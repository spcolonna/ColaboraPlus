import 'package:flutter/material.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:intl/intl.dart';

import '../../models/raffle_participation.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final RaffleService _raffleService = RaffleService();
  late Future<List<RaffleParticipation>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _raffleService.getMyFinishedParticipations();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _raffleService.getMyFinishedParticipations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Rifas'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<RaffleParticipation>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aún no tienes rifas finalizadas en tu historial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final participations = snapshot.data!;
          // Ordenamos por fecha de sorteo, de más reciente a más antigua
          participations.sort((a, b) => b.raffle.drawDate.compareTo(a.raffle.drawDate));

          return ListView.builder(
            itemCount: participations.length,
            itemBuilder: (context, index) {
              final participation = participations[index];
              final raffle = participation.raffle;
              final userNumbers = participation.userNumbers;

              // Verificamos si alguno de nuestros números es ganador
              final winningEntry = raffle.winners.where((winner) => userNumbers.contains(winner.winningNumber));
              final bool isWinner = winningEntry.isNotEmpty;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isWinner ? Colors.green[50] : null, // Resaltamos si fuimos ganadores
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raffle.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Sorteo realizado el: ${DateFormat('dd/MM/yyyy').format(raffle.drawDate)}', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 24),
                      const Text('Tus números fueron:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: userNumbers
                            .map((num) {
                          final bool isWinningNumber = raffle.winners.any((w) => w.winningNumber == num);
                          return Chip(
                            label: Text(num.toString()),
                            backgroundColor: isWinningNumber ? AppColors.accentGreen : null,
                            labelStyle: TextStyle(color: isWinningNumber ? Colors.white : null),
                          );
                        })
                            .toList(),
                      ),
                      // Mostramos el premio si ganamos
                      if (isWinner) ...[
                        const SizedBox(height: 12),
                        Text(
                          '🎉 ¡Felicidades! Ganaste el ${winningEntry.first.prizePosition}º premio: ${winningEntry.first.prizeDescription}',
                          style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
