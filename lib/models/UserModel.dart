import '../enums/UserRole.dart';

class UserModel {
  final String uid;
  final String email;
  String? name;
  String? phoneNumber;
  UserRole role;
  String? agencyName;
  String? licenseNumber; // Mantengo este campo de tu modelo original

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.phoneNumber,
    this.agencyName,
    this.licenseNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    final roleString = (data['role'] as String?)?.toLowerCase() ?? 'person';

    return UserModel(
      uid: documentId,
      email: data['mail'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      role: (roleString == 'agency') ? UserRole.agency : UserRole.person,
      agencyName: data['agencyName'],
      licenseNumber: data['licenseNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name ?? '',
      'mail': email,
      'phoneNumber': phoneNumber ?? '',
      'role': role.name.toUpperCase(), // Enviamos 'AGENCY' o 'PERSON'
      'agencyName': agencyName ?? '',
    };
  }
}
