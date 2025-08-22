import 'package:flutter/material.dart';

class FullscreenGalleryPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenGalleryPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenGalleryPage> createState() => _FullscreenGalleryPageState();
}

class _FullscreenGalleryPageState extends State<FullscreenGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Icono para cerrar la vista de pantalla completa
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Galería deslizable con zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              // InteractiveViewer es el widget que permite hacer zoom y pan
              return InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain, // Contain para ver la foto entera
                ),
              );
            },
          ),
          // Indicador de página (ej: "Foto 3 de 7")
          Positioned(
            bottom: 20.0,
            child: Text(
              '${_currentIndex + 1} / ${widget.imageUrls.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [
                Shadow(color: Colors.black, blurRadius: 4)
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
