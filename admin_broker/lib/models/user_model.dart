import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

/// Admin/Broker portal user model (users collection)
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin' or 'broker'
  final DateTime? createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'broker',
      createdAt: AppUtils.timestampToDate(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return UserModel(
        uid: doc.id,
        name: '',
        email: '',
        phone: '',
        role: 'broker',
      );
    }
    Map<String, dynamic> mapData;
    if (data is Map<String, dynamic>) {
      mapData = data;
    } else if (data is Map) {
      mapData = Map<String, dynamic>.from(data);
    } else {
      mapData = {};
    }
    return UserModel.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isBroker => role == 'broker';
}
