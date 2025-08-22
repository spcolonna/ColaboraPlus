import 'package:flutter/material.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/theme/AppColors.dart';

import '../models/prize_model.dart';

class CreateRaffleScreen extends StatefulWidget {
  const CreateRaffleScreen({super.key});

  @override
  State<CreateRaffleScreen> createState() => _CreateRaffleScreenState();
}

class _CreateRaffleScreenState extends State<CreateRaffleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raffleService = RaffleService();

  // Controllers para los campos principales
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;

  // Lista para manejar los controllers de los premios
  List<TextEditingController> _prizeControllers = [TextEditingController()];

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addPrizeField() {
    setState(() {
      _prizeControllers.add(TextEditingController());
    });
  }

  void _removePrizeField(int index) {
    setState(() {
      _prizeControllers[index].dispose();
      _prizeControllers.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final prizes = _prizeControllers
            .asMap()
            .entries
            .map((entry) => PrizeModel(position: entry.key + 1, description: entry.value.text))
            .toList();

        await _raffleService.createRaffle(
          title: _titleController.text.trim(),
          ticketPrice: double.tryParse(_priceController.text) ?? 0.0,
          drawDate: _selectedDate!,
          prizes: prizes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Rifa creada con éxito!')),
          );
          Navigator.of(context).pop(); // Volver a la pantalla anterior
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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    for (var controller in _prizeControllers) {
      controller.dispose();
    }
    super.dispose();
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
              // Selector de fecha
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Seleccionar fecha del sorteo'
                    : 'Fecha del Sorteo: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const Divider(height: 32),
              // Sección de premios
              Text('Premios', style: Theme.of(context).textTheme.titleLarge),
              ..._buildPrizeFields(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Premio'),
                onPressed: _addPrizeField,
              ),
              const SizedBox(height: 32),
              // Botón de Crear
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
}
