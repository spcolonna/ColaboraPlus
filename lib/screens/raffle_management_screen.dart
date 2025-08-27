import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:colabora_plus/widgets/winners_podium.dart';
import 'package:intl/intl.dart';

import '../enums/payment_method.dart';
import '../enums/raffle_status.dart';
import '../models/prize_model.dart';
import '../models/raffle_model.dart';
import '../models/ticket_model.dart';
import '../services/raffle_service.dart';
import '../theme/AppColors.dart';

class RaffleManagementScreen extends StatefulWidget {
  final RaffleModel raffle;
  const RaffleManagementScreen({super.key, required this.raffle});

  @override
  State<RaffleManagementScreen> createState() => _RaffleManagementScreenState();
}

class _RaffleManagementScreenState extends State<RaffleManagementScreen> {
  final RaffleService _raffleService = RaffleService();

  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late DateTime _editedDrawDate;
  late List<TextEditingController> _editedPrizeControllers;
  late bool _isLimited;
  late TextEditingController _totalTicketsController;
  late List<TextEditingController> _customFieldControllers;

  @override
  void initState() {
    super.initState();
    _initializeStateForEditing();
  }

  void _initializeStateForEditing() {
    _titleController = TextEditingController(text: widget.raffle.title);
    _priceController = TextEditingController(text: widget.raffle.ticketPrice.toString());
    _editedDrawDate = widget.raffle.drawDate;
    _editedPrizeControllers = widget.raffle.prizes
        .map((prize) => TextEditingController(text: prize.description))
        .toList();
    _isLimited = widget.raffle.isLimited;
    _totalTicketsController = TextEditingController(text: widget.raffle.totalTickets?.toString() ?? '');
    _customFieldControllers = widget.raffle.customFields
        .map((field) => TextEditingController(text: field))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _totalTicketsController.dispose();
    for (var controller in _editedPrizeControllers) {
      controller.dispose();
    }
    for (var controller in _customFieldControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- LÓGICA DE GUARDADO (COMPLETA) ---
  Future<void> _saveChanges() async {
    try {
      final newPrizes = _editedPrizeControllers
          .asMap().entries
          .map((entry) => PrizeModel(position: entry.key + 1, description: entry.value.text))
          .toList();

      final newCustomFields = _customFieldControllers
          .map((controller) => controller.text.trim())
          .where((field) => field.isNotEmpty)
          .toList();

      await _raffleService.updateRaffle(
        raffleId: widget.raffle.id,
        newTitle: _titleController.text.trim(),
        newTicketPrice: double.parse(_priceController.text.trim()),
        newDrawDate: _editedDrawDate,
        newPrizes: newPrizes,
        isLimited: _isLimited,
        totalTickets: _isLimited ? int.tryParse(_totalTicketsController.text.trim()) : null,
        customFields: newCustomFields,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rifa actualizada con éxito.')));

      // Salimos del modo edición. La UI se actualizará automáticamente
      // si la pantalla de perfil está escuchando cambios en tiempo real.
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _cancelEdit() {
    _initializeStateForEditing();
    setState(() => _isEditing = false);
  }

  // --- MÉTODOS DE UI HELPER ---
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context, initialDate: _editedDrawDate,
      firstDate: DateTime.now(), lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_editedDrawDate),
      );
      if (pickedTime != null) {
        setState(() {
          _editedDrawDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  void _addPrizeField() => setState(() => _editedPrizeControllers.add(TextEditingController()));
  void _removePrizeField(int index) {
    setState(() {
      _editedPrizeControllers[index].dispose();
      _editedPrizeControllers.removeAt(index);
    });
  }
  void _addCustomField() => setState(() => _customFieldControllers.add(TextEditingController()));
  void _removeCustomField(int index) {
    setState(() {
      _customFieldControllers[index].dispose();
      _customFieldControllers.removeAt(index);
    });
  }

  // --- BUILD METHOD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raffle.title),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: widget.raffle.status == RaffleStatus.finished
          ? _buildFinishedRaffleView()
          : _buildActiveRaffleView(),
    );
  }

  // --- WIDGETS DE VISTAS ---
  Widget _buildFinishedRaffleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildTotalRaisedCard(),
          const SizedBox(height: 16),
          WinnersPodium(winners: widget.raffle.winners),
        ],
      ),
    );
  }

