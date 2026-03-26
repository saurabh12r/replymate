import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../auto_reply/auto_reply_bridge.dart';
import '../auth/user_repository.dart';

/// Syncs `users/{phone}.isBlocked` from Firestore into native SharedPreferences.
///
/// Native background execution must be fully independent from Flutter/Internet,
/// so we always cache the last known value locally via MethodChannel.
class IsBlockedSyncService extends GetxService {
  final AutoReplyBridge _bridge = AutoReplyBridge();
  final UserRepository _userRepository = Get.find<UserRepository>();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _userSub;
  String? _phone;

  @override
  void onInit() {
    super.onInit();

    // Initial sync + listener setup.
    try {
      final current = FirebaseAuth.instance.currentUser;
      final initialPhone = current?.phoneNumber;
      if (initialPhone != null && initialPhone.isNotEmpty) {
        _startForPhone(initialPhone);
      }
    } catch (_) {
      // Firebase may not be ready yet; authStateChanges below will pick it up later.
    }

    // Handle login/logout while app remains open.
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        final phone = user?.phoneNumber;
        if (phone == null || phone.isEmpty) {
          await _stopUserListener();
          return;
        }
        _startForPhone(phone);
      });
    } catch (_) {
      // Keep service alive; cold-start sync will be retried on next app session.
    }
  }

  void _startForPhone(String phone) {
    if (_phone == phone) return;
    _phone = phone;
    _userSub?.cancel();

    // Cold start sync (best effort).
    _syncOnce(phone);

    // Real-time updates.
    _userSub = _userRepository.watchUserByPhone(phone).listen(
      (data) async {
        final blocked = (data?['isBlocked'] as bool?) == true;
        await _setBlockedNative(blocked);
      },
      onError: (_) {},
    );
  }

  Future<void> _syncOnce(String phone) async {
    try {
      final data = await _userRepository.getUserByPhone(phone);
      final blocked = (data?['isBlocked'] as bool?) == true;
      await _setBlockedNative(blocked);
    } catch (_) {
      // Offline/no internet: keep last known native value.
    }
  }

  Future<void> _setBlockedNative(bool value) async {
    try {
      await _bridge.setBlocked(value);
    } catch (_) {
      // MethodChannel not available or native failure: do not crash.
    }
  }

  Future<void> _stopUserListener() async {
    await _userSub?.cancel();
    _userSub = null;
    _phone = null;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.onClose();
  }
}

