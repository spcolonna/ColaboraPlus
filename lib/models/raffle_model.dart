import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/models/prize_model.dart';

class RaffleModel {
  final String id;
  final String title;
  final String creatorId;
  final DateTime drawDate;
  final double ticketPrice;
  final List<PrizeModel> prizes;
  final int soldTicketsCount;

  RaffleModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.drawDate,
    required this.ticketPrice,
    required this.prizes,
    this.soldTicketsCount = 0,
  });

  factory RaffleModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    List<PrizeModel> prizesList = [];
    if (data['prizes'] is List) {
      prizesList = (data['prizes'] as List)
          .where((prizeData) => prizeData is Map<String, dynamic>)
          .map((prizeData) => PrizeModel.fromMap(prizeData))
          .toList();
    }

    return RaffleModel(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      creatorId: data['creatorId'] ?? '',
      drawDate: (data['drawDate'] as Timestamp).toDate(),
      ticketPrice: (data['ticketPrice'] as num?)?.toDouble() ?? 0.0,
      prizes: prizesList,
      soldTicketsCount: data['soldTicketsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'creatorId': creatorId,
      'drawDate': Timestamp.fromDate(drawDate),
      'ticketPrice': ticketPrice,
      'prizes': prizes.map((prize) => prize.toMap()).toList(),
      'soldTicketsCount': soldTicketsCount,
    };
  }
}
