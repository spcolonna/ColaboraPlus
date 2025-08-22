import 'dart:async';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'interfaces/IHouseService.dart';

class LocationService {
  StreamSubscription<LocationData>? _positionStreamSubscription;
  bool _isTracking = false;

  Future<void> startTracking(IHouseService houseService) async {
    if (_isTracking) {
      print('[LocationService] El seguimiento ya está activo.');
      return;
    }

    Location location = Location();

    final permissionGranted = await _handlePermission(location);
    if (!permissionGranted) {
      print('[LocationService] No se pudo iniciar el seguimiento por falta de permisos.');
      return;
    }

    print('[LocationService] Permisos OK. Iniciando el stream de ubicación...');
    _isTracking = true;

    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Nos avisará cada vez que el usuario se mueva 100 metros
    );

    _positionStreamSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        print('[LocationService] Nueva ubicación detectada: ${currentLocation.latitude}, ${currentLocation.longitude}');

        houseService.sendLocationPing(
          LatLng(currentLocation.latitude!, currentLocation.longitude!),
        );
      }
    });
  }

  void stopTracking() {
    print('[LocationService] Deteniendo el seguimiento de ubicación.');
    _positionStreamSubscription?.cancel();
    _isTracking = false;
  }

  Future<bool> _handlePermission(Location location) async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }

    return true;
  }
}
