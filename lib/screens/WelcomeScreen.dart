import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Asegúrate de que esta importación esté

// Importamos los widgets y la nueva pantalla
import 'package:matchhouse_flutter/widgets/CustomInputField.dart';
import 'package:matchhouse_flutter/widgets/CustomPasswordField.dart';
import 'package:matchhouse_flutter/widgets/PrimaryButton.dart';
import 'package:matchhouse_flutter/widgets/SecondaryButton.dart';
import 'package:matchhouse_flutter/screens/HomeScreen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- FUNCIÓN DE LOGIN ACTUALIZADA ---
  Future<void> _performLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usamos el email y la contraseña de los controladores
      // final email = _emailController.text.trim();
      // final password = _passwordController.text.trim();
      //TODO: SACAR
      final email = "seba@mail.com";
      final password = "123456";


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

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Usuario registrado exitosamente: ${userCredential.user?.uid}');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('El email ya está en uso. Intentando hacer login...');
        await _performLogin();
      } else if (e.code == 'weak-password') {
        _showErrorDialog('Error de Registro', 'La contraseña es muy débil. Debe tener al menos 6 caracteres.');
      } else {
        _showErrorDialog('Error de Registro', e.message ?? 'Ocurrió un error.');
      }
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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/logo/NidoLogo.jpeg',
                  height: 120,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Nido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42.0,
                    fontWeight: FontWeight.bold,
                    // Para un estilo más elegante, considera usar el paquete google_fonts
                    // fontFamily: GoogleFonts.lato().fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Encuentra tu lugar ideal',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48.0),
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
                  const CircularProgressIndicator()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SecondaryButton(
                        text: 'Login',
                        onPressed: _performLogin,
                      ),
                      const SizedBox(height: 16.0),
                      PrimaryButton(
                        text: 'Registro',
                        onPressed: _performRegistration,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
