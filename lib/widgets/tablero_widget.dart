// FILE: lib/widgets/tablero_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class TableroWidget extends StatelessWidget {
  const TableroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del GameProvider para reconstruir el tablero.
    final gameProvider = context.watch<GameProvider>();
    final boardChain = gameProvider.gameState.boardChain;

    // Definimos un tamaño base para las fichas en el tablero.
    const double pieceWidth = 55.0; // Ancho de la ficha vertical

    return Container(
      width: double.infinity,
      color: Colors.green.shade800,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: boardChain.isEmpty
          ? const Center(
        child: Text(
          'El tablero está vacío. ¡Haz la primera jugada!',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: boardChain.length,
        // CORRECCIÓN: Se eliminó 'itemExtent'.
        // Ahora el ListView permite que cada ficha tenga su propio ancho,
        // ya sea vertical (ancho normal) u horizontal (ancho doble).
        itemBuilder: (context, index) {
          final ficha = boardChain[index];

          // Las fichas dobles se dibujan verticalmente, las otras horizontalmente.
          final isDouble = ficha.isDouble;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              // Pasamos el tamaño correcto al FichaWidget.
              // El FichaWidget ya sabe cómo calcular su propio tamaño
              // basado en si es horizontal o no.
              child: FichaWidget(
                ficha: ficha,
                isHorizontal: !isDouble,
                width: pieceWidth,
              ),
            ),
          );
        },
      ),
    );
  }
}

