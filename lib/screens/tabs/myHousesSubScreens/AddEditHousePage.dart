import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:dotted_border/dotted_border.dart';

import 'package:matchhouse_flutter/models/House.dart';
import 'package:matchhouse_flutter/services/interfaces/IProfileService.dart';
import 'package:matchhouse_flutter/services/KtorUserService.dart';
import 'package:matchhouse_flutter/services/StorageService.dart';

import 'package:matchhouse_flutter/screens/tabs/myHousesSubScreens/MapPickerPage.dart';

import '../../../services/KtorLocationService.dart';
import '../../../services/interfaces/ILocationService.dart';

class AddEditHousePage extends StatefulWidget {
  final House? house; // Si es null, estamos creando. Si no, editando.

  const AddEditHousePage({super.key, this.house});

  @override
  State<AddEditHousePage> createState() => _AddEditHousePageState();
}

class _AddEditHousePageState extends State<AddEditHousePage> {
  final _formKey = GlobalKey<FormState>();
  final IProfileService _userService = KtorUserService();
  final StorageService _storageService = StorageService();
  final ILocationService _locationService = KtorLocationService();
  bool _isSaving = false;

  // Controladores para los campos de texto
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _areaController;
  LatLng? _selectedLocation;

  // Estado para las imágenes
  final ImagePicker _picker = ImagePicker();
  XFile? _newCoverImageFile;
  String? _existingCoverImageUrl;
  final List<XFile> _newAdditionalImageFiles = [];
  final List<String> _existingAdditionalImageUrls = [];

