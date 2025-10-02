// FILE: lib/utils/logica_juego.dart
import 'dart:math';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../models/jugador.dart';

class AccusationResult {
  final GameState newState;
  final bool wasCheating;
  final bool turnSkipped; // Nuevo: para saber si se saltó el turno

  AccusationResult({
    required this.newState,
    required this.wasCheating,
    this.turnSkipped = false,
  });
}

class GameLogic {
  // ... (El método _createDeck no cambia) ...
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

  // ... (El método startGame no cambia) ...
  GameState startGame({required int playerCount}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError('El número de jugadores debe estar entre 2 y 4.');
    }

    final deck = _createDeck();
    List<Player> players = [];
    int tilesPerPlayer = 7;
    int cardsDealt = 0;

    for (int i = 0; i < playerCount; i++) {
      players.add(Player(id: i, hand: deck.sublist(cardsDealt, cardsDealt + tilesPerPlayer)));
      cardsDealt += tilesPerPlayer;
    }
    final boneyard = deck.sublist(cardsDealt);

    int startingPlayerIndex = -1;
    DominoPiece? startingPiece;

    for (int i = 6; i >= 0; i--) {
      final doublePiece = DominoPiece(a: i, b: i);
      for(int p_idx = 0; p_idx < playerCount; p_idx++) {
        if (players[p_idx].hand.contains(doublePiece)) {
          startingPlayerIndex = p_idx;
          startingPiece = doublePiece;
          break;
        }
      }
      if(startingPiece != null) break;
    }

    if (startingPlayerIndex == -1) {
      startingPlayerIndex = 0;
    }

    final List<DominoPiece> boardChain = [];
    if (startingPiece != null) {
      boardChain.add(startingPiece);
      final startingHand = List<DominoPiece>.from(players[startingPlayerIndex].hand);
      startingHand.remove(startingPiece);
      players[startingPlayerIndex] = players[startingPlayerIndex].copyWith(hand: startingHand);
    }

