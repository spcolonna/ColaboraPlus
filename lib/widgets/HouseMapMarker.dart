import 'package:flutter/material.dart';
import '../models/House.dart';

class HouseMapMarker extends StatelessWidget {
  final House house;
  final bool isFavorite;

  const HouseMapMarker({
    super.key,
    required this.house,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isFavorite ? Colors.red : Colors.white;

    // Widget para el contenido de la imagen (o el placeholder)
    Widget imageContent;
    if (house.imageUrls.isNotEmpty) {
      imageContent = Image.network(
        house.imageUrls.first,
        fit: BoxFit.cover,
        // Mostramos un pequeño spinner mientras carga
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        // Mostramos un ícono de error si falla
        errorBuilder: (context, error, stack) => const Icon(Icons.house_siding, color: Colors.grey),
      );
    } else {
      // Placeholder si no hay imágenes
      imageContent = const Icon(Icons.house_siding, size: 30, color: Colors.deepPurple);
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Forma circular
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        // Añadimos un borde rojo si es favorito
        border: Border.all(color: borderColor, width: 3),
      ),
      child: ClipOval( // Recortamos el contenido para que sea circular
        child: imageContent,
      ),
    );
  }
}
