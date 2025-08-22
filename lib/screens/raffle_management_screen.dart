import 'package:flutter/material.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import '../enums/payment_method.dart';
import '../models/raffle_model.dart';
import '../models/ticket_model.dart';

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

  @override
  void initState() {
    super.initState();
    // Inicializamos los controllers con los datos existentes de la rifa
    _titleController = TextEditingController(text: widget.raffle.title);
    _priceController = TextEditingController(text: widget.raffle.ticketPrice.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

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

  // --- PESTAÑA DE RESUMEN Y EDICIÓN (REFACTORIZADA) ---
  Widget _buildSummaryAndEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La tarjeta de "Total Recaudado" que ahora funciona correctamente
          _buildTotalRaisedCard(),
          const SizedBox(height: 24),

          // Título de la sección de edición
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Información de la Rifa", style: Theme.of(context).textTheme.headlineSmall),
              if (!_isEditing) // Solo muestra el botón de editar si no se está editando
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // El contenido cambia si estamos editando o no
          _isEditing ? _buildEditForm() : _buildInfoDisplay(),
        ],
      ),
    );
  }

  // WIDGET PARA MOSTRAR LA INFORMACIÓN (VISTA)
  Widget _buildInfoDisplay() {
    return Column(
      children: [
        ListTile(title: const Text("Título"), subtitle: Text(widget.raffle.title, style: const TextStyle(fontSize: 16))),
        ListTile(title: const Text("Precio por Boleto"), subtitle: Text("\$${widget.raffle.ticketPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16))),
        // Aquí puedes añadir más campos de solo lectura (premios, fecha, etc.)
      ],
    );
  }

  // WIDGET PARA MOSTRAR EL FORMULARIO (EDICIÓN)
  Widget _buildEditForm() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Título de la Rifa', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: 'Precio por Boleto', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        // Aquí puedes añadir campos para editar los premios y la fecha
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancelar')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Llamar al método del servicio para guardar los cambios
                setState(() => _isEditing = false);
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ],
    );
  }

  // --- MÉTODO SIN CAMBIOS (YA CORREGIDO) ---
  Widget _buildTotalRaisedCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _raffleService.getTicketsStream(widget.raffle.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error); // Imprimir el error en consola ayuda a depurar
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
                    const Text("Total Recaudado", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                  const Text("Total Recaudado", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("\$${totalRaised.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MÉTODO SIN CAMBIOS ---
  Widget _buildParticipantsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _raffleService.getTicketsStream(widget.raffle.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Error al cargar participantes."));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Aún no hay participantes."));

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

            final allNumbers = userAllTickets.expand((t) => t.ticketNumbers).toList();
            allNumbers.sort();

            final pendingManualTicket = userAllTickets.firstWhere(
                  (t) => t.paymentMethod == PaymentMethod.manual && !t.isPaid,
              orElse: () => TicketModel(id: '', raffleId: '', userId: '', userName: '', ticketNumbers: [], paymentMethod: PaymentMethod.online, isPaid: true, amount: 0),
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
                        const Text("Números:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: allNumbers.map((num) => Chip(label: Text(num.toString()))).toList(),
                        ),
                        if (hasPendingPayment) ...[
                          const Divider(height: 24),
                          CheckboxListTile(
                            title: const Text("Confirmar Pago Manual"),
                            subtitle: Text("Monto: \$${pendingManualTicket.amount.toStringAsFixed(2)}"),
                            value: false,
                            onChanged: (bool? value) {
                              if (value == true) {
                                _raffleService.confirmManualPayment(widget.raffle.id, pendingManualTicket.id);
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
