
class UserModel {
  final String uid;
  final String email;
  String? name;
  String? phoneNumber;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phoneNumber,
    this.fcmTokens = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {

    return UserModel(
      uid: documentId,
      email: data['mail'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name ?? '',
      'mail': email,
      'phoneNumber': phoneNumber ?? '',
      'fcmTokens': fcmTokens,
    };
  }
}
