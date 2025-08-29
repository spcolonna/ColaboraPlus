import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../enums/payment_method.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';
import '../models/raffle_participation.dart';

class RaffleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createRaffle({
    required String title,
    required double ticketPrice,
    required DateTime drawDate,
    required List<PrizeModel> prizes,
    required bool isLimited,
    int? totalTickets,
    required List<String> customFields,
    required String country,
    required String countryCode,
    required bool isPrivate,
    String? rafflePassword,
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
      isLimited: isLimited,
      totalTickets: totalTickets,
      customFields: customFields,
      country: country,
      countryCode: countryCode,
      isPrivate: isPrivate,
      rafflePassword: rafflePassword,
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
        // .orderBy('drawDate', descending: false)
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
    required bool isLimited,
    int? totalTickets,
    required List<String> customFields,
  }) async {
    final prizesAsMaps = newPrizes.map((prize) => prize.toMap()).toList();

    await _firestore.collection('raffles').doc(raffleId).update({
      'title': newTitle,
      'ticketPrice': newTicketPrice,
      'drawDate': Timestamp.fromDate(newDrawDate),
      'prizes': prizesAsMaps,
      'isLimited': isLimited,
      'totalTickets': totalTickets,
      'customFields': customFields,
    });
  }

  Stream<QuerySnapshot> getAllActiveRafflesStream() {
    return _firestore
        .collection('raffles')
        .where('status', isEqualTo: 'active')
        .orderBy('drawDate', descending: false)
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
    required Map<String, String> customData,
    String? adminNotes,
    String? paymentPreferenceId
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
      'customData': customData,
      'adminNotes': adminNotes,
      'paymentPreferenceId': paymentPreferenceId,
    };

    await _firestore
        .collection('raffles')
        .doc(raffle.id)
        .collection('tickets')
        .add(newTicketData);
  }

  Future<List<RaffleParticipation>> getMyParticipations() async {
    final user = _auth.currentUser;
    if (user == null) {
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

  Future<List<RaffleParticipation>> getMyFinishedParticipations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // 1. Buscamos todos los boletos del usuario (igual que antes)
    final ticketsSnapshot = await _firestore
        .collectionGroup('tickets')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (ticketsSnapshot.docs.isEmpty) return [];

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

    final raffleIds = numbersByRaffleId.keys.toList();

    // 2. LA CLAVE: Hacemos la consulta a las rifas, pero filtrando
    //    solo aquellas cuyo status sea "finished".
    final rafflesSnapshot = await _firestore
        .collection('raffles')
        .where(FieldPath.documentId, whereIn: raffleIds)
        .where('status', isEqualTo: 'finished') // <-- EL NUEVO FILTRO
        .get();

    // 3. Unimos los datos (igual que antes)
    final List<RaffleParticipation> participations = [];
    for (var raffleDoc in rafflesSnapshot.docs) {
      final raffle = RaffleModel.fromFirestore(raffleDoc);
      final userNumbers = numbersByRaffleId[raffle.id] ?? [];
      userNumbers.sort();

      participations.add(
        RaffleParticipation(raffle: raffle, userNumbers: userNumbers),
      );
    }

    return participations;
  }

  Future<Set<int>> getSoldTicketNumbers(String raffleId) async {
    final ticketsSnapshot = await _firestore
        .collection('raffles')
        .doc(raffleId)
        .collection('tickets')
        .get();

    if (ticketsSnapshot.docs.isEmpty) {
      return {};
    }

    final soldNumbers = <int>{};
    for (var ticketDoc in ticketsSnapshot.docs) {
      final numbers = List<int>.from(ticketDoc.data()['ticketNumbers'] ?? []);
      soldNumbers.addAll(numbers);
    }

    return soldNumbers;
  }

  Future<void> deleteTicket(String raffleId, String ticketId) async {
    await _firestore
        .collection('raffles')
        .doc(raffleId)
        .collection('tickets')
        .doc(ticketId)
        .delete();
  }
}
