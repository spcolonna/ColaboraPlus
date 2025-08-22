import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  // Posición por defecto si no se pasa ninguna
  final LatLng _defaultLocation = const LatLng(-34.90, -56.16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona la Ubicación'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _defaultLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName: 'com.example.matchhouse_flutter'),
            ],
          ),
          // Pin central fijo
          const Center(
            child: Icon(Icons.location_on, size: 50, color: Colors.red),
          ),
          // Botón flotante para confirmar
          Positioned(
            bottom: 30,
            left: 60,
            right: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                // Devolvemos la ubicación del centro del mapa
                Navigator.of(context).pop(_mapController.camera.center);
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirmar Ubicación'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)
              ),
            ),
          )
        ],
      ),
    );
  }
}
