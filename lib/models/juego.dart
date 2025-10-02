// FILE: lib/models/juego.dart
import 'package:flutter/foundation.dart';
import 'ficha.dart';
import 'jugador.dart';

enum PlayEnd { left, right }

@immutable
class LastMove {
  final int playerIndex;
  final DominoPiece piece; // <--- El campo se llama 'piece'
  final bool wasValid;

  const LastMove({
    required this.playerIndex,
    required this.piece,
    required this.wasValid,
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

  factory GameState.initial() {
    return GameState(
      players: [const Player(id: 0, hand: []), const Player(id: 1, hand: [])],
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