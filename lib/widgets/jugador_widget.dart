// FILE: lib/widgets/jugador_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ficha.dart';
import '../models/juego.dart';
import '../models/jugador.dart'; // <-- ESTA ES LA LÍNEA QUE FALTABA
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

  /// Revisa si el jugador actual tiene alguna jugada válida en su mano.
  bool _playerHasValidMoves(Player player, List<DominoPiece> boardChain) {
    if (boardChain.isEmpty) {
      return player.hand.isNotEmpty;
    }

    final leftValue = boardChain.first.a;
    final rightValue = boardChain.last.b;

    for (var piece in player.hand) {
      if (piece.a == leftValue || piece.b == leftValue || piece.a == rightValue || piece.b == rightValue) {
        return true;
      }
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final gameState = gameProvider.gameState;

    if (gameState.players.isEmpty || gameState.players.length <= gameState.currentPlayerIndex) {
      return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
    }

    final currentPlayer = gameState.players[gameState.currentPlayerIndex];
    final canDraw = gameState.boneyard.isNotEmpty;
    final bool canPlay = _playerHasValidMoves(currentPlayer, gameState.boardChain);
    final bool showPassButton = !canPlay && !canDraw;

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
                onPressed: !canDraw
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
              if (showPassButton)
                ElevatedButton.icon(
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Pasar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    gameProvider.passTurn();
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