import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/payment_method.dart';


class TicketModel {
  final String id;
  final String raffleId;
  final String userId;
  final String userName;
  final List<int> ticketNumbers;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final double amount;
  final Map<String, String> customData;
  final String? adminNotes;
  final String? paymentPreferenceId;

  TicketModel({
    required this.id,
    required this.raffleId,
    required this.userId,
    required this.userName,
    required this.ticketNumbers,
    required this.paymentMethod,
    required this.isPaid,
    required this.amount,
    this.customData = const {},
    this.adminNotes,
    this.paymentPreferenceId,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      raffleId: data['raffleId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario Anónimo',
      ticketNumbers: List<int>.from(data['ticketNumbers'] ?? []),
      paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.manual,
      ),
      isPaid: data['isPaid'] ?? false,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      customData: Map<String, String>.from(data['customData'] ?? {}),
      adminNotes: data['adminNotes'],
      paymentPreferenceId: data['paymentPreferenceId'],
    );
  }
}
