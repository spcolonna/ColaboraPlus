import 'package:flutter/material.dart';
import 'package:matchhouse_flutter/models/SearchFilterModel.dart';
import 'package:matchhouse_flutter/models/UserModel.dart';
import 'package:matchhouse_flutter/screens/tabs/PersonalInfoTab.dart';
import 'package:matchhouse_flutter/screens/tabs/SearchFiltersTab.dart';
import 'package:matchhouse_flutter/screens/tabs/MyHousesTab.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;
  final SearchFilterModel filters;
  final Future<void> Function() onProfileUpdated;
  final Future<void> Function(SearchFilterModel newFilters) onFiltersSaved;

  const ProfilePage({
    super.key,
    required this.user,
    required this.filters,
    required this.onProfileUpdated,
    required this.onFiltersSaved
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Personal'),
            Tab(icon: Icon(Icons.filter_alt_outlined), text: 'Filtros'),
            Tab(icon: Icon(Icons.other_houses_outlined), text: 'Mis Casas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PersonalInfoTab(user: widget.user, onProfileUpdated: widget.onProfileUpdated),
          SearchFiltersTab(filters: widget.filters, onSave: widget.onFiltersSaved,),
          MyHousesTab(),
        ],
      ),
    );
  }
}
