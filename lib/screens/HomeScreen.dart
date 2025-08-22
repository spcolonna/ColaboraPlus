import 'package:flutter/material.dart';
import 'package:colabora_plus/models/UserModel.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:colabora_plus/widgets/placeholder_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. IMPORTAMOS LA NUEVA PESTAÑA DE PERFIL ---
import 'package:colabora_plus/screens/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (mounted) {
        if (docSnapshot.exists) {
          setState(() {
            _userProfile = UserModel.fromMap(docSnapshot.data()!, docSnapshot.id);
            _isLoadingProfile = false;
          });
        } else {
          setState(() => _isLoadingProfile = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // --- 2. ACTUALIZAMOS LA LISTA DE PÁGINAS ---
  List<Widget> _buildPages() {
    return [
      const PlaceholderTab(
        title: 'Rifas Activas',
        message: 'Aquí se mostrará una lista de todas las rifas disponibles, con un buscador en la parte superior.',
      ),
      const PlaceholderTab(
        title: 'Mis Participaciones',
        message: 'Aquí verás una lista de las rifas en las que has comprado números.',
      ),
      const PlaceholderTab(
        title: 'Historial de Rifas',
        message: 'Aquí verás una lista de todas las rifas pasadas y sus ganadores.',
      ),
      _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _userProfile != null
          ? ProfileTab(user: _userProfile!)
          : const PlaceholderTab(
        title: 'Mi Perfil',
        message: 'No se pudo cargar la información del perfil. Intenta de nuevo más tarde.',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildPages(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aquí se abrirá la pantalla para crear una rifa.')),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: AppColors.accentGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.primaryBlue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(icon: Icons.home, index: 0, label: 'Inicio'),
            _buildTabItem(icon: Icons.confirmation_number, index: 1, label: 'Participo'),
            const SizedBox(width: 48),
            _buildTabItem(icon: Icons.history, index: 2, label: 'Historial'),
            _buildTabItem(icon: Icons.person, index: 3, label: 'Perfil'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.accentGreen : AppColors.textWhite.withOpacity(0.8);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
