import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:intl/intl.dart';

import '../enums/payment_method.dart';
import '../models/raffle_model.dart';

class RaffleDetailScreen extends StatefulWidget {
  final RaffleModel raffle;
  const RaffleDetailScreen({super.key, required this.raffle});

  @override
  State<RaffleDetailScreen> createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends State<RaffleDetailScreen> {
  final _raffleService = RaffleService();

  // --- ESTADO: AHORA MANEJA UNA LISTA DE NÚMEROS ---
  final List<int> _selectedNumbers = [];
  PaymentMethod _paymentMethod = PaymentMethod.online;
  bool _isLoading = false;
  String? _errorText;

  // --- LÓGICA DE NEGOCIO ---

  /// Genera una cantidad `quantity` de números al azar y los añade a la selección.
  Future<void> _assignRandomNumbers(int quantity) async {
    setState(() { _isLoading = true; _errorText = null; });
    final random = Random();
    List<int> newNumbers = [];
    int attempts = 0;
    int maxAttempts = quantity * 10; // Damos un margen de intentos

    while (newNumbers.length < quantity && attempts < maxAttempts) {
      int randomNumber = 1000 + random.nextInt(99000); // Genera un número de 4 o 5 cifras

      // Verificamos que no esté ya en la lista actual Y que no esté tomado en la DB
      if (!_selectedNumbers.contains(randomNumber) && !newNumbers.contains(randomNumber)) {
        bool isTaken = await _raffleService.isNumberTaken(raffleId: widget.raffle.id, number: randomNumber);
        if (!isTaken) {
          newNumbers.add(randomNumber);
        }
      }
      attempts++;
    }

    if (newNumbers.length < quantity) {
      _errorText = "No se pudieron generar todos los números. Puede que haya pocos disponibles.";
    }

    setState(() {
      _selectedNumbers.addAll(newNumbers);
      _isLoading = false;
    });
  }

  /// Añade un número introducido manualmente a la selección.
  Future<void> _addManualNumber(String numberStr) async {
    final number = int.tryParse(numberStr);
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, ingresa un número válido.")));
      return;
    }

    if (_selectedNumbers.contains(number)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ya has añadido este número.")));
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });
    bool isTaken = await _raffleService.isNumberTaken(raffleId: widget.raffle.id, number: number);

    if (isTaken) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El número $number ya está ocupado.")));
    } else {
      setState(() {
        _selectedNumbers.add(number);
      });
    }
    setState(() => _isLoading = false);
  }

  /// Procesa la compra de TODOS los boletos seleccionados.
  Future<void> _buyTickets() async {
    if (_selectedNumbers.isEmpty) {
      setState(() => _errorText = "Debes añadir al menos un número.");
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });

    try {
      await _raffleService.purchaseTicket(
        raffle: widget.raffle,
        numbers: _selectedNumbers,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Felicidades! Has comprado ${_selectedNumbers.length} boleto(s).')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      setState(() {
        _errorText = "Error al comprar los boletos: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  /// Dialog para pedir la cantidad de números al azar
  void _showRandomNumberDialog() {
    final controller = TextEditingController(text: '1');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Generar al Azar"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '¿Cuántos números quieres?'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
          ),
          actions: [
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(ctx).pop()),
            ElevatedButton(child: const Text("Generar"), onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty > 0) {
                _assignRandomNumbers(qty);
              }
              Navigator.of(ctx).pop();
            }),
          ],
        )
    );
  }

  /// Widget para el input manual
  Widget _buildManualNumberInput() {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Escribe un número y añádelo',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              _addManualNumber(controller.text);
              controller.clear();
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.raffle.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN DE INFORMACIÓN (SIN CAMBIOS) ---
            Text("Premios:", style: Theme.of(context).textTheme.headlineSmall),
            ...widget.raffle.prizes.map((p) => ListTile(
              leading: CircleAvatar(child: Text(p.position.toString())),
              title: Text(p.description),
            )),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
              title: Text("Fecha del Sorteo: ${DateFormat('dd/MM/yyyy').format(widget.raffle.drawDate)}"),
            ),
            ListTile(
              leading: Icon(Icons.attach_money, color: AppColors.accentGreen),
              title: Text("Precio por Boleto: \$${widget.raffle.ticketPrice.toStringAsFixed(2)}"),
            ),
            const Divider(height: 32),

            // --- SECCIÓN DE COMPRA ACTUALIZADA ---
            Text("¡Participa Ahora!", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            _buildManualNumberInput(),
            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.casino_outlined),
                label: const Text("Generar Número(s) al Azar"),
                onPressed: () => _showRandomNumberDialog(),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Tus números seleccionados:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _selectedNumbers.isEmpty
                ? const Center(child: Text("Aún no has añadido números.", style: TextStyle(color: Colors.grey)))
                : Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedNumbers.map((num) => Chip(
                label: Text(num.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                onDeleted: () => setState(() => _selectedNumbers.remove(num)),
                deleteIcon: const Icon(Icons.close, size: 16),
              )).toList(),
            ),

            const Divider(height: 32),

            // --- SECCIÓN DE PAGO (SIN CAMBIOS) ---
            const Text("Método de Pago:", style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<PaymentMethod>(
              title: const Text("Pago Online (MercadoPago/Stripe)"),
              value: PaymentMethod.online,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            RadioListTile<PaymentMethod>(
              title: const Text("Pago en Persona"),
              subtitle: const Text("Requiere confirmación del administrador"),
              value: PaymentMethod.manual,
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),

            const SizedBox(height: 24),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),

            // --- BOTÓN DE COMPRA ACTUALIZADO ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                onPressed: (_selectedNumbers.isEmpty || _isLoading) ? null : _buyTickets,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                    _selectedNumbers.isEmpty
                        ? "Añade un número para comprar"
                        : "Comprar ${_selectedNumbers.length} Boleto(s) por \$${(widget.raffle.ticketPrice * _selectedNumbers.length).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
