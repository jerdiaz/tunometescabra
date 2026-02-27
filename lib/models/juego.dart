// FILE: lib/models/juego.dart
import 'package:flutter/foundation.dart';
import 'ficha.dart';
import 'jugador.dart';

enum PlayEnd { left, right }

@immutable
class LastMove {
  final int playerIndex;
  final DominoPiece piece;
  final bool wasValid;
  final PlayEnd end;

  const LastMove({
    required this.playerIndex,
    required this.piece,
    required this.wasValid,
    required this.end,
  });
}

@immutable
class GameState {
  final List<Player> players;
  final List<DominoPiece> boneyard;
  final List<DominoPiece> boardChain;
  final int currentPlayerIndex;
  final LastMove? lastMove;
  final bool isGameOver;
  final int? winnerIndex;

  const GameState({
    required this.players,
    required this.boneyard,
    required this.boardChain,
    required this.currentPlayerIndex,
    this.lastMove,
    this.isGameOver = false,
    this.winnerIndex,
  });

  // ----- ESTA ES LA CORRECCIÓN CLAVE -----
  // Ahora el estado inicial simula una partida de 2 jugadores por defecto.
  // Esto evita que la UI se quede "cargando" antes de que el juego real comience.
  factory GameState.initial() {
    return const GameState(
      players: [
        Player(id: 0, hand: []),
        Player(id: 1, hand: [])
      ],
      boneyard: [],
      boardChain: [],
      currentPlayerIndex: 0,
    );
  }

  GameState copyWith({
    List<Player>? players,
    List<DominoPiece>? boneyard,
    List<DominoPiece>? boardChain,
    int? currentPlayerIndex,
    LastMove? lastMove,
    bool? isGameOver,
    int? winnerIndex,
    bool clearLastMove = false,
  }) {
    return GameState(
      players: players ?? this.players,
      boneyard: boneyard ?? this.boneyard,
      boardChain: boardChain ?? this.boardChain,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
      isGameOver: isGameOver ?? this.isGameOver,
      winnerIndex: winnerIndex ?? this.winnerIndex,
    );
  }
}

