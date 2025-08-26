import 'package:flutter/material.dart';

import '../../models/raffle_participation.dart';
import '../../services/raffle_service.dart';
import '../../theme/AppColors.dart';
import '../raffle_detail_screen.dart';
import 'package:intl/intl.dart';

class MyParticipationsTab extends StatefulWidget {
  const MyParticipationsTab({super.key});

  @override
  State<MyParticipationsTab> createState() => _MyParticipationsTabState();
}

class _MyParticipationsTabState extends State<MyParticipationsTab> {
  final RaffleService _raffleService = RaffleService();
  late Future<List<RaffleParticipation>> _participationsFuture;

  @override
  void initState() {
    super.initState();
    // Lanzamos la carga de datos cuando el widget se construye por primera vez
    _participationsFuture = _raffleService.getMyParticipations();
  }

  void _refreshParticipations() {
    setState(() {
      _participationsFuture = _raffleService.getMyParticipations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Participaciones'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshParticipations,
          ),
        ],
      ),
      body: FutureBuilder<List<RaffleParticipation>>(
        future: _participationsFuture,
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado de error
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar tus participaciones: ${snapshot.error}'));
          }
          // Estado sin datos o lista vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aún no has participado en ninguna rifa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          // Si todo está bien, mostramos la lista
          final participations = snapshot.data!;
          return ListView.builder(
            itemCount: participations.length,
            itemBuilder: (context, index) {
              final participation = participations[index];
              final raffle = participation.raffle;
              final userNumbers = participation.userNumbers;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RaffleDetailScreen(raffle: raffle)),
                  ),
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
                        Text(
                            'Sorteo: ${DateFormat('dd/MM/yyyy HH:mm').format(raffle.drawDate)} hs',
                            style: const TextStyle(color: Colors.grey)
                        ),
                        const Divider(height: 24),
                        const Text('Tus números:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: userNumbers
                              .map((num) => Chip(label: Text(num.toString())))
                              .toList(),
                        )
                      ],
                    ),
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
