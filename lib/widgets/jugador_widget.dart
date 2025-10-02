// FILE: lib/widgets/jugador_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ficha.dart';
import '../models/juego.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class JugadorWidget extends StatefulWidget {
  const JugadorWidget({super.key});

  @override
  State<JugadorWidget> createState() => _JugadorWidgetState();
}

class _JugadorWidgetState extends State<JugadorWidget> {
  DominoPiece? _selectedPiece;

  void _showPlayOptionsDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Dónde jugar la ficha?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Izquierda'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_selectedPiece != null) {
                  // Llamada corregida para usar el enum PlayEnd.left
                  gameProvider.playPiece(_selectedPiece!, PlayEnd.left);
                  setState(() => _selectedPiece = null);
                }
              },
            ),
            TextButton(
              child: const Text('Derecha'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_selectedPiece != null) {
                  // Llamada corregida para usar el enum PlayEnd.right
                  gameProvider.playPiece(_selectedPiece!, PlayEnd.right);
                  setState(() => _selectedPiece = null);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final gameState = gameProvider.gameState;

    // Manejo de estado inicial mientras se carga el juego.
    if (gameState.players.isEmpty || gameState.players.length <= gameState.currentPlayerIndex) {
      return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
    }

    final currentPlayer = gameState.players[gameState.currentPlayerIndex];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mano del Jugador ${currentPlayer.id + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: currentPlayer.hand.isEmpty
                ? const Center(child: Text('¡No tienes fichas!', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentPlayer.hand.length,
              itemBuilder: (context, index) {
                final ficha = currentPlayer.hand[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FichaWidget(
                    ficha: ficha,
                    width: 50,
                    isSelected: _selectedPiece == ficha,
                    onTap: () {
                      setState(() {
                        _selectedPiece = (_selectedPiece == ficha) ? null : ficha;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Jugar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                ),
                onPressed: _selectedPiece == null
                    ? null
                    : () => _showPlayOptionsDialog(context, gameProvider),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Robar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                ),
                onPressed: gameState.boneyard.isEmpty
                    ? null
                    : () {
                  gameProvider.drawPiece();
                  setState(() { _selectedPiece = null; });
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.gavel),
                label: const Text('Acusar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                ),
                onPressed: gameState.lastMove == null
                    ? null
                    : () {
                  gameProvider.accuse();
                  setState(() { _selectedPiece = null; });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

