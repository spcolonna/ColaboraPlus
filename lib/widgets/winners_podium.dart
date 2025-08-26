import 'package:flutter/material.dart';

import '../models/winner_model.dart';

class WinnersPodium extends StatelessWidget {
  final List<WinnerModel> winners;

  const WinnersPodium({super.key, required this.winners});

  @override
  Widget build(BuildContext context) {
    // Ordenamos los ganadores por la posición del premio
    final sortedWinners = List<WinnerModel>.from(winners)
      ..sort((a, b) => a.prizePosition.compareTo(b.prizePosition));

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('¡Sorteo Finalizado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Text('🏆', style: TextStyle(fontSize: 24)),
              ],
            ),
            const Divider(height: 24),
            if (sortedWinners.isEmpty)
              const Text('No se encontraron ganadores para esta rifa.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedWinners.length,
                itemBuilder: (context, index) {
                  final winner = sortedWinners[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${winner.prizePosition}º',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      winner.prizeDescription,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Subtítulo mejorado con toda la información
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Ganador: ${winner.winnerName}'),
                        Text('Boleto Nº: ${winner.winningNumber}'),
                        const SizedBox(height: 4),
                        // Mostramos email y teléfono
                        Row(children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(winner.winnerEmail),
                        ]),
                        Row(children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(winner.winnerPhoneNumber),
                        ]),
                      ],
                    ),
                    isThreeLine: true, // Permite más espacio para el subtítulo
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
          ],
        ),
      ),
    );
  }
}
