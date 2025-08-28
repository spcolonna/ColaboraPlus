import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/models/prize_model.dart';
import 'package:colabora_plus/models/winner_model.dart';

import '../enums/raffle_status.dart';

class RaffleModel {
  final String id;
  final String title;
  final String creatorId;
  final DateTime drawDate;
  final double ticketPrice;
  final List<PrizeModel> prizes;
  final int soldTicketsCount;
  final RaffleStatus status;
  final List<WinnerModel> winners;
  final bool isLimited;
  final int? totalTickets;
  final List<String> customFields;
  final String country;
  final String countryCode;
  final bool isPrivate;
  final String? rafflePassword;

  bool get hasEnded => DateTime.now().isAfter(drawDate);

  RaffleModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.drawDate,
    required this.ticketPrice,
    required this.prizes,
    this.soldTicketsCount = 0,
    this.status = RaffleStatus.active,
    this.winners = const [],
    this.isLimited = false,
    this.totalTickets,
    this.customFields = const [],
    required this.country,
    required this.countryCode,
    this.isPrivate = false,
    this.rafflePassword,
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

    List<WinnerModel> winnersList = [];
    if (data['winners'] is List) {
      winnersList = (data['winners'] as List)
          .map((winnerData) => WinnerModel.fromMap(winnerData))
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
      status: RaffleStatus.values.firstWhere(
              (e) => e.name == data['status'],
          orElse: () => RaffleStatus.active
      ),
      winners: winnersList,
      isLimited: data['isLimited'] ?? false,
      totalTickets: data['totalTickets'],
      customFields: List<String>.from(data['customFields'] ?? []),
      country: data['country'] ?? 'Uruguay',
      countryCode: data['countryCode'] ?? 'UY',
      isPrivate: data['isPrivate'] ?? false,
      rafflePassword: data['rafflePassword'],
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
      'status': status.name,
      'winners': winners.map((winner) => winner.toMap()).toList(),
      'isLimited': isLimited,
      'totalTickets': totalTickets,
      'customFields': customFields,
      'country': country,
      'countryCode': countryCode,
      'isPrivate': isPrivate,
      'rafflePassword': rafflePassword,
    };
  }
}
