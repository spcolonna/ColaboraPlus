import 'package:flutter/material.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:intl/intl.dart';

import '../models/prize_model.dart';

class CreateRaffleScreen extends StatefulWidget {
  const CreateRaffleScreen({super.key});

  @override
  State<CreateRaffleScreen> createState() => _CreateRaffleScreenState();
}

class _CreateRaffleScreenState extends State<CreateRaffleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raffleService = RaffleService();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  List<TextEditingController> _prizeControllers = [TextEditingController()];
  bool _isLimited = false;
  final _totalTicketsController = TextEditingController();
  List<TextEditingController> _customFieldControllers = [];

  String _selectedCountry = 'Uruguay';
  String _selectedCountryCode = 'UY';
  bool _isPrivate = false;
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _totalTicketsController.dispose();
    for (var controller in _prizeControllers) {
      controller.dispose();
    }
    for (var controller in _customFieldControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  void _addPrizeField() {
    setState(() => _prizeControllers.add(TextEditingController()));
  }

  void _removePrizeField(int index) {
    setState(() {
      _prizeControllers[index].dispose();
      _prizeControllers.removeAt(index);
    });
  }

  void _addCustomField() {
    setState(() => _customFieldControllers.add(TextEditingController()));
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFieldControllers[index].dispose();
      _customFieldControllers.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);

      try {
        final prizes = _prizeControllers
            .asMap().entries
            .map((entry) => PrizeModel(position: entry.key + 1, description: entry.value.text))
            .toList();

        final customFields = _customFieldControllers
            .map((controller) => controller.text.trim())
            .where((field) => field.isNotEmpty)
            .toList();

        await _raffleService.createRaffle(
          title: _titleController.text.trim(),
          ticketPrice: double.tryParse(_priceController.text) ?? 0.0,
          drawDate: _selectedDate!,
          prizes: prizes,
          isLimited: _isLimited,
          totalTickets: _isLimited ? int.tryParse(_totalTicketsController.text) : null,
          customFields: customFields,
          country: _selectedCountry,
          countryCode: _selectedCountryCode,
          isPrivate: _isPrivate,
          rafflePassword: _isPrivate ? _passwordController.text : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Rifa creada con éxito!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la rifa: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha para el sorteo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Rifa'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título de la Rifa'),
                validator: (value) => value!.isEmpty ? 'El título no puede estar vacío' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio por Boleto', prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'El precio es requerido' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Rifa con boletos limitados'),
                subtitle: const Text('Ej: 100 boletos del 0 al 99'),
                value: _isLimited,
                onChanged: (bool value) => setState(() => _isLimited = value),
              ),
              if (_isLimited)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    controller: _totalTicketsController,
                    decoration: const InputDecoration(labelText: 'Cantidad total de boletos'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (_isLimited && (value == null || value.isEmpty)) ? 'La cantidad es requerida' : null,
                  ),
                ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Seleccionar fecha y hora del sorteo'
                    : 'Fecha del Sorteo: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!)} hs'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 16),

              // --- WIDGET DEL SELECTOR DE PAÍS AÑADIDO AQUÍ ---
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(
                  labelText: 'País de la Rifa',
                  border: OutlineInputBorder(),
                ),
                items: <String>['Uruguay', 'Argentina', 'Brasil']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCountry = newValue;
                      // Lógica simple para asignar el código
                      if (newValue == 'Uruguay') _selectedCountryCode = 'UY';
                      else if (newValue == 'Argentina') _selectedCountryCode = 'AR';
                      else if (newValue == 'Brasil') _selectedCountryCode = 'BR';
                    });
                  }
                },
              ),
              // --- FIN DEL WIDGET ---

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Rifa Privada'),
                subtitle: const Text('Se requerirá una clave para ver y participar.'),
                value: _isPrivate,
                onChanged: (bool value) => setState(() => _isPrivate = value),
              ),
              if (_isPrivate) // Solo aparece si la rifa es privada
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Clave de la Rifa'),
                    validator: (value) => (_isPrivate && (value == null || value.isEmpty)) ? 'La clave es requerida' : null,
                  ),
                ),

              const Divider(height: 32),
              Text('Premios', style: Theme.of(context).textTheme.titleLarge),
              ..._buildPrizeFields(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Premio'),
                onPressed: _addPrizeField,
              ),
              const Divider(height: 32),
              Text('Información Adicional a Solicitar', style: Theme.of(context).textTheme.titleLarge),
              const Text('Ej: "Nº de Documento", etc. Déjalo en blanco si no necesitas campos extra.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              ..._buildCustomFields(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Campo'),
                onPressed: _addCustomField,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Crear Rifa'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrizeFields() {
    return _prizeControllers.asMap().entries.map((entry) {
      int index = entry.key;
      TextEditingController controller = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Descripción del ${index + 1}º Premio',
            suffixIcon: _prizeControllers.length > 1
                ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removePrizeField(index),
            )
                : null,
          ),
          validator: (value) => value!.isEmpty ? 'La descripción es requerida' : null,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCustomFields() {
    return _customFieldControllers.asMap().entries.map((entry) {
      int index = entry.key;
      TextEditingController controller = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nombre del campo ${index + 1}',
            suffixIcon: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeCustomField(index),
            ),
          ),
        ),
      );
    }).toList();
  }
}
