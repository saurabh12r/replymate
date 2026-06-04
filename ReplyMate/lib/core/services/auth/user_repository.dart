import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/profile_nav/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore {
    final o = _firestoreOverride;
    if (o != null) return o;

    // Avoid touching Firebase synchronously before initialization.
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not initialized yet');
    }
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> registerUser({
    required String name,
    required String phone,
    String? email,
    String? brokerId,    // ← linked broker's UID (null = direct/admin approval)
    String? brokerCode,  // ← the code string typed by the user
  }) async {
    final docRef = _users.doc(phone);
    final existing = await docRef.get();
    if (existing.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'User already registered',
      );
    }

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token during registration: $e');
    }

    await docRef.set({
      'name': name.trim(),
      'phone': phone,
      'email': (email ?? '').trim(),
      'isApproved': false,
      'isBlocked': false,
      'brokerId': brokerId,
      'brokerCode': brokerCode,
      'status': 'pending',
      'authUid': FirebaseAuth.instance.currentUser?.uid,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final doc = await _users.doc(phone).get();
    return doc.data();
  }

  Future<String?> getUserPhoneByUid(String uid) async {
    final snap = await _users.where('authUid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.first.id; 
    }
    // Fallback: check if the document ID itself is the uid
    final doc = await _users.doc(uid).get();
    if (doc.exists) return uid;
    return null;
  }

  Stream<Map<String, dynamic>?> watchUserByPhone(String phone) {
    return _users.doc(phone).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  Stream<UserModel?> watchUserByUid(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return UserModel.fromMap(data);
    });
  }

  Future<void> deleteUserByUid(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (name != null && name.trim().isNotEmpty) {
      updateData['name'] = name.trim();
    }
    if (email != null) {
      updateData['email'] = email.trim();
    }
    updateData['authUid'] = FirebaseAuth.instance.currentUser?.uid;
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _users.doc(userId).update(updateData);
  }

  Future<void> ensureUserDocumentForUid({
    required String uid,
    String? phone,
    String? email,
  }) async {
    final uidDoc = _users.doc(uid);
    final existing = await uidDoc.get();
    if (existing.exists) return;

    Map<String, dynamic>? seedData;
    if (phone != null && phone.isNotEmpty) {
      final legacy = await _users.doc(phone).get();
      if (legacy.exists) {
        seedData = legacy.data();
      }
    }

    final name = ((seedData?['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (seedData!['name'] as String).trim()
        : 'User';
    final normalizedPhone = ((seedData?['phone'] as String?)?.trim().isNotEmpty ?? false)
        ? (seedData!['phone'] as String).trim()
        : (phone ?? '');
    final normalizedEmail = ((seedData?['email'] as String?)?.trim().isNotEmpty ?? false)
        ? (seedData!['email'] as String).trim()
        : (email ?? '');

    await uidDoc.set({
      'name': name,
      'phone': normalizedPhone,
      'email': normalizedEmail,
      'createdAt': seedData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateFcmToken(String phone) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _users.doc(phone).update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}
