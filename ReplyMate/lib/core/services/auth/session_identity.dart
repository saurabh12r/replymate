import 'package:firebase_auth/firebase_auth.dart';

/// Resolves the session phone number for the signed-in user.
///
/// With Message Central OTP we sign in via a Firebase **custom token** whose
/// `uid` is the user's E.164 phone number. Custom-token users do NOT get
/// `currentUser.phoneNumber` populated (that field is Phone-provider only), so
/// this helper falls back to `uid` (== the phone number) and keeps every caller
/// behaving exactly as it did under Firebase Phone Auth.
String? sessionPhone([User? user]) {
  final u = user ?? FirebaseAuth.instance.currentUser;
  if (u == null) return null;
  final p = u.phoneNumber;
  return (p != null && p.isNotEmpty) ? p : u.uid;
}
