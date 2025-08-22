import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/House.dart';
import 'package:matchhouse_flutter/screens/tabs/myHousesSubScreens/AddEditHousePage.dart';
import 'package:matchhouse_flutter/services/interfaces/IProfileService.dart';
import 'package:matchhouse_flutter/services/KtorUserService.dart';

class MyHousesTab extends StatefulWidget {
  const MyHousesTab({super.key});

  @override
  State<MyHousesTab> createState() => _MyHousesTabState();
}

class _MyHousesTabState extends State<MyHousesTab> {
  // Asumo que usarás el IProfileService para getMyHouses
  final IProfileService _userService = KtorUserService();
  late Future<List<House>> _myHousesFuture;

  @override
  void initState() {
    super.initState();
    // Asumo que el servicio que tiene getMyHouses es IProfileService, ajústalo si lo moviste a IHouseService
    _myHousesFuture = _userService.getMyHouses();
  }

  void _refreshHouses() {
    setState(() {
      _myHousesFuture = _userService.getMyHouses();
    });
  }

  void _navigateAndRefresh(Widget page) async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (result == true) {
      _refreshHouses();
    }
  }

  void _deleteHouse(String houseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta propiedad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteHouse(houseId);
        _refreshHouses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al eliminar: ${e.toString()}")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<House>>(
        future: _myHousesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aún no has añadido ninguna casa.'));
          }

          final myHouses = snapshot.data!;
          return ListView.builder(
            itemCount: myHouses.length,
            itemBuilder: (context, index) {
              final house = myHouses[index];

              // --- NUEVO: WIDGET DINÁMICO PARA LA IMAGEN ---
              Widget leadingImage;
              // Comprobamos si la lista de URLs de la casa tiene al menos una imagen.
              if (house.imageUrls.isNotEmpty) {
                // Si hay imágenes, mostramos la primera.
                leadingImage = SizedBox(
                  width: 56, // Un buen tamaño para el leading de un ListTile
                  height: 56,
                  child: ClipRRect( // Para redondear las esquinas de la imagen
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      house.imageUrls.first, // Usamos la primera imagen de la lista
                      fit: BoxFit.cover, // Para que la imagen cubra el espacio
                      // Muestra un spinner mientras la imagen carga
                      loadingBuilder: (context, child, progress) {
                        return progress == null ? child : const Center(child: CircularProgressIndicator());
                      },
                      // Muestra un ícono de error si la imagen falla al cargar
                      errorBuilder: (context, error, stack) {
                        return const Icon(Icons.broken_image, color: Colors.grey);
                      },
                    ),
                  ),
                );
              } else {
                // Si no hay imágenes, mostramos el ícono de casa por defecto.
                leadingImage = const Icon(Icons.house_siding, size: 40, color: Colors.deepPurple);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // --- Usamos nuestro widget de imagen dinámico aquí ---
                  leading: leadingImage,
                  title: Text(house.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${house.price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateAndRefresh(AddEditHousePage(house: house))),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHouse(house.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(const AddEditHousePage()),
        label: const Text('Agregar Casa'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
