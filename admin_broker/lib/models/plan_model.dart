import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

/// Subscription plan model (plans collection)
class PlanModel {
  final String planId;
  final String name;
  final int durationDays;
  final double price;
  final String description;
  final bool isActive;
  final DateTime? createdAt;

  const PlanModel({
    required this.planId,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String id) {
    return PlanModel(
      planId: id,
      name: map['name'] ?? '',
      durationDays: map['durationDays'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
    );
  }

  factory PlanModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return PlanModel(
        planId: doc.id,
        name: '',
        durationDays: 30,
        price: 0,
        description: '',
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
    return PlanModel.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'name': name,
      'durationDays': durationDays,
      'price': price,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  PlanModel copyWith({
    String? planId,
    String? name,
    int? durationDays,
    double? price,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PlanModel(
      planId: planId ?? this.planId,
      name: name ?? this.name,
      durationDays: durationDays ?? this.durationDays,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-readable duration label
  String get durationLabel {
    if (durationDays == 30) return 'Monthly';
    if (durationDays == 365) return 'Yearly';
    if (durationDays == 90) return 'Quarterly';
    if (durationDays == 180) return 'Half-Yearly';
    return '$durationDays Days';
  }
}
