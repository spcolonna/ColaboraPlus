import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../enums/payment_method.dart';
import '../enums/payment_method.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';
import '../models/raffle_participation.dart';
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

  Future<void> purchaseTicket({
    required RaffleModel raffle,
    required List<int> numbers,
    required PaymentMethod paymentMethod,
  }) async {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? user?.email ?? 'Usuario Anónimo';

    if (user == null) {
      throw Exception('Debes iniciar sesión para comprar un boleto.');
    }

    final newTicketData = {
      'raffleId': raffle.id,
      'userId': user.uid,
      'userName': userName,
      'ticketNumbers': numbers,
      'paymentMethod': paymentMethod.name, // 'online' o 'manual'
      'isPaid': paymentMethod == PaymentMethod.online,
      'amount': raffle.ticketPrice * numbers.length,
      'purchaseDate': FieldValue.serverTimestamp(),
    };

    // --- ESTA ES LA LÍNEA CLAVE ---
    // En lugar de actualizar un array en el documento principal,
    // añadimos un NUEVO DOCUMENTO a la SUBCOLECCIÓN 'tickets'.
    await _firestore
        .collection('raffles')
        .doc(raffle.id)
        .collection('tickets')
        .add(newTicketData);
  }

  Future<List<RaffleParticipation>> getMyParticipations() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Si no hay usuario, devuelve una lista vacía.
      return [];
    }

    // 1. Hacemos una consulta de grupo para encontrar TODOS los boletos del usuario
    final ticketsSnapshot = await _firestore
        .collectionGroup('tickets') // <-- Magia de Collection Group Query
        .where('userId', isEqualTo: user.uid)
        .get();

    if (ticketsSnapshot.docs.isEmpty) {
      return []; // El usuario no ha comprado ningún boleto.
    }

    // 2. Agrupamos los boletos por 'raffleId' y coleccionamos los números
    final Map<String, List<int>> numbersByRaffleId = {};
    for (var ticketDoc in ticketsSnapshot.docs) {
      final ticketData = ticketDoc.data();
      final raffleId = ticketData['raffleId'] as String;
      final numbers = List<int>.from(ticketData['ticketNumbers'] ?? []);

      if (numbersByRaffleId.containsKey(raffleId)) {
        numbersByRaffleId[raffleId]!.addAll(numbers);
      } else {
        numbersByRaffleId[raffleId] = numbers;
      }
    }

    // 3. Obtenemos los IDs únicos de las rifas en las que participa
    final raffleIds = numbersByRaffleId.keys.toList();

    // 4. Hacemos UNA SOLA consulta para traer los detalles de todas esas rifas
    final rafflesSnapshot = await _firestore
        .collection('raffles')
        .where(FieldPath.documentId, whereIn: raffleIds)
        .get();

    // 5. Unimos los detalles de la rifa con los números del usuario
    final List<RaffleParticipation> participations = [];
    for (var raffleDoc in rafflesSnapshot.docs) {
      final raffle = RaffleModel.fromFirestore(raffleDoc);
      final userNumbers = numbersByRaffleId[raffle.id] ?? [];
      userNumbers.sort(); // Ordenamos los números

      participations.add(
        RaffleParticipation(raffle: raffle, userNumbers: userNumbers),
      );
    }

    return participations;
  }
}
