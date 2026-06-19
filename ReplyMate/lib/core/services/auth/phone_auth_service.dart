import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PhoneAuthService
///
/// OTP delivery & verification is handled by **Message Central** (VerifyNow) via
/// Cloud Functions. The functions mint a Firebase **custom token** (uid == E.164
/// phone) which we sign in with, so the rest of the app keeps a normal Firebase
/// session (`currentUser`, Firestore rules, sync services) exactly as before.
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth, FirebaseFunctions? functions})
    : _auth = auth ?? FirebaseAuth.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  /// Requests an OTP for [phoneNumber] (full E.164, e.g. '+919022902102').
  /// [countryCode] is the dialing code (e.g. '+91') used to derive the local
  /// mobile number on the server.
  Future<void> sendOtp({
    required String phoneNumber,
    required String countryCode,
    required Function(String verificationId) onCodeSent,
    required Function(String message) onFailed,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendOtp').call({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      });
      final verificationId =
          (result.data?['verificationId'] as String?)?.trim() ?? '';
      if (verificationId.isEmpty) {
        onFailed('Failed to send OTP. Please try again.');
        return;
      }
      onCodeSent(verificationId);
    } on FirebaseFunctionsException catch (e) {
      onFailed(e.message ?? 'Failed to send OTP');
    } catch (_) {
      onFailed('Failed to send OTP. Please try again.');
    }
  }

  /// Verifies [code] for the given [verificationId] and signs the user in with the
  /// Firebase custom token returned by the server. Returns the [UserCredential].
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String code,
    required String phoneNumber,
  }) async {
    if (verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'OTP session expired. Please request a new code.',
      );
    }

    final HttpsCallableResult result;
    try {
      result = await _functions.httpsCallable('verifyOtp').call({
        'verificationId': verificationId,
        'code': code,
        'phoneNumber': phoneNumber,
      });
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Invalid OTP. Please try again.',
      );
    }

    final token = (result.data?['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-token',
        message: 'Verification failed. Please try again.',
      );
    }
    return _auth.signInWithCustomToken(token);
  }
}
