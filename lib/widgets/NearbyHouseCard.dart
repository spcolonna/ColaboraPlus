import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/House.dart';
import 'package:matchhouse_flutter/screens/HouseDetailPage.dart';

class NearbyHouseCard extends StatelessWidget {
  final House house;

  const NearbyHouseCard({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    // --- 1. LÓGICA PARA LA IMAGEN DE PORTADA ---
    Widget imageWidget;
    if (house.imageUrls.isNotEmpty) {
      // Si hay imágenes, usamos la primera
      imageWidget = Image.network(
        house.imageUrls.first,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    } else {
      // Si no, usamos un placeholder
      imageWidget = Container(
        height: 120,
        color: Colors.deepPurple[100],
        child: const Center(child: Icon(Icons.house, color: Colors.white, size: 50)),
      );
    }

    return Container(
      width: 180, // Le damos un poco más de ancho
      margin: const EdgeInsets.only(right: 16),
      // --- 2. GESTUREDETECTOR PARA LA NAVEGACIÓN ---
      // Envolvemos la tarjeta para que sea "tocable"
      child: GestureDetector(
        onTap: () {
          print('Navegando a los detalles de: ${house.title}');
          // Al tocar, navegamos a la pantalla de detalle pasándole la casa
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HouseDetailPage(house: house),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Usamos el widget de imagen que definimos arriba
              imageWidget,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${house.price}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
