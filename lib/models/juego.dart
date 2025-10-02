import 'ficha.dart';
import 'jugador.dart';

/// Almacena el último movimiento realizado para la mecánica de acusación.
class LastMove {
  final int playerIndex;
  final DominoPiece domino;
  final bool wasValid;

  LastMove({
    required this.playerIndex,
    required this.domino,
    required this.wasValid,
  });
}

/// Define los posibles estados de la partida.
enum GameStatus { playing, gameOver, paused }

/// Encapsula todo el estado de una partida de dominó.
/// Esta clase es inmutable para facilitar la gestión del estado.
class GameState {
  final List<Player> players;
  final List<DominoPiece> boneyard;
  final List<DominoPiece> boardChain;
  final int currentPlayerIndex;
  final LastMove? lastMove;
  final GameStatus status;
  final int? winnerId;

  GameState({
    required this.players,
    required this.boneyard,
    required this.boardChain,
    required this.currentPlayerIndex,
    this.lastMove,
    this.status = GameStatus.playing,
    this.winnerId,
  });

  /// Constructor inicial para un juego nuevo.
  factory GameState.initial() {
    return GameState(
      players: [],
      boneyard: [],
      boardChain: [],
      currentPlayerIndex: 0,
    );
  }

  /// Crea una copia del estado del juego con valores actualizados.
  GameState copyWith({
    List<Player>? players,
    List<DominoPiece>? boneyard,
    List<DominoPiece>? boardChain,
    int? currentPlayerIndex,
    LastMove? lastMove,
    bool clearLastMove = false, // Para limpiar lastMove fácilmente
    GameStatus? status,
    int? winnerId,
  }) {
    return GameState(
      players: players ?? this.players,
      boneyard: boneyard ?? this.boneyard,
      boardChain: boardChain ?? this.boardChain,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}