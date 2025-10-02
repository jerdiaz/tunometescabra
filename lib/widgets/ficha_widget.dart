// FILE: lib/widgets/ficha_widget.dart
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
    final double pipSize = width * 0.15;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: actualWidth,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.black54,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.blueAccent.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            )
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
      Expanded(child: _PipGrid(value: ficha.a, pipSize: pipSize)),
      Container(
        width: isHorizontal ? 2 : double.infinity,
        height: isHorizontal ? double.infinity : 2,
        color: Colors.black54,
        margin: isHorizontal ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.symmetric(horizontal: 8),
      ),
      Expanded(child: _PipGrid(value: ficha.b, pipSize: pipSize)),
    ];
  }
}

// Widget auxiliar para dibujar los puntos (pips)
class _PipGrid extends StatelessWidget {
  final int value;
  final double pipSize;
  const _PipGrid({required this.value, required this.pipSize});

  // CORRECCIÓN CLAVE: Esta matriz ahora representa la visibilidad de cada punto
  // en una cuadrícula de 3x3 para los números del 1 al 6.
  static const List<List<bool>> _pipLayouts = [
    // 0
    [false, false, false, false, false, false, false, false, false],
    // 1
    [false, false, false, false, true,  false, false, false, false],
    // 2
    [true,  false, false, false, false, false, false, false, true ],
    // 3
    [true,  false, false, false, true,  false, false, false, true ],
    // 4
    [true,  false, true,  false, false, false, true,  false, true ],
    // 5
    [true,  false, true,  false, true,  false, true,  false, true ],
    // 6
    [true,  false, true,  true,  false, true,  true,  false, true ],
  ];

  @override
  Widget build(BuildContext context) {
    // Si el valor está fuera de rango, no dibuja nada.
    if (value < 0 || value > 6) return Container();

    final layout = _pipLayouts[value];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: 9,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Center(
          child: Container(
            width: pipSize,
            height: pipSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // El punto solo es visible si el layout lo indica.
              color: layout[index] ? Colors.black : Colors.transparent,
            ),
          ),
        );
      },
    );
  }
}

