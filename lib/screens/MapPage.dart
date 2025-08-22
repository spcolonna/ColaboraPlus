import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

import '../models/House.dart';
import '../services/interfaces/IHouseService.dart';
import '../services/KtorHouseService.dart';
import '../widgets/HouseInfoBottomSheet.dart';
import '../widgets/HouseMapMarker.dart';

class MapPage extends StatefulWidget {
  final List<House> favoriteHouses;
  final Function(String houseId) onFavoriteToggle;

  const MapPage({super.key, required this.favoriteHouses, required this.onFavoriteToggle});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final IHouseService _houseService = KtorHouseService();
  bool _isLoading = true;
  LatLng? _currentPosition;
  String? _errorMessage;
  List<House> _houses = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    Location location = Location();

    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) { throw Exception('Servicio de ubicación deshabilitado.'); }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      final locationData = await location.getLocation();
      final lat = locationData.latitude;
      final lon = locationData.longitude;

      if (lat == null || lon == null) {
        throw Exception('No se pudo obtener la ubicación.');
      }

      final userPosition = LatLng(lat, lon);

      final allHouses = await _houseService.getAllHouses();

      if (mounted) {
        setState(() {
          //_currentPosition = userPosition;
          _currentPosition = const LatLng(-34.90, -56.16);
          _houses = allHouses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _currentPosition = const LatLng(-34.90, -56.16);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error: $_errorMessage", textAlign: TextAlign.center),
        ),
      );
    }

    final List<Marker> markers = [];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 80,
          height: 80,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 50),
        ),
      );
    }

    for (final house in _houses) {
      final bool isFavorite = widget.favoriteHouses.any((favHouse) => favHouse.id == house.id);

      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: house.point,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return HouseInfoBottomSheet(
                    house: house,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () {
                      widget.onFavoriteToggle(house.id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            // --- AQUÍ USAMOS NUESTRO NUEVO WIDGET PERSONALIZADO ---
            child: HouseMapMarker(
              house: house,
              isFavorite: isFavorite,
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition!,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.matchhouse_flutter',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
