// FILE: lib/widgets/tablero_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class TableroWidget extends StatelessWidget {
  const TableroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final boardChain = gameProvider.gameState.boardChain;
    const double pieceWidth = 55.0;

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
        itemBuilder: (context, index) {
          final ficha = boardChain[index];
          final isDouble = ficha.isDouble;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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