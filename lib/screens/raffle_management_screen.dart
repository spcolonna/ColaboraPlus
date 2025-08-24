import 'package:flutter/material.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:intl/intl.dart';

import '../enums/payment_method.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';
import '../models/ticket_model.dart'; // Asegúrate de tener el paquete 'intl' en tu pubspec.yaml

class RaffleManagementScreen extends StatefulWidget {
  final RaffleModel raffle;
  const RaffleManagementScreen({super.key, required this.raffle});

  @override
  State<RaffleManagementScreen> createState() => _RaffleManagementScreenState();
}

class _RaffleManagementScreenState extends State<RaffleManagementScreen> {
  final RaffleService _raffleService = RaffleService();

  // --- ESTADOS PARA LA EDICIÓN ---
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late DateTime _editedDrawDate;
  late List<TextEditingController> _editedPrizeControllers;

  @override
  void initState() {
    super.initState();
    _initializeStateForEditing();
  }

  void _initializeStateForEditing() {
    // Inicializamos los controllers con los datos existentes de la rifa
    _titleController = TextEditingController(text: widget.raffle.title);
    _priceController =
        TextEditingController(text: widget.raffle.ticketPrice.toString());
    _editedDrawDate = widget.raffle.drawDate;
    _editedPrizeControllers = widget.raffle.prizes
        .map((prize) => TextEditingController(text: prize.description))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    for (var controller in _editedPrizeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- LÓGICA PARA GUARDAR Y CANCELAR ---
  Future<void> _saveChanges() async {
    try {
      final newPrizes = _editedPrizeControllers
          .asMap()
          .entries
          .map((entry) =>
          PrizeModel(position: entry.key + 1, description: entry.value.text))
          .toList();

      await _raffleService.updateRaffle(
        raffleId: widget.raffle.id,
        newTitle: _titleController.text.trim(),
        newTicketPrice: double.parse(_priceController.text.trim()),
        newDrawDate: _editedDrawDate,
        newPrizes: newPrizes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rifa actualizada con éxito.')));
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _cancelEdit() {
    // Si cancela, reseteamos todos los estados a los valores originales
    _initializeStateForEditing();
    setState(() => _isEditing = false);
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _editedDrawDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_editedDrawDate),
      );

      if (pickedTime != null) {
        setState(() {
          _editedDrawDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addPrizeField() {
    setState(() => _editedPrizeControllers.add(TextEditingController()));
  }

  void _removePrizeField(int index) {
    setState(() {
      _editedPrizeControllers[index].dispose();
      _editedPrizeControllers.removeAt(index);
    });
  }

  // --- BUILD METHOD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.raffle.title),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
              Tab(icon: Icon(Icons.people), text: 'Participantes'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.accentGreen,
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryAndEditTab(),
            _buildParticipantsTab(),
          ],
        ),
      ),
    );
  }

  // --- PESTAÑA DE RESUMEN Y EDICIÓN ---
  Widget _buildSummaryAndEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRaisedCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Información de la Rifa",
                  style: Theme.of(context).textTheme.headlineSmall),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          _isEditing ? _buildEditForm() : _buildInfoDisplay(),
        ],
      ),
    );
  }

  // WIDGET PARA MOSTRAR LA INFORMACIÓN (VISTA)
  Widget _buildInfoDisplay() {
    // Ordenamos los premios por posición para mostrarlos
    widget.raffle.prizes.sort((a, b) => a.position.compareTo(b.position));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
            title: const Text("Título"),
            subtitle: Text(widget.raffle.title,
                style: const TextStyle(fontSize: 16))),
        ListTile(
            title: const Text("Precio por Boleto"),
            subtitle: Text("\$${widget.raffle.ticketPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16))),
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.grey)),
          title: Text(
              'Fecha del Sorteo: ${DateFormat('dd/MM/yyyy HH:mm').format(_editedDrawDate)} hs'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectDateTime,
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text("Premios:", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
        ...widget.raffle.prizes.map((prize) => ListTile(
          leading: CircleAvatar(child: Text(prize.position.toString())),
          title: Text(prize.description),
        )),
      ],
    );
  }

  // WIDGET PARA MOSTRAR EL FORMULARIO (EDICIÓN)
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
              labelText: 'Título de la Rifa', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(
              labelText: 'Precio por Boleto', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.grey)),
          title: Text(
              'Fecha del Sorteo: ${DateFormat('dd/MM/yyyy').format(_editedDrawDate)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectDateTime,
        ),
        const Divider(height: 32),
        Text("Premios", style: Theme.of(context).textTheme.titleMedium),
        ..._editedPrizeControllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Descripción del ${index + 1}º Premio',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _removePrizeField(index),
                ),
              ),
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Añadir Premio'),
          onPressed: _addPrizeField,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: _cancelEdit, child: const Text('Cancelar')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ],
    );
  }

  // MÉTODO PARA LA TARJETA DE TOTAL RECAUDADO
  Widget _buildTotalRaisedCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _raffleService.getTicketsStream(widget.raffle.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return const Center(child: Text('Error al cargar datos'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: AppColors.primaryBlue,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    const Text("Total Recaudado",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        double totalRaised = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final ticket = TicketModel.fromFirestore(doc);
            if (ticket.isPaid) {
              totalRaised += ticket.amount;
            }
          }
        }

        return Card(
          color: AppColors.primaryBlue,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  const Text("Total Recaudado",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("\$${totalRaised.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // MÉTODO PARA LA PESTAÑA DE PARTICIPANTES
  Widget _buildParticipantsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _raffleService.getTicketsStream(widget.raffle.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar participantes."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aún no hay participantes."));
        }

        Map<String, List<TicketModel>> userTickets = {};
        for (var doc in snapshot.data!.docs) {
          final ticket = TicketModel.fromFirestore(doc);
          if (userTickets.containsKey(ticket.userId)) {
            userTickets[ticket.userId]!.add(ticket);
          } else {
            userTickets[ticket.userId] = [ticket];
          }
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: userTickets.entries.map((entry) {
            final userAllTickets = entry.value;
            final firstTicket = userAllTickets.first;

            final allNumbers =
            userAllTickets.expand((t) => t.ticketNumbers).toList();
            allNumbers.sort();

            final pendingManualTicket = userAllTickets.firstWhere(
                  (t) => t.paymentMethod == PaymentMethod.manual && !t.isPaid,
              orElse: () => TicketModel(
                  id: '',
                  raffleId: '',
                  userId: '',
                  userName: '',
                  ticketNumbers: [],
                  paymentMethod: PaymentMethod.online,
                  isPaid: true,
                  amount: 0),
            );
            final hasPendingPayment = pendingManualTicket.id.isNotEmpty;

            return Card(
              child: ExpansionTile(
                title: Text(firstTicket.userName),
                subtitle: Text("${allNumbers.length} número(s) comprados"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Números:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: allNumbers
                              .map((num) => Chip(label: Text(num.toString())))
                              .toList(),
                        ),
                        if (hasPendingPayment) ...[
                          const Divider(height: 24),
                          CheckboxListTile(
                            title: const Text("Confirmar Pago Manual"),
                            subtitle: Text(
                                "Monto: \$${pendingManualTicket.amount.toStringAsFixed(2)}"),
                            value: false,
                            onChanged: (bool? value) {
                              if (value == true) {
                                _raffleService.confirmManualPayment(
                                    widget.raffle.id, pendingManualTicket.id);
                              }
                            },
                          )
                        ]
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