  List<String> _availableCountries = [];
  List<String> _availableDepartments = [];
  List<String> _availableNeighborhoods = [];
  String? _selectedCountry;
  String? _selectedDepartment;
  String? _selectedNeighborhood;
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.house?.title ?? '');
    _priceController = TextEditingController(text: widget.house?.price.toString() ?? '');
    _bedroomsController = TextEditingController(text: widget.house?.bedrooms.toString() ?? '');
    _bathroomsController = TextEditingController(text: widget.house?.bathrooms.toString() ?? '');
    _areaController = TextEditingController(text: widget.house?.area.toString() ?? '');
    _selectedLocation = widget.house?.point;

    // Lógica para poblar el estado con las imágenes existentes si estamos editando
    if (widget.house != null && widget.house!.imageUrls.isNotEmpty) {
      _existingCoverImageUrl = widget.house!.imageUrls.first;
      _existingAdditionalImageUrls.addAll(widget.house!.imageUrls.skip(1));
    }

    _loadInitialLocationData();
  }

  Future<void> _loadInitialLocationData() async {
    try {
      final countries = await _locationService.getAvailableCountries();
      if (mounted) {
        setState(() {
          _availableCountries = countries;
          // Si estamos editando, pre-seleccionamos los valores guardados
          if (widget.house != null) {
            _selectedCountry = widget.house!.country;
            if (_selectedCountry != null) {
              _onCountrySelected(_selectedCountry, initialLoad: true);
            }
          }
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
      print("Error cargando países: $e");
    }
  }

  Future<void> _onCountrySelected(String? country, {bool initialLoad = false}) async {
    if (country == null) return;
    setState(() {
      _selectedCountry = country;
      if (!initialLoad) {
        _selectedDepartment = null;
        _selectedNeighborhood = null;
      }
      _availableDepartments = [];
      _availableNeighborhoods = [];
    });
    try {
      final departments = await _locationService.getDepartments(country);
      if (mounted) {
        setState(() {
          _availableDepartments = departments;
          if (initialLoad && widget.house != null) {
            _selectedDepartment = widget.house!.department;
            if (_selectedDepartment != null) {
              _onDepartmentSelected(_selectedDepartment, initialLoad: true);
            }
          }
        });
      }
    } catch (e) { /* ... */ }
  }

  Future<void> _onDepartmentSelected(String? department, {bool initialLoad = false}) async {
    if (department == null || _selectedCountry == null) return;
    setState(() {
      _selectedDepartment = department;
      if (!initialLoad) {
        _selectedNeighborhood = null;
      }
      _availableNeighborhoods = [];
    });
    try {
      final neighborhoods = await _locationService.getNeighborhoods(_selectedCountry!, department);
      if (mounted) {
        setState(() {
          _availableNeighborhoods = neighborhoods;
          if (initialLoad && widget.house != null) {
            _selectedNeighborhood = widget.house!.neighborhood;
          }
        });
      }
    } catch (e) { /* ... */ }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPickerPage(initialLocation: _selectedLocation),
      ),
    );
    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _newCoverImageFile = image;
        // Si había una imagen existente, la reemplazamos con la nueva
        _existingCoverImageUrl = null;
      });
    }
  }

  Future<void> _pickAdditionalImages() async {
    final int currentTotal = _existingAdditionalImageUrls.length + _newAdditionalImageFiles.length;
    final int remainingSlots = 6 - currentTotal;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has alcanzado el límite de 6 fotos adicionales.')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _newAdditionalImageFiles.addAll(images.take(remainingSlots));
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    if ((_newCoverImageFile == null && _existingCoverImageUrl == null) || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa la foto de portada y la ubicación.')),
      );
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final houseId = widget.house?.id ?? const Uuid().v4();
      List<String> finalImageUrls = [];

      // Subimos la nueva foto de portada si el usuario seleccionó una
      if (_newCoverImageFile != null) {
        final fileExtension = _newCoverImageFile!.path.split('.').last;
        final fileName = 'cover_${const Uuid().v4()}.$fileExtension';
        final path = 'houses/$houseId/$fileName';

        final imageUrl = await _storageService.uploadImage(_newCoverImageFile!, path);
        finalImageUrls.add(imageUrl);
      } else if (_existingCoverImageUrl != null) {
        finalImageUrls.add(_existingCoverImageUrl!);
      }

      // Subimos las nuevas fotos adicionales
      for (final imageFile in _newAdditionalImageFiles) {
        final fileExtension = imageFile.path.split('.').last;
        final fileName = 'additional_${const Uuid().v4()}.$fileExtension';
        final path = 'houses/$houseId/$fileName';

        final imageUrl = await _storageService.uploadImage(imageFile, path);
        finalImageUrls.add(imageUrl);
      }
      // Y mantenemos las existentes que no se hayan eliminado
      finalImageUrls.addAll(_existingAdditionalImageUrls);

      final houseData = House(
        id: houseId,
        title: _titleController.text.trim(),
        price: int.tryParse(_priceController.text) ?? 0,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        area: double.tryParse(_areaController.text) ?? 0.0,
        point: _selectedLocation!,
        imageUrls: finalImageUrls,
        country: _selectedCountry,
        department: _selectedDepartment,
        neighborhood: _selectedNeighborhood,
      );

      // Llamamos al servicio para enviar los datos a Ktor
      if (widget.house == null) {
        await _userService.createHouse(houseData);
      } else {
        await _userService.updateHouse(houseData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Propiedad guardada con éxito!')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.house == null ? 'Agregar Casa' : 'Editar Casa'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))),
            )
          else
            IconButton(onPressed: _submitForm, icon: const Icon(Icons.save))
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Foto de Portada *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildCoverImagePicker(),
            const SizedBox(height: 24),
            const Text('Fotos Adicionales (hasta 6)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildAdditionalImagesGrid(),
            const SizedBox(height: 24),
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _bedroomsController, decoration: const InputDecoration(labelText: 'Dormitorios *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _bathroomsController, decoration: const InputDecoration(labelText: 'Baños *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _areaController, decoration: const InputDecoration(labelText: 'Área (m²) *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            const Text('Ubicación de la Propiedad *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_isLoadingLocations)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildDropdown<String>(_selectedCountry, _availableCountries, (value) => _onCountrySelected(value), 'País'),
                  const SizedBox(height: 16),
                  _buildDropdown<String>(_selectedDepartment, _availableDepartments, (value) => _onDepartmentSelected(value), 'Departamento', enabled: _selectedCountry != null),
                  const SizedBox(height: 16),
                  _buildDropdown<String>(_selectedNeighborhood, _availableNeighborhoods, (value) { setState(() => _selectedNeighborhood = value); }, 'Barrio', enabled: _selectedDepartment != null),
                ],
              ),

            const SizedBox(height: 20),
            const Text('Pin en el Mapa *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedLocation == null
                          ? 'Ninguna ubicación seleccionada'
                          : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lon: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: _selectedLocation == null ? Colors.grey : Colors.black),
                    ),
                  ),
                  ElevatedButton(onPressed: _pickLocationOnMap, child: const Text('Elegir en Mapa'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T? currentValue, List<T> items, ValueChanged<T?> onChanged, String hint, {bool enabled = true}) {
    final T? value = (currentValue != null && items.contains(currentValue)) ? currentValue : null;
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint),
      isExpanded: true,
      decoration: InputDecoration(border: const OutlineInputBorder()),
      items: items.map((T item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Campo requerido' : null,
    );
  }

  Widget _buildCoverImagePicker() {
    Widget imageContent;
    if (_newCoverImageFile != null) {
      imageContent = Image.file(File(_newCoverImageFile!.path), fit: BoxFit.cover);
    } else if (_existingCoverImageUrl != null) {
      imageContent = Image.network(_existingCoverImageUrl!, fit: BoxFit.cover);
    } else {
      imageContent = const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey));
    }

    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: imageContent,
      ),
    );
  }

  Widget _buildAdditionalImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _existingAdditionalImageUrls.length + _newAdditionalImageFiles.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        // Mostramos las imágenes existentes primero
        if (index < _existingAdditionalImageUrls.length) {
          final imageUrl = _existingAdditionalImageUrls[index];
          return _buildImageThumbnail(Image.network(imageUrl, fit: BoxFit.cover), () {
            setState(() => _existingAdditionalImageUrls.removeAt(index));
          });
        }
        // Luego las nuevas imágenes seleccionadas
        final newImageIndex = index - _existingAdditionalImageUrls.length;
        if (newImageIndex < _newAdditionalImageFiles.length) {
          final imageFile = _newAdditionalImageFiles[newImageIndex];
          return _buildImageThumbnail(Image.file(File(imageFile.path), fit: BoxFit.cover), () {
            setState(() => _newAdditionalImageFiles.removeAt(newImageIndex));
          });
        }


        if (index == _existingAdditionalImageUrls.length + _newAdditionalImageFiles.length) {
          final currentTotal = _existingAdditionalImageUrls.length + _newAdditionalImageFiles.length;
          if (currentTotal < 6) {

            return GestureDetector(
              onTap: _pickAdditionalImages,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: Colors.grey.shade600,
                  strokeWidth: 2,
                  dashPattern: const [6, 4],
                  radius: Radius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.grey, size: 40),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildImageThumbnail(Widget image, VoidCallback onDelete) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
