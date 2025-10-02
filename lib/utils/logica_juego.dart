// FILE: lib/utils/logica_juego.dart
import 'dart:math';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../models/jugador.dart';

class AccusationResult {
  final GameState newState;
  final bool wasCheating;
  AccusationResult({required this.newState, required this.wasCheating});
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

  GameState startGame() {
    final deck = _createDeck();
    List<Player> players = [
      Player(id: 0, hand: deck.sublist(0, 7)),
      Player(id: 1, hand: deck.sublist(7, 14)),
    ];
    final boneyard = deck.sublist(14);

    int startingPlayerIndex = -1;
    DominoPiece? startingPiece;

    for (int i = 6; i >= 0; i--) {
      final doublePiece = DominoPiece(a: i, b: i);
      final p0Has = players[0].hand.contains(doublePiece);
      final p1Has = players[1].hand.contains(doublePiece);

      if (p0Has) {
        startingPlayerIndex = 0;
        startingPiece = doublePiece;
        break;
      }
      if (p1Has) {
        startingPlayerIndex = 1;
        startingPiece = doublePiece;
        break;
      }
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
      currentPlayerIndex: (startingPlayerIndex + (startingPiece != null ? 1 : 0)) % 2,
    );
  }

  bool _isMoveValid(List<DominoPiece> board, DominoPiece piece, PlayEnd end) {
    if (board.isEmpty) return true;
    final int valueToMatch = (end == PlayEnd.left) ? board.first.a : board.last.b;
    return piece.a == valueToMatch || piece.b == valueToMatch;
  }

  GameState playPiece({
    required GameState currentState,
    required DominoPiece piece,
    required PlayEnd end,
  }) {
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
      currentPlayerIndex: (currentState.currentPlayerIndex + 1) % 2,
      lastMove: LastMove(playerIndex: currentState.currentPlayerIndex, piece: piece, wasValid: wasValid),
      isGameOver: isGameOver,
      winnerIndex: isGameOver ? currentState.currentPlayerIndex : null,
    );
  }

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

  AccusationResult accuse({required GameState currentState}) {
    final lastMove = currentState.lastMove;
    if (lastMove == null) return AccusationResult(newState: currentState, wasCheating: false);

    final updatedPlayers = List<Player>.from(currentState.players.map((p) => p.copyWith()));
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);

    if (!lastMove.wasValid) { // Acusación CORRECTA
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