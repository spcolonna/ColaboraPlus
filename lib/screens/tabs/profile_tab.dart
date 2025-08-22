import 'package:flutter/material.dart';
import 'package:colabora_plus/models/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import '../../models/raffle_model.dart';

class ProfileTab extends StatefulWidget {
  final UserModel user;

  const ProfileTab({super.key, required this.user});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isLoadingRaffles = true;
  List<RaffleModel> _myRaffles = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _loadMyRaffles();
  }

  Future<void> _loadMyRaffles() async {
    // Esta función no cambia, sigue cargando las rifas del usuario
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('raffles')
          .where('creatorId', isEqualTo: widget.user.uid)
          .get();
      if (mounted) {
        setState(() {
          _myRaffles = querySnapshot.docs.map((doc) => RaffleModel.fromFirestore(doc)).toList();
          _isLoadingRaffles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRaffles = false);
    }
  }

  Future<void> _saveProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'name': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado con éxito.')),
    );

    setState(() => _isEditing = false);
  }

  void _cancelEdit() {
    setState(() {
      _nameController.text = widget.user.name!;
      _phoneController.text = widget.user.phoneNumber!;
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN DEL FORMULARIO DE PERFIL ---
            _buildProfileFormCard(),
            const SizedBox(height: 24),

            // --- SEPARADOR Y LISTA DE RIFAS ---
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Mis Rifas Administradas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildRafflesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EMAIL: Se muestra en un TextField deshabilitado
            Text("Correo Electrónico", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: widget.user.email),
              enabled: false, // <-- CLAVE: No editable
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                filled: true,
                fillColor: Color(0xFFF5F5F5), // Color gris claro para indicar que no es editable
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // NOMBRE: Editable
            Text("Nombre Completo", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Ingresa tu nombre',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),

            // TELÉFONO: Editable
            Text("Teléfono", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Ingresa tu teléfono',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 24),

            // LÓGICA DE BOTONES: Muestra 'Editar' o 'Guardar'/'Cancelar'
            _isEditing
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _cancelEdit, child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
                  child: const Text('Guardar'),
                ),
              ],
            )
                : Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRafflesList() {
    if (_isLoadingRaffles) {
      return const Center(child: CircularProgressIndicator());
    }

    // ESTADO VACÍO: Muestra un mensaje amigable si no hay rifas.
    if (_myRaffles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Aquí aparecerán las rifas que crees',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Muestra la lista si hay rifas
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myRaffles.length,
      itemBuilder: (context, index) {
        final raffle = _myRaffles[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.confirmation_number_outlined),
            title: Text(raffle.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Sorteo: ${raffle.drawDate.day}/${raffle.drawDate.month}/${raffle.drawDate.year}'),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () { /* Navegar a la pantalla de gestión de esta rifa específica */ },
            ),
          ),
        );
      },
    );
  }
}
