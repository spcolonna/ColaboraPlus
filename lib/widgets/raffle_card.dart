import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:colabora_plus/screens/raffle_detail_screen.dart';

import '../models/raffle_model.dart';

class RaffleCard extends StatelessWidget {
  final RaffleModel raffle;

  const RaffleCard({super.key, required this.raffle});

  // --- NUEVO MÉTODO HELPER PARA MOSTRAR EL DIÁLOGO DE CLAVE ---
  void _showPasswordDialog(BuildContext context, RaffleModel raffle) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rifa Privada'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Esta rifa requiere una clave para continuar.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Clave',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la clave' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Verificar'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (passwordController.text == raffle.rafflePassword) {
                    Navigator.of(ctx).pop(); // Cierra el diálogo
                    Navigator.push( // Navega a la pantalla de detalle
                      context,
                      MaterialPageRoute(builder: (context) => RaffleDetailScreen(raffle: raffle)),
                    );
                  } else {
                    // Muestra un error si la clave es incorrecta
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clave incorrecta.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // Usamos un Stack para poder posicionar el ícono del candado encima
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              // --- LÓGICA DE VERIFICACIÓN AQUÍ ---
              if (raffle.isPrivate) {
                _showPasswordDialog(context, raffle);
              } else {
                // Si no es privada, navega directamente como antes
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaffleDetailScreen(raffle: raffle),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dejamos un poco de espacio a la derecha para el candado
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: Text(
                      raffle.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.confirmation_number, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${raffle.soldTicketsCount} Boletos Vendidos',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        backgroundColor: AppColors.accentGreen.withOpacity(0.1),
                        avatar: const Icon(Icons.attach_money, color: AppColors.accentGreen),
                        label: Text(
                          raffle.ticketPrice.toStringAsFixed(2),
                          style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        avatar: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        label: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(raffle.drawDate),
                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- ÍCONO DE CANDADO PARA RIFAS PRIVADAS ---
          if (raffle.isPrivate)
            Positioned(
              top: 16,
              right: 16,
              child: Icon(Icons.lock, color: Colors.grey[600], size: 24),
            ),
        ],
      ),
    );
  }
}
