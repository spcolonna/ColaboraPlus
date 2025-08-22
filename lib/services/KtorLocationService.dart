import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'interfaces/ILocationService.dart';

class KtorLocationService implements ILocationService {
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  @override
  Future<List<String>> getAvailableCountries() async {
    final url = Uri.parse('$_baseUrl/locations/countries');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return List<String>.from(jsonList);
      } else {
        throw Exception('Error al cargar los países');
      }
    } catch (e) {
      throw Exception('No se pudo conectar al servidor.');
    }
  }

  @override
  Future<List<String>> getDepartments(String countryName) async {
    final url = Uri.parse('$_baseUrl/locations/countries/$countryName/departments');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return List<String>.from(jsonList);
      } else {
        throw Exception('Error al cargar los departamentos');
      }
    } catch (e) {
      throw Exception('No se pudo conectar al servidor.');
    }
  }

  @override
  Future<List<String>> getNeighborhoods(String countryName, String departmentName) async {
    final url = Uri.parse('$_baseUrl/locations/countries/$countryName/departments/$departmentName/neighborhoods');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return List<String>.from(jsonList);
      } else {
        throw Exception('Error al cargar los barrios');
      }
    } catch (e) {
      throw Exception('No se pudo conectar al servidor.');
    }
  }
}
