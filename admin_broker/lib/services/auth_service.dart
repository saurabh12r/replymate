import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

/// Handles Firebase Auth operations and user role management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current Firebase user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) return null;
      return await getUserModel(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Get user model from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromDoc(doc);
  }

  /// Stream user model for real-time updates
  Stream<UserModel?> userModelStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Create a broker account (admin only)
  Future<UserModel> createBrokerAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    // Safely create auth account via Cloud Function (Admin SDK)
    // to prevent logging out the current admin session.
    final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
    final callable = functions.httpsCallable('createBroker');
    
    final result = await callable.call({
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'phone': phone.trim(),
    });

    final uid = result.data['uid'] as String;

    // Create Firestore user document
    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: AppConstants.roleBroker,
      isActive: true,
    );
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toMap());

    return userModel;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Convert Firebase errors to readable messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
