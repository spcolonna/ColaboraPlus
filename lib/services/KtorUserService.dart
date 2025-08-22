import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../enums/UserRole.dart';
import '../models/House.dart';
import '../models/SearchFilterModel.dart';
import '../models/UserModel.dart';
import 'interfaces/IProfileService.dart';

class KtorUserService implements IProfileService {
  String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final url = Uri.parse('$_baseUrl/user/${user.uid}');

    // En el futuro, aquí enviarías el token de autenticación
    // final idToken = await user.getIdToken();
    // final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return UserModel.fromMap(json.decode(response.body), user.uid);
    } else if (response.statusCode > 400 && response.statusCode < 500) {
      return UserModel(uid: user.uid, email: user.email!, role: UserRole.person);
    } else {
      throw Exception('Error al cargar el perfil del servidor');
    }
  }

  @override
  Future<http.Response> createUserProfile(UserModel user) async {
    final url = Uri.parse('$_baseUrl/user');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = json.encode(user.toMap());

    final response = await http.post(
      url,
      headers: headers,
      // En el futuro, aquí añadirías el token de autenticación:
      // 'Authorization': 'Bearer TU_ID_TOKEN_DE_FIREBASE'
      body: body
    ).timeout(const Duration(seconds: 10));

    return response;
  }

  @override
  Future<void> addFavorite(String houseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado para añadir favorito');

    final url = Uri.parse('$_baseUrl/user/${user.uid}/favorites/$houseId');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final response = await http.post(url, headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Error al añadir a favoritos: ${response.body}');
    }
  }

  @override
  Future<List<House>> getFavoriteHouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado para añadir favorito');

    final url = Uri.parse('$_baseUrl/user/${user.uid}/favorites');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> housesJson = json.decode(response.body);
      return housesJson.map((json) => House.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los favoritos: ${response.body}');
    }
  }

  @override
  Future<void> removeFavorite(String houseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado para quitar favorito');

    final url = Uri.parse('$_baseUrl/user/${user.uid}/favorites/$houseId');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Error al quitar favorito');
  }


  @override
  Future<List<House>> getMyHouses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final url = Uri.parse('$_baseUrl/house/${user.uid}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> housesJson = json.decode(response.body);
      return housesJson.map((json) => House.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar mis casas: ${response.body}');
    }
  }

  @override
  Future<void> createHouse(House house) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. No se puede crear la casa.');
    }
    final url = Uri.parse('$_baseUrl/house');

    final requestBody = {
      'ownerId': user.uid,
      'point': {
        'lat': house.point.latitude,
        'lon': house.point.longitude,
      },
      'title': house.title,
      'price': house.price,
      'bedrooms': house.bedrooms,
      'bathrooms': house.bathrooms,
      'area': house.area,
      'imageUrls': house.imageUrls,
      'country': house.country,
      'department': house.department,
      'neighborhood': house.neighborhood
    };
    print('[KTOR CALL] Enviando a POST $url');
    print('[KTOR CALL] Body: ${json.encode(requestBody)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Casa creada con éxito en el servidor.');
      } else {
        print('Error del servidor: ${response.statusCode} - ${response.body}');
        throw Exception('Error al crear la casa en el servidor: ${response.body}');
      }
    } catch (e) {
      print('Error de conexión al crear casa: $e');
      throw Exception('No se pudo conectar al servidor. Inténtalo de nuevo.');
    }
  }

  @override
  Future<void> updateHouse(House house) async {
    print('[KTOR SIM] Actualizando casa: ${house.id}');
    await Future.delayed(const Duration(seconds: 1));
    // Aquí iría la llamada http.put a Ktor
    print('Éxito!');
  }

  @override
  Future<void> deleteHouse(String houseId) async {
    print('[KTOR SIM] Eliminando casa: $houseId');
    await Future.delayed(const Duration(seconds: 1));
    // Aquí iría la llamada http.delete a Ktor
    print('Éxito!');
  }

  @override
  Future<void> saveFilters(SearchFilterModel filters) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. No se pueden guardar los filtros.');
    }

    final url = Uri.parse('$_baseUrl/user/${user.uid}/filters');

    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = json.encode(filters.toMap());

    print('[KTOR SAVE FILTERS] Enviando a $url');
    print('[KTOR SAVE FILTERS] Body: $body');

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error del servidor al guardar los filtros: ${response.body}');
      }

      print('Filtros guardados exitosamente en el servidor.');

    } catch (e) {
      throw Exception('Error de red al guardar los filtros: ${e.toString()}');
    }
  }

  @override
  Future<SearchFilterModel> getUserFilters() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. No se pueden guardar los filtros.');
    }

    final url = Uri.parse('$_baseUrl/user/${user.uid}/filters');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SearchFilterModel.fromMap(json.decode(response.body));
      } else if (response.statusCode == 404) {
        print("No se encontraron filtros en el servidor. Usando valores por defecto.");
        return SearchFilterModel();
      } else {
        throw Exception('Error del servidor al cargar los filtros: ${response.body}');
      }
    } catch (e) {
      print("Error de conexión al obtener filtros: $e");
      throw Exception('No se pudo conectar al servidor para obtener los filtros.');
    }
  }
}
