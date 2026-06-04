import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Auth service singleton provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Firestore service singleton provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
