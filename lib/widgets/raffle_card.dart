import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:colabora_plus/theme/AppColors.dart';

import '../models/raffle_model.dart';

class RaffleCard extends StatelessWidget {
  final RaffleModel raffle;

  const RaffleCard({super.key, required this.raffle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a la pantalla de detalle de la rifa (vista pública)
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ELIMINAMOS EL CONTENEDOR DE LA IMAGEN

              // Título de la Rifa
              Text(
                raffle.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.confirmation_number, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${raffle.soldTicketsCount} Boletos Vendidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información de Precio y Fecha (datos reales)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor: AppColors.accentGreen.withOpacity(0.1),
                    avatar: Icon(Icons.attach_money, color: AppColors.accentGreen),
                    label: Text(
                      raffle.ticketPrice.toStringAsFixed(2),
                      style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    avatar: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                    label: Text(
                      DateFormat('dd/MM/yyyy').format(raffle.drawDate),
                      style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
