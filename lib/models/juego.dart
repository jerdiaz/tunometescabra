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

  Map<String, dynamic> toMap() => {
        'playerIndex': playerIndex,
        'piece': piece.toMap(),
        'wasValid': wasValid,
        'end': end == PlayEnd.left ? 'left' : 'right',
      };

  factory LastMove.fromMap(Map<String, dynamic> m) => LastMove(
        playerIndex: m['playerIndex'] as int,
        piece: DominoPiece.fromMap(Map<String, dynamic>.from(m['piece'])),
        wasValid: m['wasValid'] as bool,
        end: m['end'] == 'left' ? PlayEnd.left : PlayEnd.right,
      );
}

/// Evento de acusación que se sincroniza entre jugadores vía Firestore.
@immutable
class AccusationEvent {
  final int accuserIndex;
  final int cheaterIndex;
  final bool wasCheating;
  final bool turnSkipped; // Acusación falsa sin pozo → pierde turno

  const AccusationEvent({
    required this.accuserIndex,
    required this.cheaterIndex,
    required this.wasCheating,
    this.turnSkipped = false,
  });

  Map<String, dynamic> toMap() => {
        'accuserIndex': accuserIndex,
        'cheaterIndex': cheaterIndex,
        'wasCheating': wasCheating,
        'turnSkipped': turnSkipped,
      };

  factory AccusationEvent.fromMap(Map<String, dynamic> m) => AccusationEvent(
        accuserIndex: m['accuserIndex'] as int,
        cheaterIndex: m['cheaterIndex'] as int,
        wasCheating: m['wasCheating'] as bool,
        turnSkipped: m['turnSkipped'] as bool? ?? false,
      );
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
  final AccusationEvent? lastAccusation;

  const GameState({
    required this.players,
    required this.boneyard,
    required this.boardChain,
    required this.currentPlayerIndex,
    this.lastMove,
    this.isGameOver = false,
    this.winnerIndex,
    this.lastAccusation,
  });

  factory GameState.initial() {
    return const GameState(
      players: [
        Player(id: 0, name: 'Jugador 1', hand: []),
        Player(id: 1, name: 'Jugador 2', hand: [])
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
    AccusationEvent? lastAccusation,
    bool clearLastMove = false,
    bool clearAccusation = false,
  }) {
    return GameState(
      players: players ?? this.players,
      boneyard: boneyard ?? this.boneyard,
      boardChain: boardChain ?? this.boardChain,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
      isGameOver: isGameOver ?? this.isGameOver,
      winnerIndex: winnerIndex ?? this.winnerIndex,
      lastAccusation:
          clearAccusation ? null : lastAccusation ?? this.lastAccusation,
    );
  }

  Map<String, dynamic> toMap() => {
        'players': players.map((p) => p.toMap()).toList(),
        'boneyard': boneyard.map((p) => p.toMap()).toList(),
        'boardChain': boardChain.map((p) => p.toMap()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'lastMove': lastMove?.toMap(),
        'isGameOver': isGameOver,
        'winnerIndex': winnerIndex,
        'lastAccusation': lastAccusation?.toMap(),
      };

  factory GameState.fromMap(Map<String, dynamic> m) => GameState(
        players: (m['players'] as List)
            .map((p) => Player.fromMap(Map<String, dynamic>.from(p)))
            .toList(),
        boneyard: (m['boneyard'] as List)
            .map((p) => DominoPiece.fromMap(Map<String, dynamic>.from(p)))
            .toList(),
        boardChain: (m['boardChain'] as List)
            .map((p) => DominoPiece.fromMap(Map<String, dynamic>.from(p)))
            .toList(),
        currentPlayerIndex: m['currentPlayerIndex'] as int,
        lastMove: m['lastMove'] != null
            ? LastMove.fromMap(Map<String, dynamic>.from(m['lastMove']))
            : null,
        isGameOver: m['isGameOver'] as bool? ?? false,
        winnerIndex: m['winnerIndex'] as int?,
        lastAccusation: m['lastAccusation'] != null
            ? AccusationEvent.fromMap(
                Map<String, dynamic>.from(m['lastAccusation']))
            : null,
      );
}
