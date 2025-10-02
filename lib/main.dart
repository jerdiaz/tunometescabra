// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/juego_screen.dart';
import 'providers/game_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: 'Dominó con Trampa',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blueGrey[900],
          scaffoldBackgroundColor: Colors.grey[850],
        ),
        home: const JuegoScreen(),
      ),
    );
  }
}
