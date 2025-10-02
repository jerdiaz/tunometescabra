// FILE: lib/screens/juego_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tablero_widget.dart';
import '../widgets/jugador_widget.dart';

// Convertido a StatelessWidget ya que no necesita manejar su propio estado.
class JuegoScreen extends StatelessWidget {
  const JuegoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;

        // Muestra diálogos de mensajes cuando sea necesario.
        if (gameProvider.message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text(gameProvider.message!.title),
                content: Text(gameProvider.message!.body),
                actions: [
                  TextButton(
                    onPressed: () {
                      final isGameOver = gameProvider.gameState.isGameOver;
                      Navigator.of(ctx).pop(); // Cierra el diálogo
                      gameProvider.clearMessage(); // Limpia el mensaje
                      if (isGameOver) {
                        // Si el juego ha terminado, vuelve al menú principal.
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            title: const Text('Tunometescabra'),
            centerTitle: true,
            // Agregamos un botón para volver al menú principal
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.grey[800],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        'Turno: Jugador ${gameState.currentPlayerIndex + 1}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    Text(
                        'Fichas para Robar: ${gameState.boneyard.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ],
                ),
              ),
              // Usamos const porque estos widgets ya no cambian.
              const Expanded(
                child: TableroWidget(),
              ),
              const JugadorWidget(),
            ],
          ),
        );
      },
    );
  }
}

