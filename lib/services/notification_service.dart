import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Pedir permisos al usuario (para iOS y Android 13+)
    await _fcm.requestPermission();

    // Obtener el token del dispositivo
    final fcmToken = await _fcm.getToken();
    print('FCM Token: $fcmToken');

    // Guardar el token en Firestore
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // Si el token se refresca, lo guardamos de nuevo
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Usamos FieldValue.arrayUnion para añadir el token a la lista sin duplicarlo
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
}
