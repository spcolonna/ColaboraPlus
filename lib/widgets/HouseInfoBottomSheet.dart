import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/House.dart';

import '../screens/HouseDetailPage.dart';

class HouseInfoBottomSheet extends StatelessWidget {
  final House house;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const HouseInfoBottomSheet({
    super.key,
    required this.house,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // --- NUEVO: Lógica para obtener la primera imagen de forma segura ---
    final String? coverImageUrl = house.imageUrls.isNotEmpty ? house.imageUrls.first : null;

    return Padding(
      // Usamos MediaQuery para que el popup no sea excesivamente alto en pantallas grandes
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Imagen de la Casa Corregida ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200], // Color de fondo por si no hay imagen
                  // Mostramos la imagen solo si tenemos una URL
                  child: coverImageUrl != null
                      ? Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, error, stack) =>
                    const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 60),
                  )
                      : const Icon(Icons.house_siding, size: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Título y Precio (sin cambios)
              Text(
                house.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${house.price}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // --- Botones de Acción con Lógica Corregida ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      // La lógica ahora es simple: solo llamamos al callback
                      onPressed: onFavoriteToggle,

                      // El ícono y el texto cambian según si es favorito o no
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                      label: Text(isFavorite ? 'Quitar Favorito' : 'Favorito'),

                      // El estilo también cambia
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: isFavorite ? Colors.red : Colors.deepPurple,
                        side: BorderSide(color: isFavorite ? Colors.red : Colors.deepPurple, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      // --- LÓGICA DE NAVEGACIÓN CORREGIDA ---
                      onPressed: () {
                        // Primero, cerramos el BottomSheet para que no quede abierto debajo
                        Navigator.pop(context);

                        // Luego, navegamos a la nueva pantalla de detalle,
                        // pasándole el objeto 'house' completo.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HouseDetailPage(house: house),
                          ),
                        );
                      },
                      // ------------------------------------
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver Casa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
