import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/SearchFilterModel.dart';
import 'package:matchhouse_flutter/services/interfaces/ILocationService.dart';
import 'package:matchhouse_flutter/services/KtorLocationService.dart';

class SearchFiltersTab extends StatefulWidget {
  final SearchFilterModel filters;
  final Future<void> Function(SearchFilterModel newFilters) onSave;

  const SearchFiltersTab({
    super.key,
    required this.filters,
    required this.onSave
  });
  @override
  State<SearchFiltersTab> createState() => _SearchFiltersTabState();
}

class _SearchFiltersTabState extends State<SearchFiltersTab> {
  final ILocationService _locationService = KtorLocationService();
  late SearchFilterModel _filters;
  bool _isSaving = false;

  List<String> _availableCountries = [];
  List<String> _availableDepartments = [];
  List<String> _availableNeighborhoods = [];

  String? _selectedCountry;
  String? _selectedDepartment;
  String? _selectedNeighborhood;

  bool _isLoadingCountries = true;
  bool _isLoadingDepartments = false;
  bool _isLoadingNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
    _selectedCountry = _filters.country;
    _selectedDepartment = _filters.department;
    _selectedNeighborhood = _filters.neighborhood;
    _loadInitialCountries();
  }

  Future<void> _loadInitialCountries() async {
    try {
      final countries = await _locationService.getAvailableCountries();
      if (mounted) {
        setState(() {
          _availableCountries = countries;
          _isLoadingCountries = false;
          // Si ya hay un país seleccionado (porque venía guardado), cargamos sus departamentos
          if (_selectedCountry != null) {
            _onCountrySelected(_selectedCountry, initialLoad: true);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCountries = false);
      print("Error cargando países: $e");
    }
  }

  Future<void> _onCountrySelected(String? country, {bool initialLoad = false}) async {
    if (country == null) return;

    setState(() {
      _selectedCountry = country;
      _filters.country = country;
      _isLoadingDepartments = true;
      // Si no es la carga inicial, reseteamos las selecciones dependientes
      if (!initialLoad) {
        _selectedDepartment = null;
        _filters.department = null;
        _selectedNeighborhood = null;
        _filters.neighborhood = null;
      }
      _availableDepartments = [];
      _availableNeighborhoods = [];
    });

    try {
      final departments = await _locationService.getDepartments(country);
      if (mounted) {
        setState(() {
          _availableDepartments = departments;
          _isLoadingDepartments = false;
          // Si es la carga inicial y ya hay un departamento guardado, lo seleccionamos
          if (initialLoad && _selectedDepartment != null) {
            _onDepartmentSelected(_selectedDepartment, initialLoad: true);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDepartments = false);
      print("Error cargando departamentos: $e");
    }
  }

  Future<void> _onDepartmentSelected(String? department, {bool initialLoad = false}) async {
    if (department == null || _selectedCountry == null) return;

    setState(() {
      _selectedDepartment = department;
      _filters.department = department;
      _isLoadingNeighborhoods = true;
      if (!initialLoad) {
        _selectedNeighborhood = null;
        _filters.neighborhood = null;
      }
      _availableNeighborhoods = [];
    });

    try {
      final neighborhoods = await _locationService.getNeighborhoods(_selectedCountry!, department);
      if (mounted) {
        setState(() {
          _availableNeighborhoods = neighborhoods;
          _isLoadingNeighborhoods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNeighborhoods = false);
      print("Error cargando barrios: $e");
    }
  }

  void _activateFilters() async {
    if (_isSaving) return;
    setState(() { _isSaving = true; });

    try {
      await widget.onSave(_filters);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filtros guardados con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar filtros: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }


  void _clearFilters() {
    setState(() {
      _filters = SearchFilterModel();
      _selectedCountry = _filters.country;
      _selectedDepartment = _filters.department;
      _selectedNeighborhood = _filters.neighborhood;
      if (_selectedCountry != null) {
        _onCountrySelected(_selectedCountry);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCountries) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Ubicación'),
          _buildDropdown<String>(_selectedCountry, _availableCountries, (value) => _onCountrySelected(value), 'País', (c) => c),
          const Divider(),
          _isLoadingDepartments
              ? const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()))
              : _buildDropdown<String>(_selectedDepartment, _availableDepartments, (value) => _onDepartmentSelected(value), 'Departamento', (d) => d, enabled: _selectedCountry != null),
          const Divider(),
          _isLoadingNeighborhoods
              ? const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()))
              : _buildDropdown<String>(_selectedNeighborhood, _availableNeighborhoods, (n) {
            setState(() {
              _selectedNeighborhood = n;
              _filters.neighborhood = n;
            });
          }, 'Barrio', (name) => name, enabled: _selectedDepartment != null),
          const SizedBox(height: 24),
          _buildSectionTitle('Rango de Precio'),
          RangeSlider(
            min: 0,
            max: 1000000,
            divisions: 100,
            values: RangeValues(_filters.minPrice, _filters.maxPrice),
            labels: RangeLabels('\$${_filters.minPrice.round()}', '\$${_filters.maxPrice.round()}'),
            onChanged: (values) {
              setState(() {
                _filters.minPrice = values.start;
                _filters.maxPrice = values.end;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('\$${_filters.minPrice.toInt()}'), Text('\$${_filters.maxPrice.toInt()}')],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Características'),
          _buildCounter('Mínimo de Dormitorios', Icons.bed_outlined, _filters.bedrooms, (newValue) {
            setState(() => _filters.bedrooms = newValue);
          }),
          const Divider(),
          _buildCounter('Mínimo de Baños', Icons.shower_outlined, _filters.bathrooms, (newValue) {
            setState(() => _filters.bathrooms = newValue);
          }),
          const Divider(),
          _buildCounter('Mínimo de Área (m²)', Icons.square_foot_outlined, _filters.area, (newValue) {
            setState(() => _filters.area = newValue);
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: _clearFilters, child: const Text('Limpiar')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _activateFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Activar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T? currentValue, List<T> items, ValueChanged<T?> onChanged, String hint, String Function(T) itemText, {bool enabled = true}) {
    // Verificamos si el valor actual está en la lista de items.
    // Si no está, usamos null para que se muestre el hint.
    final T? value = (currentValue != null && items.contains(currentValue)) ? currentValue : null;

    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint),
      isExpanded: true,
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(
          hint == 'País' ? Icons.public : (hint == 'Departamento' ? Icons.location_city : Icons.location_on_outlined),
          color: enabled ? Colors.black54 : Colors.grey.shade400,
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemText(item)),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCounter(String label, IconData icon, int currentValue, ValueChanged<int> onChanged) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: currentValue > 0 ? () => onChanged(currentValue - 1) : null,
          ),
          Text(currentValue.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(currentValue + 1),
          ),
        ],
      ),
    );
  }
}
