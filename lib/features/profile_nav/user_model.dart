class UserModel {
  UserModel({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawName = (map['name'] as String?)?.trim();
    final rawPhone = (map['phone'] as String?)?.trim();
    final rawEmail = (map['email'] as String?)?.trim();
    return UserModel(
      name: (rawName == null || rawName.isEmpty) ? 'Unknown User' : rawName,
      phone: (rawPhone == null || rawPhone.isEmpty) ? 'Not available' : rawPhone,
      email: (rawEmail == null || rawEmail.isEmpty) ? 'Not available' : rawEmail,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
      };
}
