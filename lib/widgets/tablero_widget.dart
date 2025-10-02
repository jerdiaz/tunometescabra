import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'ficha_widget.dart';

class TableroWidget extends StatelessWidget {
  const TableroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha al provider para obtener la cadena de fichas del tablero.
    final boardChain = context.watch<GameProvider>().gameState.boardChain;

    return Expanded(
      child: Container(
        color: Colors.green[800],
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: boardChain.isEmpty
              ? const Text(
            'El tablero está vacío. ¡El primer jugador empieza!',
            style: TextStyle(color: Colors.white, fontSize: 18),
          )
          // Usamos un ListView para que el tablero sea desplazable si crece mucho.
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: boardChain.length,
            itemBuilder: (context, index) {
              final ficha = boardChain[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                // Las fichas en el tablero siempre son horizontales.
                child: FichaWidget(
                  ficha: ficha,
                  isHorizontal: true,
                  width: 100,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}