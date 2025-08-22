import 'package:latlong2/latlong.dart';
import '../../models/House.dart';

abstract class IHouseService {
  Future<List<House>> getAllHouses();
  Future<List<House>> getNearbyHouses(LatLng location);
  Future<List<House>> getDiscoveryHouses();

  Future<void> sendLocationPing(LatLng location);
}
