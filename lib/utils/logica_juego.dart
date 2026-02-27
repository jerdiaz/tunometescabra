// FILE: lib/utils/logica_juego.dart
import 'dart:math';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../models/jugador.dart';

class AccusationResult {
  final GameState newState;
  final bool wasCheating;
  final bool turnSkipped;

  AccusationResult({
    required this.newState,
    required this.wasCheating,
    this.turnSkipped = false,
  });
}

class GameLogic {
  List<DominoPiece> _createDeck() {
    List<DominoPiece> deck = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        deck.add(DominoPiece(a: i, b: j));
      }
    }
    deck.shuffle(Random());
    return deck;
  }

  GameState startGame({required int playerCount}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError('El número de jugadores debe estar entre 2 y 4.');
    }

    final deck = _createDeck();
    List<Player> players = [];
    int tilesPerPlayer = 7;
    int cardsDealt = 0;

    for (int i = 0; i < playerCount; i++) {
      players.add(Player(
          id: i,
          hand: deck.sublist(cardsDealt, cardsDealt + tilesPerPlayer)));
      cardsDealt += tilesPerPlayer;
    }
    final boneyard = deck.sublist(cardsDealt);

    int startingPlayerIndex = -1;
    DominoPiece? startingPiece;

    for (int i = 6; i >= 0; i--) {
      final doublePiece = DominoPiece(a: i, b: i);
      for (int pIdx = 0; pIdx < playerCount; pIdx++) {
        if (players[pIdx].hand.contains(doublePiece)) {
          startingPlayerIndex = pIdx;
          startingPiece = doublePiece;
          break;
        }
      }
      if (startingPiece != null) break;
    }

    if (startingPlayerIndex == -1) {
      startingPlayerIndex = 0;
    }

    final List<DominoPiece> boardChain = [];
    if (startingPiece != null) {
      boardChain.add(startingPiece);
      final startingHand =
          List<DominoPiece>.from(players[startingPlayerIndex].hand);
      startingHand.remove(startingPiece);
      players[startingPlayerIndex] =
          players[startingPlayerIndex].copyWith(hand: startingHand);
    }

    return GameState(
      players: players,
      boneyard: boneyard,
      boardChain: boardChain,
      currentPlayerIndex:
          (startingPlayerIndex + (startingPiece != null ? 1 : 0)) %
              playerCount,
    );
  }

  // La ficha ya viene en la orientación elegida por el jugador.
  // Se coloca SIEMPRE en el tablero (para la mecánica de trampa).
  GameState playPiece({
    required GameState currentState,
    required DominoPiece piece,
    required PlayEnd end,
  }) {
    final playerCount = currentState.players.length;
    final currentPlayer =
        currentState.players[currentState.currentPlayerIndex];
    if (!currentPlayer.hand.contains(piece)) return currentState;

    // Quitamos la ficha de la mano.
    final newHand = List<DominoPiece>.from(currentPlayer.hand)..remove(piece);
    final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

    // Verificar validez según la orientación elegida por el jugador.
    bool wasValid;
    if (newBoardChain.isEmpty) {
      wasValid = true;
    } else if (end == PlayEnd.left) {
      wasValid = piece.b == newBoardChain.first.a;
    } else {
      wasValid = piece.a == newBoardChain.last.b;
    }

    // SIEMPRE colocar la ficha en el tablero (trampa incluida).
    if (newBoardChain.isEmpty) {
      newBoardChain.add(piece);
    } else if (end == PlayEnd.left) {
      newBoardChain.insert(0, piece);
    } else {
      newBoardChain.add(piece);
    }

    final updatedPlayers = List<Player>.from(currentState.players);
    updatedPlayers[currentState.currentPlayerIndex] =
        currentPlayer.copyWith(hand: newHand);

    final bool isGameOver = wasValid && newHand.isEmpty;

    return currentState.copyWith(
      players: updatedPlayers,
      boardChain: newBoardChain,
      currentPlayerIndex:
          (currentState.currentPlayerIndex + 1) % playerCount,
      lastMove: LastMove(
        playerIndex: currentState.currentPlayerIndex,
        piece: piece,
        wasValid: wasValid,
        end: end,
      ),
      isGameOver: isGameOver,
      winnerIndex: isGameOver ? currentState.currentPlayerIndex : null,
    );
  }

  GameState drawPiece({required GameState currentState}) {
    if (currentState.boneyard.isEmpty) return currentState;

    final currentPlayer =
        currentState.players[currentState.currentPlayerIndex];
    final newHand = List<DominoPiece>.from(currentPlayer.hand);
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    newHand.add(newBoneyard.removeAt(0));
    final updatedPlayers = List<Player>.from(currentState.players);
    updatedPlayers[currentState.currentPlayerIndex] =
        currentPlayer.copyWith(hand: newHand);

    return currentState.copyWith(
      players: updatedPlayers,
      boneyard: newBoneyard,
      clearLastMove: true,
    );
  }

  AccusationResult accuse({required GameState currentState}) {
    final lastMove = currentState.lastMove;
    if (lastMove == null) {
      return AccusationResult(newState: currentState, wasCheating: false);
    }

    final updatedPlayers = List<Player>.from(
        currentState.players.map((p) => p.copyWith()));
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    final playerCount = currentState.players.length;

    if (!lastMove.wasValid) {
      // Acusación CORRECTA
      final cheaterIndex = lastMove.playerIndex;
      final cheaterHand =
          List<DominoPiece>.from(updatedPlayers[cheaterIndex].hand);
      final newBoardChain =
          List<DominoPiece>.from(currentState.boardChain);

      // Devolver la ficha al tramposo.
      cheaterHand.add(lastMove.piece);

      // Quitar la ficha del tablero usando el lado donde fue jugada.
      if (lastMove.end == PlayEnd.left && newBoardChain.isNotEmpty) {
        newBoardChain.removeAt(0);
      } else if (lastMove.end == PlayEnd.right && newBoardChain.isNotEmpty) {
        newBoardChain.removeLast();
      }

      // Castigo: el tramposo roba 1 ficha del pozo.
      if (newBoneyard.isNotEmpty) {
        cheaterHand.add(newBoneyard.removeAt(0));
      }
      updatedPlayers[cheaterIndex] =
          updatedPlayers[cheaterIndex].copyWith(hand: cheaterHand);

      return AccusationResult(
        newState: currentState.copyWith(
          players: updatedPlayers,
          boneyard: newBoneyard,
          boardChain: newBoardChain,
          currentPlayerIndex: cheaterIndex,
          clearLastMove: true,
        ),
        wasCheating: true,
      );
    } else {
      // Acusación FALSA
      final accuserIndex = currentState.currentPlayerIndex;

      if (newBoneyard.isEmpty) {
        return AccusationResult(
          newState: currentState.copyWith(
            currentPlayerIndex:
                (currentState.currentPlayerIndex + 1) % playerCount,
            clearLastMove: true,
          ),
          wasCheating: false,
          turnSkipped: true,
        );
      } else {
        final accuserHand =
            List<DominoPiece>.from(updatedPlayers[accuserIndex].hand);
        if (newBoneyard.isNotEmpty) {
          accuserHand.add(newBoneyard.removeAt(0));
        }
        updatedPlayers[accuserIndex] =
            updatedPlayers[accuserIndex].copyWith(hand: accuserHand);

        return AccusationResult(
          newState: currentState.copyWith(
            players: updatedPlayers,
            boneyard: newBoneyard,
            clearLastMove: true,
          ),
          wasCheating: false,
        );
      }
    }
  }

  GameState passTurn({required GameState currentState}) {
    final playerCount = currentState.players.length;
    return currentState.copyWith(
      currentPlayerIndex:
          (currentState.currentPlayerIndex + 1) % playerCount,
      clearLastMove: true,
    );
  }

  bool isGameBlocked(GameState state) {
    if (state.boneyard.isNotEmpty) return false;
    if (state.boardChain.isEmpty) return false;

    final leftValue = state.boardChain.first.a;
    final rightValue = state.boardChain.last.b;

    for (var player in state.players) {
      for (var piece in player.hand) {
        if (piece.a == leftValue || piece.b == leftValue ||
            piece.a == rightValue || piece.b == rightValue) {
          return false;
        }
      }
    }
    return true;
  }

  int getWinnerByLowestScore(GameState state) {
    int lowestScore = 999;
    int winnerIndex = 0;
    for (int i = 0; i < state.players.length; i++) {
      int score = 0;
      for (var piece in state.players[i].hand) {
        score += piece.a + piece.b;
      }
      if (score < lowestScore) {
        lowestScore = score;
        winnerIndex = i;
      }
    }
    return winnerIndex;
  }
}
