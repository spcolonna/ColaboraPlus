import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';

class RaffleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createRaffle({
    required String title,
    required double ticketPrice,
    required DateTime drawDate,
    required List<PrizeModel> prizes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. No se puede crear la rifa.');
    }

    final newRaffle = RaffleModel(
      id: '',
      title: title,
      creatorId: user.uid,
      drawDate: drawDate,
      ticketPrice: ticketPrice,
      prizes: prizes,
    );

    await _firestore.collection('raffles').add(newRaffle.toMap());
  }

  Stream<QuerySnapshot> getMyRafflesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // Si no hay usuario, devuelve un stream vacío para evitar errores.
      return Stream.empty();
    }

    return _firestore
        .collection('raffles')
        .where('creatorId', isEqualTo: user.uid)
        .snapshots(); // La clave es .snapshots() para tiempo real
  }

  Stream<QuerySnapshot> getTicketsStream(String raffleId) {
    return _firestore
        .collection('raffles')
        .doc(raffleId)
        .collection('tickets') // <-- Accedemos a la subcolección
        .snapshots();
  }

  /// Marca un boleto de pago manual como pagado.
  Future<void> confirmManualPayment(String raffleId, String ticketId) async {
    await _firestore
        .collection('raffles')
        .doc(raffleId)
        .collection('tickets')
        .doc(ticketId)
        .update({'isPaid': true});
  }

  Future<void> updateRaffle({
    required String raffleId,
    required String newTitle,
    required double newTicketPrice,
    required DateTime newDrawDate,
    required List<PrizeModel> newPrizes,
  }) async {
    // Convertimos la lista de premios a una lista de mapas
    final prizesAsMaps = newPrizes.map((prize) => prize.toMap()).toList();

    await _firestore.collection('raffles').doc(raffleId).update({
      'title': newTitle,
      'ticketPrice': newTicketPrice,
      'drawDate': Timestamp.fromDate(newDrawDate),
      'prizes': prizesAsMaps,
    });
  }
}
