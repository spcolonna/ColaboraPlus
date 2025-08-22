import 'package:flutter/material.dart';
import 'package:colabora_plus/theme/AppColors.dart'; // <-- 1. Importa tus colores

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          // 2. Usa los colores de tu marca
          backgroundColor: AppColors.accentGreen, // <-- ANTES: Colors.deepPurple
          foregroundColor: AppColors.textWhite,      // <-- ANTES: Colors.white
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold, // Opcional: un poco más de énfasis
          ),
        ),
      ),
    );
  }
}
