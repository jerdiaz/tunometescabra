// FILE: lib/widgets/jugador_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ficha.dart';
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

  bool _playerHasValidMoves(Player player, List<DominoPiece> boardChain) {
    if (boardChain.isEmpty) return player.hand.isNotEmpty;
    final leftValue = boardChain.first.a;
    final rightValue = boardChain.last.b;
    for (var piece in player.hand) {
      if (piece.a == leftValue ||
          piece.b == leftValue ||
          piece.a == rightValue ||
          piece.b == rightValue) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final gameState = gameProvider.gameState;
    final bool isPlacingMode = gameProvider.pendingPiece != null;
    final bool isMyTurn = gameProvider.isMyTurn;
    final int localIdx = gameProvider.localPlayerIndex;

    if (gameState.players.isEmpty || gameState.players.length <= localIdx) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    // Siempre mostrar la mano del jugador local
    final localPlayer = gameState.players[localIdx];
    final canDraw = gameState.boneyard.isNotEmpty && isMyTurn;
    final bool canPlay =
        _playerHasValidMoves(localPlayer, gameState.boardChain);
    final bool showPassButton = !canPlay && !canDraw && isMyTurn;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:
              BorderSide(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
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
          // Fichas del jugador local
          SizedBox(
            height: 105,
            child: localPlayer.hand.isEmpty
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
                    itemCount: localPlayer.hand.length,
                    itemBuilder: (context, index) {
                      final ficha = localPlayer.hand[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: FichaWidget(
                          ficha: ficha,
                          width: 46,
                          isSelected: _selectedPiece == ficha,
                          onTap: (isPlacingMode || !isMyTurn)
                              ? null
                              : () {
                                  setState(() {
                                    _selectedPiece = (_selectedPiece == ficha)
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
          if (isPlacingMode)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close_rounded,
                    label: 'Cancelar',
                    gradient: const [
                      Color(0xFFFF6B6B),
                      Color(0xFFEE5A24),
                    ],
                    enabled: true,
                    onTap: () {
                      gameProvider.clearPendingPiece();
                      setState(() => _selectedPiece = null);
                    },
                  ),
                ),
              ],
            )
          else
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isMyTurn ? 1.0 : 0.4,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Jugar',
                      gradient: const [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                      enabled: _selectedPiece != null && isMyTurn,
                      onTap: () {
                        gameProvider.setPendingPiece(_selectedPiece!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Comer',
                      gradient: const [Color(0xFF2ED573), Color(0xFF26A65B)],
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
                      gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                      enabled: gameState.lastMove != null && isMyTurn,
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
                        gradient: const [Color(0xFFFF9F43), Color(0xFFE17D32)],
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
          gradient: enabled ? LinearGradient(colors: gradient) : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.08),
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
