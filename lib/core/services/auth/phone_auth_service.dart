import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  int? _resendToken;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(UserCredential credential) onVerificationCompleted,
    required Function(String message) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        onVerificationCompleted(userCredential);
      },
      verificationFailed: (e) {
        onFailed(e.message ?? 'Failed to send OTP');
      },
      codeSent: (verificationId, resendToken) {
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    if (verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'OTP session expired. Please request a new code.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }
}
