import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/House.dart';

class DiscoveryCard extends StatelessWidget {
  final House house;

  const DiscoveryCard({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge, // Evita que los hijos se salgan de los bordes redondeados
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Espacio para la imagen (placeholder)
          Expanded(
            child: Container(
              alignment: Alignment.center,
              color: Colors.deepPurple[100],
              child: const Icon(Icons.photo_size_select_actual_outlined, size: 100, color: Colors.white),
            ),
          ),
          // Información de la casa
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${house.price.toString()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
