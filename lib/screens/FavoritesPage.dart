import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/House.dart';
import 'package:matchhouse_flutter/screens/HouseDetailPage.dart';

import 'HouseDetailPage.dart'; // <-- 1. AÑADE LA IMPORTACIÓN A LA PÁGINA DE DETALLE

class FavoritesPage extends StatelessWidget {
  final List<House> favoriteHouses;
  final Function(String houseId) onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.favoriteHouses,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos')),
      body: favoriteHouses.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Usa el corazón ♥️ en el mapa o en la sección de Descubrir para guardar tus casas preferidas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: favoriteHouses.length,
        itemBuilder: (context, index) {
          final house = favoriteHouses[index];
          Widget leadingImage;

          if (house.imageUrls.isNotEmpty) {
            leadingImage = SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  house.imageUrls.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) {
                    return const Icon(Icons.broken_image_outlined, color: Colors.grey);
                  },
                ),
              ),
            );
          } else {
            leadingImage = Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.house_siding, size: 40, color: Colors.grey),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              // --- 2. AÑADIMOS LA ACCIÓN onTap AL LISTTILE ---
              onTap: () {
                // Navegamos a la pantalla de detalle al tocar la tarjeta
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HouseDetailPage(house: house),
                  ),
                );
              },
              // ----------------------------------------------------
              contentPadding: const EdgeInsets.all(10),
              leading: leadingImage,
              title: Text(house.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('\$${house.price}'),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: 'Quitar de favoritos',
                // Esta lógica no cambia, el corazón sigue quitando de favoritos
                onPressed: () => onFavoriteToggle(house.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
