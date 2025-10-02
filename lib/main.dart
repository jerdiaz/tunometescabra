// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
// ----- ESTA ES LA CORRECCIÓN CLAVE -----
// Importamos la pantalla del menú en lugar de la pantalla de juego.
import 'screens/menu_principal.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunometescabra',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[850],
      ),
      // ----- Y AQUÍ LA USAMOS COMO LA PANTALLA DE INICIO -----
      home: const MenuPrincipal(),
      debugShowCheckedModeBanner: false,
    );
  }
}

