import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'service_providers.dart';

/// Auth state provider - streams Firebase auth changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Helper to check if auth is fully loaded
final authLoadedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (_) => true,
    orElse: () => false,
  );
});

/// Current user model provider - Firestore user document
///
/// ✅ FIX: Every branch must return Stream<UserModel?> explicitly.
/// Using `const Stream.empty()` without a type parameter makes Dart infer
/// Stream<Never>, which Riverpod cannot cast to Stream<UserModel?> at
/// runtime — causing: "type 'mE' is not a subtype of type 'f2'"
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream<UserModel?>.empty(); // ✅ typed
      return ref.read(authServiceProvider).userModelStream(user.uid);
    },
    loading: () => const Stream<UserModel?>.empty(),  // ✅ typed
    error: (_, __) => const Stream<UserModel?>.empty(), // ✅ typed
  );
});

/// Auth notifier for login/logout operations
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<UserModel?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Theme mode provider (dark/light)
final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark