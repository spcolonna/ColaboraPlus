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

                  // Creamos una lista de widgets para los datos personalizados
                  final customDataWidgets = winner.customData.entries.map((entry) {
                    return Text('  • ${entry.key}: ${entry.value}');
                  }).toList();

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${winner.prizePosition}º', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(winner.prizeDescription, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Ganador: ${winner.winnerName}'),
                        Text('Boleto Nº: ${winner.winningNumber}'),
                        const SizedBox(height: 8),

                        // --- INFORMACIÓN DE CONTACTO ---
                        const Text('Datos de Contacto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

                        // --- DATOS PERSONALIZADOS (SI EXISTEN) ---
                        if (customDataWidgets.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Información Adicional:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ...customDataWidgets,
                        ],

                        // --- NOTAS DEL ADMIN (SI EXISTEN) ---
                        if (winner.adminNotes != null && winner.adminNotes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Nota de Reserva (Admin):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('  • ${winner.adminNotes}'),
                        ],
                      ],
                    ),
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
