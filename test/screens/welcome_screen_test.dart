// Importa las librerías necesarias para el test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colabora_plus/screens/WelcomeScreen.dart';

void main() {
  testWidgets('La pantalla de bienvenida muestra el título y los dos botones', (WidgetTester tester) async {
    // "Inflamos" o renderizamos nuestro widget WelcomeScreen en un entorno de prueba.
    // Lo envolvemos en MaterialApp para que tenga el contexto necesario (temas, etc.).
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    // Verifica que el texto 'Bienvenido' aparece exactamente una vez.
    final titleFinder = find.text('Bienvenido');
    expect(titleFinder, findsOneWidget);

    // Verifica que existe un botón con el texto 'Login'.
    // Usamos find.widgetWithText para ser más específicos.
    final loginButtonFinder = find.widgetWithText(OutlinedButton, 'Login');
    expect(loginButtonFinder, findsOneWidget);

    // Verifica que existe un botón con el texto 'Registro'.
    final signUpButtonFinder = find.widgetWithText(ElevatedButton, 'Registro');
    expect(signUpButtonFinder, findsOneWidget);
  });
}
