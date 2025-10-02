// FILE: lib/widgets/jugador_widget.dart
// Muestra la mano del jugador actual y los botones de acción.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ficha.dart';
import '../models/juego.dart'; // <-- ESTA ES LA LÍNEA CRUCIAL QUE RESUELVE EL ERROR
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class JugadorWidget extends StatefulWidget {
  const JugadorWidget({super.key});

  @override
  State<JugadorWidget> createState() => _JugadorWidgetState();
}

class _JugadorWidgetState extends State<JugadorWidget> {
  DominoPiece? _selectedPiece;

  /// Muestra un diálogo para que el jugador elija dónde jugar la ficha.
  void _showPlayOptionsDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Dónde jugar la ficha?'),
          content: const Text('Elige a qué lado del tablero quieres añadir la ficha.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Izquierda'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_selectedPiece != null) {
                  gameProvider.playPiece(_selectedPiece!, PlayEnd.left);
                  setState(() {
                    _selectedPiece = null;
                  });
                }
              },
            ),
            TextButton(
              child: const Text('Derecha'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_selectedPiece != null) {
                  gameProvider.playPiece(_selectedPiece!, PlayEnd.right);
                  setState(() {
                    _selectedPiece = null;
                  });
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
    final currentPlayer = gameState.players[gameState.currentPlayerIndex];
    final lastMove = gameState.lastMove;

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
                        if (_selectedPiece == ficha) {
                          _selectedPiece = null;
                        } else {
                          _selectedPiece = ficha;
                        }
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
                ),
                onPressed: lastMove == null
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
