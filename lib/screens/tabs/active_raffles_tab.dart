import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/services/raffle_service.dart';
import 'package:colabora_plus/widgets/raffle_card.dart';
import 'package:colabora_plus/theme/AppColors.dart';

import '../../models/raffle_model.dart';

class ActiveRafflesTab extends StatefulWidget {
  const ActiveRafflesTab({super.key});

  @override
  State<ActiveRafflesTab> createState() => _ActiveRafflesTabState();
}

class _ActiveRafflesTabState extends State<ActiveRafflesTab> {
  final RaffleService _raffleService = RaffleService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Añadimos un listener para que la UI se actualice al escribir
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rifas Activas'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BUSCADOR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar rifa por título...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // --- LISTA DE RIFAS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _raffleService.getAllActiveRafflesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar las rifas.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay rifas activas en este momento.'));
                }

                var allRaffles = snapshot.data!.docs
                    .map((doc) => RaffleModel.fromFirestore(doc))
                    .toList();

                // Aplicamos el filtro de búsqueda
                final filteredRaffles = _searchQuery.isEmpty
                    ? allRaffles
                    : allRaffles.where((raffle) =>
                    raffle.title.toLowerCase().contains(_searchQuery)).toList();

                if (filteredRaffles.isEmpty) {
                  return const Center(child: Text('No se encontraron rifas con ese nombre.'));
                }

                return ListView.builder(
                  itemCount: filteredRaffles.length,
                  itemBuilder: (context, index) {
                    return RaffleCard(raffle: filteredRaffles[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
