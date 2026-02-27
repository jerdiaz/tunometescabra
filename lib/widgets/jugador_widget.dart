// FILE: lib/widgets/jugador_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ficha.dart';
import '../models/juego.dart';
import '../models/jugador.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class JugadorWidget extends StatefulWidget {
  const JugadorWidget({super.key});

  @override
  State<JugadorWidget> createState() => _JugadorWidgetState();
}

class _JugadorWidgetState extends State<JugadorWidget> {
  DominoPiece? _selectedPiece;

  /// Diálogo para elegir orientación de la ficha y lado del tablero.
  void _showPlayOptionsDialog(BuildContext context, GameProvider gameProvider) {
    // Estado local para la orientación de la ficha dentro del diálogo.
    DominoPiece currentPiece = _selectedPiece!;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isDouble = currentPiece.isDouble;
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
              ),
              title: const Text(
                '¿Cómo jugar la ficha?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previsualización de la ficha con orientación actual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FichaWidget(
                        ficha: currentPiece,
                        width: 50,
                        isHorizontal: true,
                      ),
                      if (!isDouble) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFFD93D).withValues(alpha: 0.5)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded,
                                color: Color(0xFFFFD93D), size: 26),
                            tooltip: 'Voltear ficha',
                            onPressed: () {
                              setDialogState(() {
                                currentPiece = currentPiece.flipped;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isDouble) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Conecta: [${currentPiece.b}] ← izq  |  der → [${currentPiece.a}]',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Botones de dirección
                  Row(
                    children: [
                      Expanded(
                        child: _DirectionButton(
                          label: '← Izquierda',
                          color: const Color(0xFF4ECDC4),
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            gameProvider.playPiece(
                                currentPiece, PlayEnd.left);
                            setState(() => _selectedPiece = null);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DirectionButton(
                          label: 'Derecha →',
                          color: const Color(0xFFFFD93D),
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            gameProvider.playPiece(
                                currentPiece, PlayEnd.right);
                            setState(() => _selectedPiece = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _playerHasValidMoves(Player player, List<DominoPiece> boardChain) {
    if (boardChain.isEmpty) return player.hand.isNotEmpty;
    final leftValue = boardChain.first.a;
    final rightValue = boardChain.last.b;
    for (var piece in player.hand) {
      if (piece.a == leftValue || piece.b == leftValue ||
          piece.a == rightValue || piece.b == rightValue) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final gameState = gameProvider.gameState;

    if (gameState.players.isEmpty ||
        gameState.players.length <= gameState.currentPlayerIndex) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }

    final currentPlayer =
        gameState.players[gameState.currentPlayerIndex];
    final canDraw = gameState.boneyard.isNotEmpty;
    final bool canPlay =
        _playerHasValidMoves(currentPlayer, gameState.boardChain);
    final bool showPassButton = !canPlay && !canDraw;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
              color:
                  const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Fichas del jugador
          SizedBox(
            height: 105,
            child: currentPlayer.hand.isEmpty
                ? Center(
                    child: Text(
                      '¡No tienes fichas!',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentPlayer.hand.length,
                    itemBuilder: (context, index) {
                      final ficha = currentPlayer.hand[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3.0),
                        child: FichaWidget(
                          ficha: ficha,
                          width: 46,
                          isSelected: _selectedPiece == ficha,
                          onTap: () {
                            setState(() {
                              _selectedPiece =
                                  (_selectedPiece == ficha)
                                      ? null
                                      : ficha;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Jugar',
                  gradient: const [
                    Color(0xFF4ECDC4),
                    Color(0xFF44B3AA)
                  ],
                  enabled: _selectedPiece != null,
                  onTap: () => _showPlayOptionsDialog(
                      context, gameProvider),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Comer',
                  gradient: const [
                    Color(0xFF2ED573),
                    Color(0xFF26A65B)
                  ],
                  enabled: canDraw,
                  onTap: () {
                    gameProvider.drawPiece();
                    setState(() => _selectedPiece = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.gavel_rounded,
                  label: 'Acusar',
                  gradient: const [
                    Color(0xFFFF6B6B),
                    Color(0xFFEE5A24)
                  ],
                  enabled: gameState.lastMove != null,
                  onTap: () {
                    gameProvider.accuse();
                    setState(() => _selectedPiece = null);
                  },
                ),
              ),
              if (showPassButton) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Pasar',
                    gradient: const [
                      Color(0xFFFF9F43),
                      Color(0xFFE17D32)
                    ],
                    enabled: true,
                    onTap: () {
                      gameProvider.passTurn();
                      setState(() => _selectedPiece = null);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.35,
      child: Container(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: gradient)
              : null,
          color: enabled
              ? null
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DirectionButton(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}