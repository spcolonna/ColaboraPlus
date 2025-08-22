import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matchhouse_flutter/models/House.dart';
import 'package:matchhouse_flutter/models/SearchFilterModel.dart';

class FirestoreStreamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Devuelve un Stream de casas de la cola de descubrimiento del usuario.
  Stream<List<House>> getDiscoveryQueueStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Si no hay usuario, devuelve un stream vacío para no causar errores.
      return Stream.value([]);
    }

    // Apuntamos a la subcolección 'discoveryQueue' del usuario actual
    final query = _db
        .collection('users')
        .doc(user.uid)
        .collection('discoveryQueue');

    // .snapshots() es la función mágica que nos da el Stream en tiempo real
    return query.snapshots().map((snapshot) {
      // Cada vez que hay un cambio, convertimos los documentos a objetos House
      return snapshot.docs
          .map((doc) => House.fromJson(doc.data()))
          .toList();
    });
  }

  /// Devuelve un Stream de casas que coincide con los filtros del usuario.
  Stream<List<House>> getFilteredHousesStream(SearchFilterModel filters) {
    Query query = _db.collection('houses');

    // --- CONSTRUIMOS LA CONSULTA DINÁMICAMENTE ---
    if (filters.country != null && filters.country!.isNotEmpty) {
      query = query.where('country', isEqualTo: filters.country);
    }
    if (filters.department != null && filters.department!.isNotEmpty) {
      query = query.where('department', isEqualTo: filters.department);
    }
    if (filters.neighborhood != null && filters.neighborhood!.isNotEmpty) {
      query = query.where('neighborhood', isEqualTo: filters.neighborhood);
    }

    query = query.where('price', isGreaterThanOrEqualTo: filters.minPrice);
    query = query.where('price', isLessThanOrEqualTo: filters.maxPrice);

    if (filters.bedrooms > 0) {
      query = query.where('bedrooms', isGreaterThanOrEqualTo: filters.bedrooms);
    }
    if (filters.bathrooms > 0) {
      query = query.where('bathrooms', isGreaterThanOrEqualTo: filters.bathrooms);
    }
    if (filters.area > 0) {
      query = query.where('area', isGreaterThanOrEqualTo: filters.area);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => House.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }
}
