import 'package:flutter/material.dart';
import '../../enums/UserRole.dart';
import '../../models/UserModel.dart';
import '../../services/interfaces/IProfileService.dart';
import '../../services/KtorUserService.dart';


class PersonalInfoTab extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onProfileUpdated;

  const PersonalInfoTab({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<PersonalInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final IProfileService _userService = KtorUserService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _agencyNameController;
  late UserRole _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _agencyNameController = TextEditingController(text: widget.user.agencyName ?? '');
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _agencyNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() { _isSaving = true; });

      final userToUpdate = widget.user;
      userToUpdate.name = _nameController.text.trim();
      userToUpdate.phoneNumber = _phoneController.text.trim();
      userToUpdate.role = _selectedRole;
      userToUpdate.agencyName = _agencyNameController.text.trim().isNotEmpty
          ? _agencyNameController.text.trim()
          : null;

      print('[FLUTTER DEBUG] Se va a llamar al servicio para guardar el perfil.');
      try {
        await _userService.createUserProfile(userToUpdate);
        await widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil guardado con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el perfil: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            const Text('Tipo de Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              onChanged: (UserRole? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
              items: UserRole.values.map((UserRole role) {
                return DropdownMenuItem<UserRole>(
                  value: role,
                  child: Text(role == UserRole.agency ? 'Inmobiliaria' : 'Persona'),
                );
              }).toList(),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            if (_selectedRole == UserRole.agency)
              TextFormField(
                controller: _agencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Inmobiliaria *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (value) => (_selectedRole == UserRole.agency && (value == null || value.isEmpty)) ? 'Este campo es obligatorio para inmobiliarias' : null,
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        label: _isSaving ? const Text('Guardando...') : const Text('Guardar Cambios'),
        icon: _isSaving
            ? Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2.0),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : const Icon(Icons.save),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
