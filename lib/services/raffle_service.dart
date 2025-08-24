import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../enums/payment_method.dart';
import '../enums/payment_method.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';
import '../models/ticket_model.dart';

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

  Stream<QuerySnapshot> getAllActiveRafflesStream() {
    // Más adelante podríamos añadir un .where('status', isEqualTo: 'active')
    // para filtrar solo las que no han sido sorteadas.
    return _firestore
        .collection('raffles')
        .orderBy('drawDate', descending: false) // Muestra primero las más próximas a sortearse
        .snapshots();
  }

  Future<bool> isNumberTaken({required String raffleId, required int number}) async {
    final query = await _firestore
        .collection('raffles')
        .doc(raffleId)
        .collection('tickets')
        .where('ticketNumbers', arrayContains: number) // 'array-contains' es muy eficiente para esto
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Registra la compra de un nuevo boleto.
  Future<void> purchaseTicket({
    required RaffleModel raffle,
    required List<int> numbers,
    required PaymentMethod paymentMethod,
  }) async {
    final user = _auth.currentUser;
    // Asumimos que HomeScreen ya cargó el perfil, pero en una app más grande,
    // podríamos pasar el UserModel o buscarlo aquí.
    final userName = user?.displayName ?? user?.email ?? 'Usuario Anónimo';

    if (user == null) {
      throw Exception('Debes iniciar sesión para comprar un boleto.');
    }

    final newTicket = TicketModel(
      id: '', // Firestore lo genera
      raffleId: raffle.id,
      userId: user.uid,
      userName: userName,
      ticketNumbers: numbers,
      paymentMethod: paymentMethod,
      // Si el pago es manual, no está pagado hasta que el admin lo confirme.
      isPaid: paymentMethod == PaymentMethod.online,
      amount: raffle.ticketPrice * numbers.length,
    );

    // Creamos el documento en la subcolección de la rifa
    await _firestore
        .collection('raffles')
        .doc(raffle.id)
        .collection('tickets')
        .add({ // No usamos un .toMap() aquí para poder añadir la fecha del servidor
      'raffleId': newTicket.raffleId,
      'userId': newTicket.userId,
      'userName': newTicket.userName,
      'ticketNumbers': newTicket.ticketNumbers,
      'paymentMethod': newTicket.paymentMethod.name,
      'isPaid': newTicket.isPaid,
      'amount': newTicket.amount,
      'purchaseDate': FieldValue.serverTimestamp(), // Usa la hora del servidor
    });
  }
}
