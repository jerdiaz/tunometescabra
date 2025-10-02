// FILE: lib/screens/menu_principal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'juego_screen.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: const Text('Tunometescabra'),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      // ----- CORRECCIÓN CLAVE AQUÍ -----
      // Usamos SingleChildScrollView para que el contenido sea desplazable si la pantalla es pequeña.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Widget para mostrar la imagen del logo
              Image.asset(
                'assets/images/logo.png',
                height: 200, // Ajusta el tamaño como prefieras
              ),
              const SizedBox(height: 50),
              const Text(
                'Selecciona el número de jugadores:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              _PlayerButton(playerCount: 2),
              const SizedBox(height: 20),
              _PlayerButton(playerCount: 3),
              const SizedBox(height: 20),
              _PlayerButton(playerCount: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para los botones de selección
class _PlayerButton extends StatelessWidget {
  final int playerCount;

  const _PlayerButton({required this.playerCount});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Provider.of<GameProvider>(context, listen: false).startGame(playerCount);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JuegoScreen()),
        );
      },
      child: Text('$playerCount Jugadores'),
    );
  }
}