import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/UserModel.dart'; // Asegúrate que tu UserModel esté simplificado (sin roles)

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra un usuario con email/contraseña y crea su perfil básico en Firestore.
  /// Devuelve un UserModel si tiene éxito, o null si falla.
  Future<UserModel?> signUpWithEmailPassword(String email, String password) async {
    try {
      // 1. Crear el usuario en Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // 2. Crear el perfil básico en la base de datos de Firestore
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          // name y phoneNumber se quedan vacíos, como querías
        );

        // Guardamos el nuevo usuario en la colección 'users'
        // El ID del documento será el mismo que el UID de autenticación
        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

        // Devolvemos el modelo de usuario recién creado
        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      // Manejar errores de Firebase (email en uso, contraseña débil, etc.)
      print('Error de FirebaseAuth: ${e.message}');
      return null;
    } catch (e) {
      print('Ocurrió un error inesperado al registrar: $e');
      return null;
    }
    return null;
  }
}
