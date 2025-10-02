import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class JuegoScreen extends StatelessWidget {
  const JuegoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para escuchar los cambios en GameProvider.
    // Cada vez que notifyListeners() es llamado, este widget se reconstruirá.
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // Obtenemos el estado actual del juego desde el provider.
        final gameState = gameProvider.gameState;
        final currentPlayer = gameState.players.isNotEmpty
            ? gameState.players[gameState.currentPlayerIndex]
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dominó con Trampa'),
            backgroundColor: Colors.grey[900],
          ),
          backgroundColor: Colors.grey[850],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Estado del Juego (Placeholder):',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (currentPlayer != null)
                  Text(
                    'Turno del Jugador: ${currentPlayer.id + 1}',
                    style: const TextStyle(fontSize: 20),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Fichas en el pozo: ${gameState.boneyard.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'Fichas en el tablero: ${gameState.boardChain.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Llama al método para reiniciar el juego en el provider.
                    gameProvider.restartGame();
                  },
                  child: const Text('Reiniciar Juego'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}