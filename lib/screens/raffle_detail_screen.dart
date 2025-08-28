import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../enums/payment_method.dart';
import '../enums/raffle_status.dart';
import '../models/raffle_model.dart';
import '../services/remote_config_service.dart';
import '../widgets/winners_podium.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RaffleDetailScreen extends StatefulWidget {
  final RaffleModel raffle;
  const RaffleDetailScreen({super.key, required this.raffle});

  @override
  State<RaffleDetailScreen> createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends State<RaffleDetailScreen> {
  final _raffleService = RaffleService();

  final List<int> _selectedNumbers = [];
  PaymentMethod _paymentMethod = PaymentMethod.online;
  bool _isLoading = false;
  String? _errorText;

  Future<Set<int>>? _soldNumbersFuture;
  final _numberSearchController = TextEditingController();
  String _numberSearchQuery = '';
  int _visibleNumberLimit = 10;

  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _customDataControllers;
  bool _isAdmin = false;
  final _adminNotesController = TextEditingController();

  final RemoteConfigService _remoteConfigService = RemoteConfigService.instance;

  @override
  void initState() {
    super.initState();
    // Lógica para rifas limitadas
    if (widget.raffle.isLimited) {
      _soldNumbersFuture =
          _raffleService.getSoldTicketNumbers(widget.raffle.id);
      _numberSearchController.addListener(() {
        setState(() => _numberSearchQuery = _numberSearchController.text);
      });
    }
    // Lógica para campos personalizados
    _customDataControllers = {
      for (var field in widget.raffle.customFields) field: TextEditingController()
    };

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.raffle.creatorId) {
      _isAdmin = true;
    }
  }

  @override
  void dispose() {
    _numberSearchController.dispose();
    for (var controller in _customDataControllers.values) {
      controller.dispose();
    }
    _adminNotesController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE COMPRA ---
  Future<void> _buyTickets() async {
    // 1. Validamos que haya números seleccionados
    if (_selectedNumbers.isEmpty) {
      setState(() => _errorText = "Debes añadir al menos un número.");
      return;
    }
    // 2. Si hay un formulario de campos personalizados, lo validamos también
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return; // Detiene la ejecución si los campos no son válidos
    }

    setState(() { _isLoading = true; _errorText = null; });

    try {
      final customData = _customDataControllers.map(
            (key, controller) => MapEntry(key, controller.text.trim()),
      );

      if (_paymentMethod == PaymentMethod.manual) {
        await _raffleService.purchaseTicket(
          raffle: widget.raffle,
          numbers: _selectedNumbers,
          paymentMethod: _paymentMethod,
          customData: customData,
          adminNotes: _isAdmin ? _adminNotesController.text.trim() : null,
          paymentPreferenceId: null, // No hay ID de pago en este caso
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boleto reservado. Pendiente de confirmación.')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // --- Flujo de Pago Online ---
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          print('DEBUG: currentUser es NULO justo antes de la llamada.');
          throw Exception("Usuario es nulo. No se puede continuar.");
        }

        print('--- INICIO DEBUG DE AUTH ---');
        print('currentUser.uid: ${currentUser.uid}');
        print('currentUser.email: ${currentUser.email}');
        print('currentUser.isAnonymous: ${currentUser.isAnonymous}');

        print('Forzando actualización de token...');
        try {
          final idTokenResult = await currentUser.getIdTokenResult(true);
          print('Token actualizado. Obtenido en: ${idTokenResult.authTime}');
          print('Token (primeros 10 chars): ${idTokenResult.token?.substring(0, 10)}...');
        } catch (e) {
          print('ERROR al refrescar el token: $e');
        }
        print('--- FIN DEBUG DE AUTH ---');

        final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('createPaymentPreference');
        final response = await callable.call<Map<String, dynamic>>({
          'raffleId': widget.raffle.id,
          'raffleTitle': widget.raffle.title,
          'quantity': _selectedNumbers.length,
          'unitPrice': widget.raffle.ticketPrice,
        });

        // 2. Extraemos los dos datos que nos devuelve la función
        final String? preferenceId = response.data['preferenceId'];
        final String? initPoint = response.data['initPoint'];

        if (preferenceId == null || initPoint == null) {
          throw Exception('La respuesta del servidor no fue válida.');
        }

        // 3. Creamos el boleto en nuestra DB como 'pendiente' pero con el ID de la preferencia
        await _raffleService.purchaseTicket(
          raffle: widget.raffle,
          numbers: _selectedNumbers,
          paymentMethod: _paymentMethod,
          customData: customData, // Asumiendo que ya tienes esta variable
          adminNotes: _isAdmin ? _adminNotesController.text.trim() : null,
          paymentPreferenceId: preferenceId,
        );

        // 4. Abrimos la URL de pago (¡tu código, que es perfecto!)
        final Uri url = Uri.parse(initPoint);
        if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
          throw Exception('No se pudo abrir la URL de pago: $url');
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _errorText = "Error al iniciar el pago: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- LÓGICA PARA RIFAS LIMITADAS ---
  void _assignRandomLimitedNumber(Set<int> soldNumbers) {
    final allPossibleNumbers =
    List.generate(widget.raffle.totalTickets!, (i) => i);

    final availableNumbers = allPossibleNumbers
        .where((num) => !soldNumbers.contains(num) && !_selectedNumbers.contains(num))
        .toList();

    if (availableNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡No quedan números disponibles para elegir al azar!')),
      );
      return;
    }

    final random = Random();
    final randomIndex = random.nextInt(availableNumbers.length);
    final randomNumber = availableNumbers[randomIndex];

    setState(() {
      _selectedNumbers.add(randomNumber);
    });
  }

  // --- LÓGICA PARA RIFAS ABIERTAS ---
  Future<void> _assignRandomOpenNumbers(int quantity) async {
    setState(() { _isLoading = true; _errorText = null; });
    final random = Random();
    List<int> newNumbers = [];
    int attempts = 0;
    int maxAttempts = quantity * 10;

    while (newNumbers.length < quantity && attempts < maxAttempts) {
      int randomNumber = 1000 + random.nextInt(99000);
      if (!_selectedNumbers.contains(randomNumber) && !newNumbers.contains(randomNumber)) {
        bool isTaken = await _raffleService.isNumberTaken(
            raffleId: widget.raffle.id, number: randomNumber);
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

  Future<void> _addManualOpenNumber(String numberStr) async {
    final number = int.tryParse(numberStr);
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, ingresa un número válido.")));
      return;
    }
    if (_selectedNumbers.contains(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya has añadido este número.")));
      return;
    }
    setState(() { _isLoading = true; _errorText = null; });
    bool isTaken = await _raffleService.isNumberTaken(
        raffleId: widget.raffle.id, number: number);
    if (isTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El número $number ya está ocupado.")));
    } else {
      setState(() {
        _selectedNumbers.add(number);
      });
    }
    setState(() => _isLoading = false);
  }

  void _showRandomOpenNumberDialog() {
    final controller = TextEditingController(text: '1');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Generar al Azar"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: '¿Cuántos números quieres?'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
          ),
          actions: [
            TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(ctx).pop()),
            ElevatedButton(
                child: const Text("Generar"),
                onPressed: () {
                  final qty = int.tryParse(controller.text) ?? 0;
                  if (qty > 0) {
                    _assignRandomOpenNumbers(qty);
                  }
                  Navigator.of(ctx).pop();
                }),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.raffle.title)),
      body: widget.raffle.status == RaffleStatus.finished
          ? _buildFinishedView()
          : _buildActiveView(),
    );
  }

  Widget _buildActiveView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRaffleInfo(),
                const Divider(height: 32),
                Text("¡Participa Ahora!", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (_isAdmin) _buildAdminNotesField(),
                widget.raffle.isLimited
                    ? _buildLimitedRaffleUI()
                    : _buildOpenRaffleUI(),
                const Divider(height: 32),
                _buildCustomFieldsForm(),
                _buildPaymentMethodSelector(),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBuyButton(),
        ),
      ],
    );
  }

  Widget _buildFinishedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: WinnersPodium(winners: widget.raffle.winners),
    );
  }

  // --- WIDGETS DE UI ---
  Widget _buildAdminNotesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "MODO ADMINISTRADOR",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _adminNotesController,
            decoration: const InputDecoration(
              labelText: 'Nota de Reserva (Ej: "Para Juan Pérez")',
              hintText: 'Esta nota solo es visible para ti',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildRaffleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Premios:", style: Theme.of(context).textTheme.headlineSmall),
        ...widget.raffle.prizes.map((p) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(p.position.toString())),
          title: Text(p.description),
        )),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
          title: Text(
              "Fecha del Sorteo: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.raffle.drawDate)} hs"),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.attach_money, color: AppColors.accentGreen),
          title: Text(
              "Precio por Boleto: \$${widget.raffle.ticketPrice.toStringAsFixed(2)}"),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.public, color: Colors.grey[700]),
          title: Text(
            "Rifa válida en: ${widget.raffle.country}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            "El premio solo podrá ser reclamado en este territorio.",
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitedRaffleUI() {
    return FutureBuilder<Set<int>>(
      future: _soldNumbersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar números vendidos."));
        }

        final soldNumbers = snapshot.data ?? {};
        final availableNumbers = List.generate(widget.raffle.totalTickets!, (i) => i)
            .where((num) => !soldNumbers.contains(num))
            .toList();
        final filteredNumbers = availableNumbers.where((num) {
          return num.toString().contains(_numberSearchQuery);
        }).toList();
        final visibleNumbers = filteredNumbers.take(_visibleNumberLimit).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _numberSearchController,
              decoration: InputDecoration(
                hintText: 'Buscar número disponible...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.casino),
                label: const Text("Dame un número al azar"),
                onPressed: () => _assignRandomLimitedNumber(soldNumbers),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tus números seleccionados:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _selectedNumbers.isEmpty
                ? const Text("Ninguno", style: TextStyle(color: Colors.grey))
                : Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedNumbers
                  .map((num) => Chip(
                label: Text(num.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                onDeleted: () =>
                    setState(() => _selectedNumbers.remove(num)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text("Números Disponibles:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: visibleNumbers.length,
              itemBuilder: (context, index) {
                final number = visibleNumbers[index];
                final isSelected = _selectedNumbers.contains(number);
                return InkWell(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedNumbers.remove(number);
                    } else {
                      _selectedNumbers.add(number);
                    }
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentGreen : Colors.transparent,
                      border: Border.all(color: isSelected ? AppColors.accentGreen : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(number.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
            if (visibleNumbers.length < filteredNumbers.length)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _visibleNumberLimit += 10),
                    child: const Text("Ver 10 más..."),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOpenRaffleUI() {
    final manualNumberController = TextEditingController();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: manualNumberController,
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
              style:
              IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () {
                if (manualNumberController.text.isNotEmpty) {
                  _addManualOpenNumber(manualNumberController.text);
                  manualNumberController.clear();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.casino_outlined),
            label: const Text("Generar Número(s) al Azar"),
            onPressed: () => _showRandomOpenNumberDialog(),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Tus números seleccionados:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _selectedNumbers.isEmpty
            ? const Center(
            child: Text("Aún no has añadido números.",
                style: TextStyle(color: Colors.grey)))
            : Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedNumbers
              .map((num) => Chip(
            label: Text(num.toString(),
                style:
                const TextStyle(fontWeight: FontWeight.bold)),
            onDeleted: () =>
                setState(() => _selectedNumbers.remove(num)),
            deleteIcon: const Icon(Icons.close, size: 16),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCustomFieldsForm() {
    if (widget.raffle.customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Información Adicional Requerida:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...widget.raffle.customFields.map((field) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _customDataControllers[field],
              decoration: InputDecoration(labelText: field, border: const OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Este campo es requerido' : null,
            ),
          )).toList(),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Método de Pago:", style: TextStyle(fontWeight: FontWeight.bold)),
        if (_remoteConfigService.onlinePaymentsEnabled)
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
      ],
    );
  }

  Widget _buildBuyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: (_selectedNumbers.isEmpty || _isLoading) ? null : _buyTickets,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
            _selectedNumbers.isEmpty
                ? "Selecciona un número para comprar"
                : "Comprar ${_selectedNumbers.length} Boleto(s) por \$${(widget.raffle.ticketPrice * _selectedNumbers.length).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
