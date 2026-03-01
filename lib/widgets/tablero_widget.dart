// FILE: lib/widgets/tablero_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/juego.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class TableroWidget extends StatelessWidget {
  const TableroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final boardChain = gameProvider.gameState.boardChain;
    final pendingPiece = gameProvider.pendingPiece;
    final bool isPlacingMode = pendingPiece != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Patrón decorativo de fondo
            Positioned.fill(
              child: CustomPaint(painter: _FeltPatternPainter()),
            ),
            // Contenido del tablero
            boardChain.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tablero vacío',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Juega la primera ficha',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular tamaño dinámico basado en fichas y espacio
                      final availableWidth =
                          constraints.maxWidth - 16; // padding
                      // Cada ficha horizontal ocupa ~2*width + 4 gap
                      // Cada ficha doble (vertical) ocupa ~width + 4 gap
                      double totalNeeded = 0;
                      for (var f in boardChain) {
                        totalNeeded += f.isDouble ? 1.0 : 2.0;
                      }
                      totalNeeded += boardChain.length * 4; // gaps
                      double pieceWidth = (availableWidth /
                          (totalNeeded == 0 ? 1 : totalNeeded / 50));
                      pieceWidth = pieceWidth.clamp(24.0, 50.0);
                      // Recalculate: if all pieces still don't fit, shrink more
                      double estimatedTotal = 0;
                      for (var f in boardChain) {
                        estimatedTotal +=
                            f.isDouble ? pieceWidth + 4 : pieceWidth * 2 + 4;
                      }
                      if (estimatedTotal > availableWidth &&
                          boardChain.isNotEmpty) {
                        pieceWidth = (availableWidth / boardChain.length / 2.2)
                            .clamp(20.0, 50.0);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: boardChain.map((ficha) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0),
                                  child: FichaWidget(
                                    ficha: ficha,
                                    isHorizontal: !ficha.isDouble,
                                    width: pieceWidth,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            // ── Overlay de modo colocación ──
            if (isPlacingMode) ...[
              // Fondo semi-transparente
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),

              // Zona clickeable IZQUIERDA
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: _PlacementZone(
                  side: PlayEnd.left,
                  onTap: () => gameProvider.confirmPlay(PlayEnd.left),
                ),
              ),

              // Zona clickeable DERECHA
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: _PlacementZone(
                  side: PlayEnd.right,
                  onTap: () => gameProvider.confirmPlay(PlayEnd.right),
                ),
              ),

              // Overlay de ficha con botón invertir (centro-superior)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _PiecePreviewOverlay(
                    piece: pendingPiece,
                    onFlip: pendingPiece.isDouble
                        ? null
                        : () => gameProvider.flipPendingPiece(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Overlay semi-transparente que muestra la ficha a jugar con botón de invertir
class _PiecePreviewOverlay extends StatelessWidget {
  final dynamic piece;
  final VoidCallback? onFlip;

  const _PiecePreviewOverlay({required this.piece, this.onFlip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FichaWidget(
            ficha: piece,
            width: 42,
            isHorizontal: true,
          ),
          if (onFlip != null) ...[
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD93D).withValues(alpha: 0.5)),
              ),
              child: IconButton(
                icon: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFFFFD93D), size: 22),
                tooltip: 'Voltear ficha',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: const EdgeInsets.all(6),
                onPressed: onFlip,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Zona clickeable para colocar la ficha a la izquierda o derecha del tablero
class _PlacementZone extends StatefulWidget {
  final PlayEnd side;
  final VoidCallback onTap;

  const _PlacementZone({required this.side, required this.onTap});

  @override
  State<_PlacementZone> createState() => _PlacementZoneState();
}

class _PlacementZoneState extends State<_PlacementZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.side == PlayEnd.left;
    final color = isLeft ? const Color(0xFF4ECDC4) : const Color(0xFFFFD93D);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final alpha = _isHovered ? 0.45 : _pulseAnimation.value * 0.3;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    color.withValues(alpha: alpha),
                    color.withValues(alpha: 0.0),
                  ],
                ),
                border: Border(
                  left: isLeft
                      ? BorderSide(
                          color:
                              color.withValues(alpha: _isHovered ? 0.9 : 0.5),
                          width: 3)
                      : BorderSide.none,
                  right: !isLeft
                      ? BorderSide(
                          color:
                              color.withValues(alpha: _isHovered ? 0.9 : 0.5),
                          width: 3)
                      : BorderSide.none,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLeft
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      color: color.withValues(alpha: _isHovered ? 1.0 : 0.7),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLeft ? 'IZQ' : 'DER',
                      style: TextStyle(
                        color: color.withValues(alpha: _isHovered ? 1.0 : 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Patrón sutil tipo fieltro para el tablero
class _FeltPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
