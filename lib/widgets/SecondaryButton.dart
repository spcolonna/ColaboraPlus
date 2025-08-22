import 'package:flutter/material.dart';
import 'package:colabora_plus/theme/AppColors.dart'; // <-- 1. Importa tus colores

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          // 2. Usa el color primario para el borde y el texto
          side: const BorderSide(color: AppColors.primaryBlue, width: 2), // <-- ANTES: Colors.deepPurple
          foregroundColor: AppColors.primaryBlue, // <-- Color para efectos (splash)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 3. ¡ERROR CORREGIDO! Ahora usa la variable 'text'
        child: Text(
          text, // <-- ANTES: 'Login'
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold, // Opcional: un poco más de énfasis
            color: AppColors.primaryBlue, // <-- ANTES: Colors.deepPurple
          ),
        ),
      ),
    );
  }
}
