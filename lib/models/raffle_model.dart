import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/models/prize_model.dart';

class RaffleModel {
  final String id;
  final String title;
  final String creatorId;
  final DateTime drawDate;
  final double ticketPrice;
  final List<PrizeModel> prizes;

  RaffleModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.drawDate,
    required this.ticketPrice,
    required this.prizes,
  });

  factory RaffleModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // --- LÓGICA CORREGIDA Y MÁS SEGURA ---
    List<PrizeModel> prizesList = [];
    // 1. Verificamos que 'prizes' no sea nulo y que sea una lista
    if (data['prizes'] != null && data['prizes'] is List) {
      // 2. Usamos 'List.from' para crear una copia segura
      final rawPrizes = List.from(data['prizes']);

      // 3. Iteramos y solo convertimos los elementos que son mapas válidos
      prizesList = rawPrizes
          .where((prizeData) => prizeData is Map<String, dynamic>) // Filtramos nulos o tipos incorrectos
          .map((prizeData) => PrizeModel.fromMap(prizeData))
          .toList();
    }
    // --- FIN DE LA CORRECCIÓN ---

    return RaffleModel(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      creatorId: data['creatorId'] ?? '',
      drawDate: (data['drawDate'] as Timestamp).toDate(),
      ticketPrice: (data['ticketPrice'] as num?)?.toDouble() ?? 0.0,
      prizes: prizesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'creatorId': creatorId,
      'drawDate': Timestamp.fromDate(drawDate),
      'ticketPrice': ticketPrice,
      'prizes': prizes.map((prize) => prize.toMap()).toList(),
    };
  }
}
