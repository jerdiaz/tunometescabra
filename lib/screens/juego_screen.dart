// FILE: lib/screens/juego_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tablero_widget.dart';
import '../widgets/jugador_widget.dart';

class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key});

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia el juego automáticamente una vez que la pantalla se ha cargado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para reaccionar a los cambios y mostrar diálogos.
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;

        // Lógica para mostrar mensajes emergentes (diálogos) de forma segura.
        if (gameProvider.message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Prevenimos mostrar un diálogo si ya hay uno en pantalla.
            if (ModalRoute.of(context)?.isCurrent != true) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text(gameProvider.message!.title),
                content: Text(gameProvider.message!.body),
                actions: [
                  TextButton(
                    onPressed: () {
                      final isGameOver = gameProvider.gameState.isGameOver;
                      Navigator.of(ctx).pop(); // Cierra el diálogo
                      gameProvider.clearMessage(); // Limpia el mensaje para que no vuelva a aparecer.
                      if (isGameOver) {
                        gameProvider.startGame(); // Reinicia el juego si ha terminado.
                      }
                    },
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            title: const Text('Dominó con Trampa y Castigo'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Barra de información superior
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.grey[800],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Turno: Jugador ${gameState.currentPlayerIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Fichas para Robar: ${gameState.boneyard.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // El tablero ocupa el espacio central expandido
              const Expanded(
                child: TableroWidget(),
              ),
              // La mano del jugador actual en la parte inferior
              const JugadorWidget(),
            ],
          ),
        );
      },
    );
  }
}

