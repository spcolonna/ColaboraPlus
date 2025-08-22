import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:matchhouse_flutter/services/interfaces/IHouseService.dart';
import '../models/House.dart';
import 'package:latlong2/latlong.dart';

class KtorHouseService implements IHouseService {
  String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  @override
  Future<List<House>> getAllHouses() async {
    final url = Uri.parse('$_baseUrl/house');

    print("Obteniendo TODAS las casas desde: $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> housesJson = json.decode(response.body);
        return housesJson.map((json) => House.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor al cargar las casas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red al obtener las casas: ${e.toString()}');
    }
  }

  @override
  Future<List<House>> getNearbyHouses(LatLng location) async {
    final queryParameters = {
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
    };
    final uri = Uri.parse('$_baseUrl/house/nearby').replace(queryParameters: queryParameters);

    print("Obteniendo casas cercanas desde: $uri");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> housesJson = json.decode(response.body);
        return housesJson.map((json) => House.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar casas cercanas: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de red al buscar casas cercanas: ${e.toString()}');
    }
  }

  @override
  Future<List<House>> getDiscoveryHouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final url = Uri.parse('$_baseUrl/discovery/queue?userId=${user.uid}');

    print('[KTOR DISCOVERY] Pidiendo cola de descubrimiento: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> housesJson = json.decode(response.body);
        final houses = housesJson.map((json) => House.fromJson(json)).toList();
        print('[KTOR DISCOVERY] Se recibieron ${houses.length} casas.');
        return houses;
      } else {
        print('Error al cargar la cola de descubrimiento: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de conexión al obtener la cola de descubrimiento: $e');
      return [];
    }
  }

  @override
  Future<void> sendLocationPing(LatLng location) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Ping de ubicación omitido: Usuario no autenticado.');
      return;
    }
    final url = Uri.parse('$_baseUrl/discovery/ping?userId=${user.uid}');

    final body = json.encode({
      'lat': location.latitude,
      'lon': location.longitude,
    });

    try {
      print('[KTOR PING] Enviando ubicación: Lat ${location.latitude}, Lon ${location.longitude}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('[KTOR PING] Ubicación procesada por el servidor.');
      } else {
        print('[KTOR PING] Error del servidor: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[KTOR PING] Error de conexión: ${e.toString()}');
    }
  }
}
