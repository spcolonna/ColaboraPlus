import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile image, String path) async {
    // --- NUEVO: Logs de diagnóstico ---
    print('[STORAGE SERVICE DEBUG] Intentando subir a la ruta: $path');
    print('[STORAGE SERVICE DEBUG] Longitud de la ruta: ${path.length}');
    // ------------------------------------

    try {
      // La lógica de subida no cambia.
      final ref = _storage.ref(path);
      final uploadTask = await ref.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // El error que estás viendo se origina aquí.
      print("Error al subir imagen: $e");
      // Re-lanzamos la excepción para que la UI sepa que algo falló.
      throw Exception('No se pudo subir la imagen.');
    }
  }
}
