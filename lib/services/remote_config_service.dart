import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  // La instancia sigue siendo privada
  static RemoteConfigService? _instance;

  // Constructor privado
  RemoteConfigService._(this._remoteConfig);

  // --- GETTER PÚBLICO AÑADIDO AQUÍ ---
  // Este es el método público y seguro para obtener la instancia ya creada.
  static RemoteConfigService get instance {
    if (_instance == null) {
      throw Exception('RemoteConfigService no ha sido inicializado. Llama a getInstance() primero en tu main.dart');
    }
    return _instance!;
  }
  // --- FIN DE LA MODIFICACIÓN ---

  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(const {
        "online_payments_enabled": false,
      });
      _instance = RemoteConfigService._(remoteConfig);
    }
    return _instance!;
  }

  bool get onlinePaymentsEnabled => _remoteConfig.getBool('online_payments_enabled');

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error al cargar Remote Config: $e');
    }
  }
}