    return GameState(
      players: players,
      boneyard: boneyard,
      boardChain: boardChain,
      currentPlayerIndex: (startingPlayerIndex + (startingPiece != null ? 1 : 0)) % playerCount,
    );
  }

  bool _isMoveValid(List<DominoPiece> board, DominoPiece piece, PlayEnd end) {
    if (board.isEmpty) return true;
    final int valueToMatch = (end == PlayEnd.left) ? board.first.a : board.last.b;
    return piece.a == valueToMatch || piece.b == valueToMatch;
  }

  // ... (El método playPiece no cambia) ...
  GameState playPiece({
    required GameState currentState,
    required DominoPiece piece,
    required PlayEnd end,
  }) {
    final playerCount = currentState.players.length;
    final currentPlayer = currentState.players[currentState.currentPlayerIndex];
    if (!currentPlayer.hand.contains(piece)) return currentState;

    final bool wasValid = _isMoveValid(currentState.boardChain, piece, end);

    final newHand = List<DominoPiece>.from(currentPlayer.hand)..remove(piece);
    final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

    if (newBoardChain.isEmpty) {
      newBoardChain.add(piece);
    } else {
      var pieceToPlay = piece;
      if (end == PlayEnd.left) {
        if (piece.b != newBoardChain.first.a) pieceToPlay = piece.flipped;
        newBoardChain.insert(0, pieceToPlay);
      } else {
        if (piece.a != newBoardChain.last.b) pieceToPlay = piece.flipped;
        newBoardChain.add(pieceToPlay);
      }
    }

    final updatedPlayers = List<Player>.from(currentState.players);
    updatedPlayers[currentState.currentPlayerIndex] = currentPlayer.copyWith(hand: newHand);

    final bool isGameOver = newHand.isEmpty;

    return currentState.copyWith(
      players: updatedPlayers,
      boardChain: newBoardChain,
      currentPlayerIndex: (currentState.currentPlayerIndex + 1) % playerCount,
      lastMove: LastMove(playerIndex: currentState.currentPlayerIndex, piece: piece, wasValid: wasValid),
      isGameOver: isGameOver,
      winnerIndex: isGameOver ? currentState.currentPlayerIndex : null,
    );
  }

  // ... (El método drawPiece no cambia) ...
  GameState drawPiece({required GameState currentState}) {
    if (currentState.boneyard.isEmpty) return currentState;

    final currentPlayer = currentState.players[currentState.currentPlayerIndex];
    final newHand = List<DominoPiece>.from(currentPlayer.hand);
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    newHand.add(newBoneyard.removeAt(0));
    final updatedPlayers = List<Player>.from(currentState.players);
    updatedPlayers[currentState.currentPlayerIndex] = currentPlayer.copyWith(hand: newHand);

    return currentState.copyWith(
      players: updatedPlayers,
      boneyard: newBoneyard,
      clearLastMove: true,
    );
  }

  // ----- MÉTODO 'accuse' ACTUALIZADO -----
  AccusationResult accuse({required GameState currentState}) {
    final lastMove = currentState.lastMove;
    if (lastMove == null) return AccusationResult(newState: currentState, wasCheating: false);

    final updatedPlayers = List<Player>.from(currentState.players.map((p) => p.copyWith()));
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    final playerCount = currentState.players.length;

    if (!lastMove.wasValid) { // Acusación CORRECTA
      // (Esta parte no cambia)
      final cheaterIndex = lastMove.playerIndex;
      final cheaterHand = List<DominoPiece>.from(updatedPlayers[cheaterIndex].hand);
      final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

      cheaterHand.add(lastMove.piece);

      if (newBoardChain.isNotEmpty && newBoardChain.first == lastMove.piece) {
        newBoardChain.removeAt(0);
      } else if (newBoardChain.isNotEmpty && newBoardChain.last == lastMove.piece) {
        newBoardChain.removeLast();
      }

      for (int i = 0; i < 2 && newBoneyard.isNotEmpty; i++) {
        cheaterHand.add(newBoneyard.removeAt(0));
      }
      updatedPlayers[cheaterIndex] = updatedPlayers[cheaterIndex].copyWith(hand: cheaterHand);

      return AccusationResult(
          newState: currentState.copyWith(
            players: updatedPlayers,
            boneyard: newBoneyard,
            boardChain: newBoardChain,
            clearLastMove: true,
          ),
          wasCheating: true
      );

    } else { // Acusación FALSA
      final accuserIndex = currentState.currentPlayerIndex;

      // NUEVA REGLA: Si el pozo está vacío, el acusador pierde el turno.
      if (newBoneyard.isEmpty) {
        return AccusationResult(
          newState: currentState.copyWith(
            // Simplemente avanzamos al siguiente jugador.
            currentPlayerIndex: (currentState.currentPlayerIndex + 1) % playerCount,
            clearLastMove: true,
          ),
          wasCheating: false,
          turnSkipped: true, // Indicamos que se saltó el turno.
        );
      } else { // Si hay fichas, se mantiene la penalización original.
        final accuserHand = List<DominoPiece>.from(updatedPlayers[accuserIndex].hand);
        for (int i = 0; i < 2 && newBoneyard.isNotEmpty; i++) {
          accuserHand.add(newBoneyard.removeAt(0));
        }
        updatedPlayers[accuserIndex] = updatedPlayers[accuserIndex].copyWith(hand: accuserHand);

        return AccusationResult(
            newState: currentState.copyWith(
              players: updatedPlayers,
              boneyard: newBoneyard,
              clearLastMove: true,
            ),
            wasCheating: false
        );
      }
    }
  }

  // ----- NUEVO MÉTODO: 'passTurn' -----
  GameState passTurn({required GameState currentState}) {
    final playerCount = currentState.players.length;
    // Simplemente avanza al siguiente jugador y limpia el último movimiento.
    return currentState.copyWith(
      currentPlayerIndex: (currentState.currentPlayerIndex + 1) % playerCount,
      clearLastMove: true,
    );
  }
}

