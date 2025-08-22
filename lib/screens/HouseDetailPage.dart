import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:matchhouse_flutter/models/House.dart';

import 'FullscreenGalleryPage.dart';

class HouseDetailPage extends StatefulWidget {
  final House house;

  const HouseDetailPage({super.key, required this.house});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached && widget.house.imageUrls.isNotEmpty) {
      for (final imageUrl in widget.house.imageUrls) {
        precacheImage(NetworkImage(imageUrl), context);
      }
      _imagesPrecached = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentImageIndex) {
        setState(() {
          _currentImageIndex = _pageController.page?.round() ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un Stack para poder poner el botón de back sobre el CustomScrollView
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                stretch: true, // Efecto de estiramiento al hacer overscroll
                // Hacemos el AppBar transparente para que la imagen ocupe todo
                backgroundColor: Colors.transparent,
                elevation: 0,
                // Quitamos el botón de back por defecto para poner el nuestro
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageGallery(),
                ),
              ),

              // Contenido Principal de la Página
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.house.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.house.price}',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(context, Icons.bed_outlined, '${widget.house.bedrooms}', 'Dorm.'),
                              _buildDetailItem(context, Icons.shower_outlined, '${widget.house.bathrooms}', 'Baños'),
                              _buildDetailItem(context, Icons.square_foot_outlined, '${widget.house.area} m²', 'Área'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Ubicación',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: widget.house.point,
                                  initialZoom: 16.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                                  ),
                                ),
                                children: [
                                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: widget.house.point,
                                        child: const Icon(Icons.location_on, size: 50, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Espacio extra para que el botón flotante no tape el contenido
                          const SizedBox(height: 100),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),

          // --- 1. NUEVO BOTÓN DE "BACK" PERSONALIZADO ---
          // Lo ponemos en un Positioned para que flote sobre la imagen
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // Se ajusta al notch del teléfono
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
      // --- 2. NUEVO BOTÓN FLOTANTE PARA "CONTACTAR" ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Lógica para contactar
          print('Botón de Contactar presionado para la casa: ${widget.house.id}');
          // TODO: Llamar al servicio para registrar la métrica y enviar notificación a Ktor
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contactando al propietario... (simulación)')),
          );
        },
        label: const Text('Contactar'),
        icon: const Icon(Icons.chat_bubble_outline),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.house.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.house_siding, size: 100, color: Colors.grey),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // El PageView ahora está envuelto en un GestureDetector
        GestureDetector(
          onTap: () {
            // --- NUEVO: NAVEGACIÓN A PANTALLA COMPLETA ---
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullscreenGalleryPage(
                  imageUrls: widget.house.imageUrls,
                  initialIndex: _currentImageIndex,
                ),
              ),
            );
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.house.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.house.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              );
            },
          ),
        ),
        // Los puntos indicadores (sin cambios)
        Positioned(
          bottom: 10.0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.house.imageUrls.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // Widget de ayuda para los ítems de detalle (dormitorios, etc.)
  Widget _buildDetailItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 30),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
