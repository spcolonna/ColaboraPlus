import 'package:colabora_plus/screens/tabs/active_raffles_tab.dart';
import 'package:colabora_plus/screens/tabs/history_tab.dart';
import 'package:colabora_plus/screens/tabs/my_participations_tab.dart';
import 'package:flutter/material.dart';
import 'package:colabora_plus/models/UserModel.dart';
import 'package:colabora_plus/theme/AppColors.dart';
import 'package:colabora_plus/widgets/placeholder_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. IMPORTAMOS LA NUEVA PESTAÑA DE PERFIL ---
import 'package:colabora_plus/screens/tabs/profile_tab.dart';

import '../services/notification_service.dart';
import 'create_raffle_screen.dart';

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
    _initNotifications();
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

  void _initNotifications() async {
    await NotificationService().initNotifications();
  }

  List<Widget> _buildPages() {
    return [
      const ActiveRafflesTab(),
      const MyParticipationsTab(),
      const HistoryTab(),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRaffleScreen()),
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
