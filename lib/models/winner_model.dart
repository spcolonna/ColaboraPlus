class WinnerModel {
  final int prizePosition;
  final String prizeDescription;
  final int winningNumber;
  final String winnerUserId;
  final String winnerName;
  final String winnerEmail;
  final String winnerPhoneNumber;
  final String? adminNotes;
  final Map<String, String> customData;

  WinnerModel({
    required this.prizePosition,
    required this.prizeDescription,
    required this.winningNumber,
    required this.winnerUserId,
    required this.winnerName,
    required this.winnerEmail,
    required this.winnerPhoneNumber,
    this.adminNotes,
    this.customData = const {},
  });

  factory WinnerModel.fromMap(Map<String, dynamic> map) {
    return WinnerModel(
        prizePosition: map['prizePosition'] ?? 0,
        prizeDescription: map['prizeDescription'] ?? '',
        winningNumber: map['winningNumber'] ?? 0,
        winnerUserId: map['winnerUserId'] ?? '',
        winnerName: map['winnerName'] ?? '',
        winnerEmail: map['winnerEmail'] ?? 'No disponible',
        winnerPhoneNumber: map['winnerPhoneNumber'] ?? 'No disponible',
        adminNotes: map['adminNotes'],
        customData: Map<String, String>.from(map['customData'] ?? {})
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prizePosition': prizePosition,
      'prizeDescription': prizeDescription,
      'winningNumber': winningNumber,
      'winnerUserId': winnerUserId,
      'winnerName': winnerName,
      'winnerEmail': winnerEmail,
      'winnerPhoneNumber': winnerPhoneNumber,
      'adminNotes': adminNotes,
      'customData': customData,
    };
  }
}
