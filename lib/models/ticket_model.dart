import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/payment_method.dart';


class TicketModel {
  final String id;
  final String raffleId;
  final String userId;
  final String userName; // Guardamos el nombre para no tener que buscarlo después
  final List<int> ticketNumbers; // Los números que compró en esta transacción
  final PaymentMethod paymentMethod;
  final bool isPaid; // False por defecto para pagos manuales
  final double amount; // Cuánto costó esta compra

  TicketModel({
    required this.id,
    required this.raffleId,
    required this.userId,
    required this.userName,
    required this.ticketNumbers,
    required this.paymentMethod,
    required this.isPaid,
    required this.amount,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      raffleId: data['raffleId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario Anónimo',
      // Firestore guarda las listas como List<dynamic>, hay que convertirla
      ticketNumbers: List<int>.from(data['ticketNumbers'] ?? []),
      paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.manual,
      ),
      isPaid: data['isPaid'] ?? false,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
