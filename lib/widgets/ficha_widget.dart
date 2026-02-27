// FILE: lib/widgets/ficha_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ficha.dart';

class FichaWidget extends StatelessWidget {
  final DominoPiece ficha;
  final double width;
  final bool isSelected;
  final bool isHorizontal;
  final VoidCallback? onTap;

  const FichaWidget({
    super.key,
    required this.ficha,
    this.width = 60,
    this.isSelected = false,
    this.isHorizontal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double height = isHorizontal ? width : width * 2;
    final double actualWidth = isHorizontal ? width * 2 : width;
    final double pipSize = width * 0.14;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? (Matrix4.identity()..translate(0.0, -6.0)..scale(1.05))
            : Matrix4.identity(),
        width: actualWidth,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [const Color(0xFFF0F8FF), const Color(0xFFE8F4FD)]
                : [const Color(0xFFFCFCFC), const Color(0xFFF0F0F0)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFFBDBDBD),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
          ],
        ),
        child: isHorizontal
            ? Row(children: _buildHalves(pipSize))
            : Column(children: _buildHalves(pipSize)),
      ),
    );
  }

  List<Widget> _buildHalves(double pipSize) {
    return [
      Expanded(child: _PipGrid(value: ficha.a, pipSize: pipSize, isHorizontal: isHorizontal)),
      Container(
        width: isHorizontal ? 1.5 : double.infinity,
        height: isHorizontal ? double.infinity : 1.5,
        margin: isHorizontal
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF757575).withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
      Expanded(child: _PipGrid(value: ficha.b, pipSize: pipSize, isHorizontal: isHorizontal)),
    ];
  }
}

class _PipGrid extends StatelessWidget {
  final int value;
  final double pipSize;
  final bool isHorizontal;

  const _PipGrid({
    required this.value,
    required this.pipSize,
    this.isHorizontal = false,
  });

  // Posiciones base de los pips (modo vertical/retrato)
  static const List<List<double>> _pipPositions = [
    [0.2, 0.2],  // 0: top-left
    [0.5, 0.2],  // 1: top-center
    [0.8, 0.2],  // 2: top-right
    [0.2, 0.5],  // 3: mid-left
    [0.5, 0.5],  // 4: center
    [0.8, 0.5],  // 5: mid-right
    [0.2, 0.8],  // 6: bot-left
    [0.5, 0.8],  // 7: bot-center
    [0.8, 0.8],  // 8: bot-right
  ];

  static const List<List<bool>> _pipLayouts = [
    [false, false, false, false, false, false, false, false, false], // 0
    [false, false, false, false, true,  false, false, false, false], // 1
    [true,  false, false, false, false, false, false, false, true ], // 2
    [true,  false, false, false, true,  false, false, false, true ], // 3
    [true,  false, true,  false, false, false, true,  false, true ], // 4
    [true,  false, true,  false, true,  false, true,  false, true ], // 5
    [true,  false, true,  true,  false, true,  true,  false, true ], // 6
  ];

  @override
  Widget build(BuildContext context) {
    if (value < 0 || value > 6) return const SizedBox();
    final layout = _pipLayouts[value];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final ps = math.min(pipSize, math.min(w, h) * 0.22);

        return Stack(
          children: [
            for (int i = 0; i < 9; i++)
              if (layout[i])
                Positioned(
                  // Cuando la ficha es horizontal, rotamos los pips 90° CCW
                  // para que se vean como en un dominó real girado.
                  // Rotación CCW: (x, y) → (y, 1 - x)
                  left: (isHorizontal ? _pipPositions[i][1] : _pipPositions[i][0]) * w - ps / 2,
                  top: (isHorizontal ? (1.0 - _pipPositions[i][0]) : _pipPositions[i][1]) * h - ps / 2,
                  child: Container(
                    width: ps,
                    height: ps,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}