
class UserModel {
  final String uid;
  final String email;
  String? name;
  String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {

    return UserModel(
      uid: documentId,
      email: data['mail'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name ?? '',
      'mail': email,
      'phoneNumber': phoneNumber ?? '',
    };
  }
}
