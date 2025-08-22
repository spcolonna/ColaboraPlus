import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:latlong2/latlong.dart';

// Modelos, Servicios y Widgets necesarios
import '../models/House.dart';
import '../services/interfaces/IHouseService.dart';
import '../services/KtorHouseService.dart';
import '../services/LocationService.dart';
import '../services/FirestoreStreamService.dart';
import '../widgets/NearbyHouseCard.dart';
import '../widgets/DiscoveryCard.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // --- SERVICIOS Y CONTROLADORES ---
  final IHouseService _houseService = KtorHouseService();
  final LocationService _locationService = LocationService();
  final FirestoreStreamService _streamService = FirestoreStreamService();
  final CardSwiperController _swiperController = CardSwiperController();

  // --- ESTADO DE LA PÁGINA ---
  // Usamos un Future para la carga inicial de "Casas Cercanas"
  late Future<List<House>> _nearbyHousesFuture;
  // Usamos un Stream para la cola de descubrimiento en tiempo real
  late Stream<List<House>> _discoveryStream;

  // --- CICLO DE VIDA DEL WIDGET ---

  @override
  void initState() {
    super.initState();
    // Al iniciar la página, cargamos los datos y activamos los servicios.
    _initializePage();
  }

  @override
  void dispose() {
    // Detenemos los servicios al salir de la página para ahorrar batería.
    _locationService.stopTracking();
    _swiperController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS ---

  /// Inicializa los servicios y la carga de datos para la página.
  void _initializePage() {
    // Iniciamos el rastreo de ubicación que enviará pings a Ktor en segundo plano.
    // El servicio de Ktor se pasa aquí para que el location service pueda llamarlo.
    _locationService.startTracking(_houseService);

    // Cargamos la lista de casas cercanas solo una vez.
    _nearbyHousesFuture = _loadNearbyHouses();

    // Nos suscribimos al stream de la cola de descubrimiento para recibir actualizaciones en tiempo real.
    _discoveryStream = _streamService.getDiscoveryQueueStream();
  }

  /// Carga la lista de casas cercanas desde Ktor.
  Future<List<House>> _loadNearbyHouses() async {
    try {
      final locationData = await _getUserLocation();
      final userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      return await _houseService.getNearbyHouses(userLocation);
    } catch (e) {
      print('!!! ERROR CAPTURADO en _loadNearbyHouses: $e');
      // Devolvemos una lista vacía en caso de error para que la UI no se rompa.
      return [];
    }
  }

  /// Obtiene la ubicación del usuario, con lógica de permisos y timeout.
  Future<LocationData> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) throw Exception('Servicio de ubicación deshabilitado.');
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Permiso de ubicación denegado por el usuario.');
      }
    }

    return await location.getLocation().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        print('DEBUG: Timeout de ubicación. Usando ubicación harcodeada para Rivera y Soca.');
        return LocationData.fromMap({
          "latitude": -34.9004,
          "longitude": -56.1557,
          "accuracy": 50.0,
          "altitude": 0.0,
          "speed": 0.0,
          "speed_accuracy": 0.0,
          "heading": 0.0,
          "time": DateTime.now().millisecondsSinceEpoch.toDouble(),
        });
      },
    );
  }

  /// Se ejecuta cada vez que el usuario desliza una tarjeta del carrusel.
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction, List<House> discoveryHouses) {
    // Obtenemos el ID de la casa que se acaba de deslizar.
    final houseId = discoveryHouses[previousIndex].id;

    if (direction == CardSwiperDirection.right) {
      print('LIKE a la casa: $houseId');
      // TODO: Llamar al servicio para añadir a favoritos.
    } else if (direction == CardSwiperDirection.left) {
      print('DISLIKE a la casa: $houseId');
      // TODO: Llamar a un servicio para que Ktor elimine esta casa de la discovery_queue
      // y la marque como "vista" para no volver a mostrarla.
    }
    return true; // Permite que el swipe se complete.
  }

  // --- CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nido', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        // Permite al usuario refrescar manualmente la lista de casas cercanas.
        onRefresh: () async {
          setState(() {
            _nearbyHousesFuture = _loadNearbyHouses();
          });
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildSectionTitle('Cerca de Ti'),
            _buildNearbyHousesList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Descubre tu Próximo Hogar'),
            _buildDiscoverySwiper(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Widget de ayuda para los títulos de sección.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Construye la lista horizontal de casas cercanas usando un FutureBuilder.
  Widget _buildNearbyHousesList() {
    return FutureBuilder<List<House>>(
      future: _nearbyHousesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return ListTile(title: Text('Error al cargar casas cercanas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const ListTile(title: Text('No se encontraron casas cercanas.'));
        }

        final houses = snapshot.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: houses.length,
            itemBuilder: (context, index) => NearbyHouseCard(house: houses[index]),
          ),
        );
      },
    );
  }

  /// Construye el carrusel de descubrimiento usando un StreamBuilder para actualizaciones en tiempo real.
  Widget _buildDiscoverySwiper() {
    return StreamBuilder<List<House>>(
      stream: _discoveryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 500, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Sal a explorar para descubrir nuevas casas.', textAlign: TextAlign.center),
            ),
          );
        }

        final discoveryHouses = snapshot.data!;
        return SizedBox(
          height: 500,
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: discoveryHouses.length,
            onSwipe: (p, c, d) => _onSwipe(p, c, d, discoveryHouses),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            cardBuilder: (context, index, percentX, percentY) {
              return DiscoveryCard(house: discoveryHouses[index]);
            },
          ),
        );
      },
    );
  }
}
