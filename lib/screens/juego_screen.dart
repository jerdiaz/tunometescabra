// FILE: lib/screens/juego_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tablero_widget.dart';
import '../widgets/jugador_widget.dart';
import 'menu_principal.dart';

class JuegoScreen extends StatefulWidget {
  final String roomCode;
  final int localPlayerIndex;

  const JuegoScreen({
    super.key,
    required this.roomCode,
    required this.localPlayerIndex,
  });

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  bool _hasShownAbandonDialog = false;
  bool _hasShownMessageDialog = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;
        final seconds = gameProvider.remainingSeconds;
        final timerColor = _timerColor(seconds);
        final isMyTurn = gameProvider.isMyTurn;

        // Detectar abandono del oponente
        if (gameProvider.opponentLeft && !_hasShownAbandonDialog) {
          _hasShownAbandonDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAbandonDialog(context);
          });
        }

        // Mostrar diálogos de mensajes
        if (gameProvider.message != null && !_hasShownMessageDialog) {
          _hasShownMessageDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            final isGameOver = gameProvider.gameState.isGameOver;
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black87,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
                ),
                title: Text(
                  gameProvider.message!.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
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
                        Navigator.of(ctx).pop();
                        gameProvider.clearMessage();
                        _hasShownMessageDialog = false;
                        if (isGameOver) {
                          _returnToLobby(context, gameProvider);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Text(
                          isGameOver ? 'Volver a la Sala' : 'Entendido',
                          style: const TextStyle(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Botón salir
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon:
                                const Icon(Icons.arrow_back_ios_new, size: 18),
                            onPressed: () =>
                                _confirmExit(context, gameProvider),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Jugador/turno actual
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMyTurn
                                  ? const Color(0xFF4ECDC4)
                                      .withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isMyTurn
                                      ? const Color(0xFF4ECDC4)
                                          .withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMyTurn
                                        ? const Color(0xFF4ECDC4)
                                        : const Color(0xFFFF9F43),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isMyTurn
                                        ? 'TU TURNO'
                                        : 'Turno de ${gameProvider.currentTurnPlayerName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: isMyTurn
                                          ? const Color(0xFF4ECDC4)
                                          : const Color(0xFFFF9F43),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Timer
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isMyTurn ? timerColor : Colors.grey)
                                .withValues(alpha: 0.12),
                            border: Border.all(
                                color: (isMyTurn ? timerColor : Colors.grey)
                                    .withValues(alpha: 0.6),
                                width: 2),
                            boxShadow: isMyTurn && seconds <= 5
                                ? [
                                    BoxShadow(
                                        color:
                                            timerColor.withValues(alpha: 0.4),
                                        blurRadius: 16)
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              isMyTurn ? '$seconds' : '—',
                              style: TextStyle(
                                fontSize: isMyTurn && seconds <= 5 ? 22 : 20,
                                fontWeight: FontWeight.w900,
                                color: isMyTurn ? timerColor : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Room code & Pozo
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text(
                          'Sala: ${widget.roomCode}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.layers,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text(
                          'Pozo: ${gameState.boneyard.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Tablero ──
                  Expanded(
                    child: Stack(
                      children: [
                        const TableroWidget(),
                        // Overlay "turno del oponente"
                        if (!isMyTurn && !gameState.isGameOver)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E)
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFF9F43)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFF9F43),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Turno de ${gameProvider.currentTurnPlayerName}...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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

  Color _timerColor(int seconds) {
    if (seconds > 20) return const Color(0xFF2ED573);
    if (seconds > 10) return const Color(0xFFFFD93D);
    if (seconds > 5) return const Color(0xFFFF9F43);
    return const Color(0xFFFF4757);
  }

  void _showAbandonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
        ),
        title: const Text(
          '👋 Jugador abandonó',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Un jugador ha abandonado la partida.',
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
                Navigator.of(ctx).pop();
                _exitToMenu(
                    context, Provider.of<GameProvider>(context, listen: false));
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Volver al Menú',
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
  }

  void _confirmExit(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
        ),
        title: const Text(
          '¿Abandonar partida?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Si sales, la partida se marcará como abandonada.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF4ECDC4))),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _exitToMenu(context, provider);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Salir',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exitToMenu(BuildContext context, GameProvider provider) {
    provider.leaveRoom();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuPrincipal()),
      (route) => false,
    );
  }

  void _returnToLobby(BuildContext context, GameProvider provider) {
    provider.returnToLobby();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const _LobbyFromGame(),
        ),
      ),
      (route) => false,
    );
  }
}

/// Widget que muestra el lobby después de una partida.
/// Reutiliza el provider existente con la misma sala.
class _LobbyFromGame extends StatelessWidget {
  const _LobbyFromGame();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        // Si la partida vuelve a empezar, navegar al juego
        if (provider.isGameStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: JuegoScreen(
                    roomCode: provider.roomCode,
                    localPlayerIndex: provider.localPlayerIndex,
                  ),
                ),
              ),
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D1A),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E)
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildLobbyCard(context, provider),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLobbyCard(BuildContext context, GameProvider provider) {
    final names = provider.playerNames;
    final isHost = provider.isHost;
    final code = provider.roomCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏆 Partida Terminada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD93D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sala',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            code,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Color(0xFF4ECDC4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'JUGADORES (${names.length}/4)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(names.length, (i) {
            final isMe = i == provider.localPlayerIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.person,
                      size: 18,
                      color: isMe ? const Color(0xFF4ECDC4) : Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      names[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.white.withValues(alpha: isMe ? 1.0 : 0.7),
                      ),
                    ),
                  ),
                  if (isMe)
                    const Text('TÚ',
                        style: TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          if (isHost)
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => provider.startGame(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            '¡Jugar de Nuevo!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF4ECDC4)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esperando a que el host inicie otra partida...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              provider.leaveRoom();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPrincipal()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.exit_to_app,
                color: Color(0xFFFF6B6B), size: 16),
            label: const Text(
              'Salir al Menú',
              style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