  Widget _buildActiveRaffleView() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
              Tab(icon: Icon(Icons.people), text: 'Participantes'),
            ],
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

  // --- WIDGETS DE PESTAÑAS Y FORMULARIOS ---
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
              Text("Información de la Rifa", style: Theme.of(context).textTheme.headlineSmall),
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

  Widget _buildInfoDisplay() {
    widget.raffle.prizes.sort((a, b) => a.position.compareTo(b.position));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(title: const Text("Título"), subtitle: Text(widget.raffle.title, style: const TextStyle(fontSize: 16))),
        ListTile(title: const Text("Precio por Boleto"), subtitle: Text("\$${widget.raffle.ticketPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16))),
        ListTile(title: const Text("Fecha del Sorteo"), subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(widget.raffle.drawDate), style: const TextStyle(fontSize: 16))),
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

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título de la Rifa', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Precio por Boleto', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Rifa con boletos limitados'),
          value: _isLimited,
          onChanged: (value) => setState(() => _isLimited = value),
        ),
        if (_isLimited)
          TextFormField(
            controller: _totalTicketsController,
            decoration: const InputDecoration(labelText: 'Cantidad total de boletos', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: Colors.grey)),
          title: Text('Fecha del Sorteo: ${DateFormat('dd/MM/yyyy HH:mm').format(_editedDrawDate)} hs'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectDateTime,
        ),
        const Divider(height: 32),
        Text("Premios", style: Theme.of(context).textTheme.titleMedium),
        ..._editedPrizeControllers.asMap().entries.map((entry) {
          int index = entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: 'Descripción del ${index + 1}º Premio', border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removePrizeField(index)),
              ),
            ),
          );
        }),
        TextButton.icon(icon: const Icon(Icons.add), label: const Text('Añadir Premio'), onPressed: _addPrizeField),
        const Divider(height: 32),
        Text("Campos Adicionales a Solicitar", style: Theme.of(context).textTheme.titleMedium),
        ..._customFieldControllers.asMap().entries.map((entry) {
          int index = entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: 'Nombre del campo ${index + 1}', border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeCustomField(index)),
              ),
            ),
          );
        }),
        TextButton.icon(icon: const Icon(Icons.add), label: const Text('Añadir Campo'), onPressed: _addCustomField),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _cancelEdit, child: const Text('Cancelar')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _saveChanges, child: const Text('Guardar Cambios')),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRaisedCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _raffleService.getTicketsStream(widget.raffle.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error al cargar datos'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(color: AppColors.primaryBlue, child: Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: Colors.white))));
        }
        double totalRaised = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final ticket = TicketModel.fromFirestore(doc);
            if (ticket.isPaid) totalRaised += ticket.amount;
          }
        }
        return Card(
          color: AppColors.primaryBlue,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(child: Column(children: [
              const Text("Total Recaudado", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text("\$${totalRaised.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ])),
          ),
        );
      },
    );
  }

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

            final allNumbers = userAllTickets.expand((t) => t.ticketNumbers).toList()..sort();

            final pendingManualTickets = userAllTickets
                .where((t) => t.paymentMethod == PaymentMethod.manual && !t.isPaid)
                .toList();

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
                        const Text("Números:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0, runSpacing: 4.0,
                          children: allNumbers.map((num) => Chip(label: Text(num.toString()))).toList(),
                        ),

                        // --- LÓGICA MEJORADA PARA PAGOS PENDIENTES ---
                        if (pendingManualTickets.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text("Pagos Manuales Pendientes:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...pendingManualTickets.map((ticket) {
                            return ListTile(
                              title: Text("Compra de ${ticket.ticketNumbers.length} boleto(s)"),
                              subtitle: Text("Monto: \$${ticket.amount.toStringAsFixed(2)}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón para Liberar/Eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Liberar números',
                                    onPressed: () {
                                      // Mostramos un diálogo de confirmación
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('¿Liberar Números?'),
                                          content: Text('¿Estás seguro de que quieres eliminar esta compra pendiente? Los números ${ticket.ticketNumbers.join(', ')} volverán a estar disponibles.'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancelar'),
                                              onPressed: () => Navigator.of(ctx).pop(),
                                            ),
                                            TextButton(
                                              child: const Text('Sí, Liberar', style: TextStyle(color: Colors.red)),
                                              onPressed: () {
                                                _raffleService.deleteTicket(widget.raffle.id, ticket.id);
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  // Botón para Confirmar
                                  ElevatedButton(
                                    child: const Text('Confirmar'),
                                    onPressed: () {
                                      _raffleService.confirmManualPayment(widget.raffle.id, ticket.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
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
