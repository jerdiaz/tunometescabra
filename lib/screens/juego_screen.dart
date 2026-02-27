// FILE: lib/screens/juego_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tablero_widget.dart';
import '../widgets/jugador_widget.dart';

class JuegoScreen extends StatelessWidget {
  const JuegoScreen({super.key});

  Color _timerColor(int seconds) {
    if (seconds > 20) return const Color(0xFF2ED573);
    if (seconds > 10) return const Color(0xFFFFD93D);
    if (seconds > 5) return const Color(0xFFFF9F43);
    return const Color(0xFFFF4757);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;
        final seconds = gameProvider.remainingSeconds;
        final timerColor = _timerColor(seconds);

        // Mostrar diálogos de mensajes
        if (gameProvider.message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black87,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
                ),
                title: Text(
                  gameProvider.message!.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  gameProvider.message!.body,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () {
                        final isGameOver = gameProvider.gameState.isGameOver;
                        Navigator.of(ctx).pop();
                        gameProvider.clearMessage();
                        if (isGameOver) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Text(
                          'Entendido',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Botón atrás
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Jugador actual
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4ECDC4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'JUGADOR ${gameState.currentPlayerIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF4ECDC4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Timer
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: timerColor.withValues(alpha: 0.12),
                            border: Border.all(color: timerColor.withValues(alpha: 0.6), width: 2),
                            boxShadow: seconds <= 5
                                ? [BoxShadow(color: timerColor.withValues(alpha: 0.4), blurRadius: 16)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              '$seconds',
                              style: TextStyle(
                                fontSize: seconds <= 5 ? 22 : 20,
                                fontWeight: FontWeight.w900,
                                color: timerColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pozo info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'Pozo: ${gameState.boneyard.length} fichas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Tablero ──
                  const Expanded(child: TableroWidget()),
                  // ── Panel del Jugador ──
                  const JugadorWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
