import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:colabora_plus/widgets/CustomInputField.dart';
import 'package:colabora_plus/widgets/CustomPasswordField.dart';
import 'package:colabora_plus/widgets/PrimaryButton.dart';
import 'package:colabora_plus/widgets/SecondaryButton.dart';

import '../services/auth_service.dart';
import '../theme/AppColors.dart';
import 'HomeScreen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _performLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usamos el email y la contraseña de los controladores
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      //TODO: SACAR
      // final email = "seba@mail.com";
      // final password = "123456";


      // PASO 1: Intentamos hacer login directamente con Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No se encontró un usuario con ese correo electrónico.';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta. Por favor, inténtalo de nuevo.';
          break;
        case 'invalid-credential':
          errorMessage = 'Las credenciales son incorrectas.';
          break;
        default:
          errorMessage = 'Ocurrió un error inesperado. Por favor, inténtalo más tarde.';
      }
      _showErrorDialog('Error de Login', errorMessage);
    } catch (e) {
      _showErrorDialog('Error', 'Ocurrió un error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performRegistration() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Llamada única y limpia a nuestro servicio
      final userModel = await _authService.signUpWithEmailPassword(email, password);

      if (userModel != null) {
        // ¡Éxito! El usuario se creó en Auth Y su perfil en Firestore
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // El servicio devolvió null, lo que significa que hubo un error
        _showErrorDialog('Error de Registro', 'No se pudo completar el registro. El correo puede ya estar en uso o la contraseña es muy débil.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Ocurrió un error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray, // Fondo general gris claro
      body: Column(
        children: [
          // 1. Contenedor superior con el color oscuro
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35, // Ocupa el 35% de la pantalla
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(50), // <-- ESTO APLICA LA CURVA A AMBAS ESQUINAS INFERIORES
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo/Logo.jpeg', height: 90),
                const SizedBox(height: 16),
                Text(
                  'Colabora+',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite, // Texto blanco
                  ),
                ),
              ],
            ),
          ),
          // 2. Espacio para el formulario
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Crea y participa en rifas fácilmente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 32.0),
                    CustomInputField(
                      controller: _emailController,
                      labelText: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16.0),
                    CustomPasswordField(
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 32.0),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SecondaryButton(
                            text: 'Iniciar Sesión',
                            onPressed: _performLogin,
                          ),
                          const SizedBox(height: 16.0),
                          PrimaryButton(
                            text: 'Crear Cuenta',
                            onPressed: _performRegistration,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
