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

  /// Calcula el siguiente índice de jugador activo.
  int _nextActivePlayer(List<Player> players, int current) {
    final n = players.length;
    int next = (current + 1) % n;
    int attempts = 0;
    while (!players[next].isActive && attempts < n) {
      next = (next + 1) % n;
      attempts++;
    }
    return next;
  }

  /// Cuenta los jugadores activos.
  int _activeCount(List<Player> players) {
    return players.where((p) => p.isActive).length;
  }

  GameState startGame(
      {required int playerCount, required List<String> playerNames}) {
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
          name: i < playerNames.length ? playerNames[i] : 'Jugador ${i + 1}',
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
      currentPlayerIndex: _nextActivePlayer(
          players, startingPlayerIndex + (startingPiece != null ? 0 : -1)),
    );
  }

  // ═══════════════════════════════════════════════════
  // ELIMINATE PLAYER (abandono)
  // ═══════════════════════════════════════════════════

  /// Elimina un jugador (abandono). Sus fichas pasan al pozo.
  /// Si solo queda 1 jugador activo, gana automáticamente.
  GameState eliminatePlayer({
    required GameState currentState,
    required int playerIndex,
  }) {
    final updatedPlayers =
        List<Player>.from(currentState.players.map((p) => p.copyWith()));
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);

    // Pasar fichas del jugador eliminado al pozo
    final eliminatedHand = updatedPlayers[playerIndex].hand;
    newBoneyard.addAll(eliminatedHand);
    newBoneyard.shuffle(Random());

    updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
      hand: [],
      isActive: false,
    );

    // Verificar si solo queda 1 jugador activo
    final activeCount = _activeCount(updatedPlayers);
    if (activeCount <= 1) {
      final winnerIndex = updatedPlayers.indexWhere((p) => p.isActive);
      return currentState.copyWith(
        players: updatedPlayers,
        boneyard: newBoneyard,
        isGameOver: true,
        winnerIndex: winnerIndex >= 0 ? winnerIndex : 0,
        clearAccusation: true,
      );
    }

    // Si era el turno del eliminado, avanzar al siguiente activo
    int newCurrentIndex = currentState.currentPlayerIndex;
    if (newCurrentIndex == playerIndex) {
      newCurrentIndex = _nextActivePlayer(updatedPlayers, playerIndex);
    }

    return currentState.copyWith(
      players: updatedPlayers,
      boneyard: newBoneyard,
      currentPlayerIndex: newCurrentIndex,
      clearLastMove: true,
      clearAccusation: true,
    );
  }

  // ═══════════════════════════════════════════════════
  // PLAY PIECE
  // ═══════════════════════════════════════════════════

  GameState playPiece({
    required GameState currentState,
    required DominoPiece piece,
    required PlayEnd end,
  }) {
    final currentPlayer = currentState.players[currentState.currentPlayerIndex];
    if (!currentPlayer.hand.contains(piece)) return currentState;

    final newHand = List<DominoPiece>.from(currentPlayer.hand)..remove(piece);
    final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

    bool wasValid;
    if (newBoardChain.isEmpty) {
      wasValid = true;
    } else if (end == PlayEnd.left) {
      wasValid = piece.b == newBoardChain.first.a;
    } else {
      wasValid = piece.a == newBoardChain.last.b;
    }

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

    final bool isGameOver = newHand.isEmpty;
    final nextPlayer =
        _nextActivePlayer(updatedPlayers, currentState.currentPlayerIndex);

    return currentState.copyWith(
      players: updatedPlayers,
      boardChain: newBoardChain,
      currentPlayerIndex: nextPlayer,
      lastMove: LastMove(
        playerIndex: currentState.currentPlayerIndex,
        piece: piece,
        wasValid: wasValid,
        end: end,
      ),
      isGameOver: isGameOver,
      winnerIndex: isGameOver ? currentState.currentPlayerIndex : null,
      clearAccusation: true,
    );
  }

  // ═══════════════════════════════════════════════════
  // DRAW PIECE
  // ═══════════════════════════════════════════════════

  GameState drawPiece({required GameState currentState}) {
    if (currentState.boneyard.isEmpty) return currentState;

    final currentPlayer = currentState.players[currentState.currentPlayerIndex];
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
      clearAccusation: true,
    );
  }

  // ═══════════════════════════════════════════════════
  // ACCUSE
  // ═══════════════════════════════════════════════════

  AccusationResult accuse({required GameState currentState}) {
    final lastMove = currentState.lastMove;
    if (lastMove == null) {
      return AccusationResult(newState: currentState, wasCheating: false);
    }

    final updatedPlayers =
        List<Player>.from(currentState.players.map((p) => p.copyWith()));
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    final accuserIndex = currentState.currentPlayerIndex;

    if (!lastMove.wasValid) {
      // ═══ Acusación CORRECTA ═══
      final cheaterIndex = lastMove.playerIndex;
      final cheaterHand =
          List<DominoPiece>.from(updatedPlayers[cheaterIndex].hand);
      final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

      cheaterHand.add(lastMove.piece);

      if (lastMove.end == PlayEnd.left && newBoardChain.isNotEmpty) {
        newBoardChain.removeAt(0);
      } else if (lastMove.end == PlayEnd.right && newBoardChain.isNotEmpty) {
        newBoardChain.removeLast();
      }

      // Castigo: roba 1 ficha (solo si <4 jugadores activos)
      final activeCount = _activeCount(updatedPlayers);
      if (activeCount < 4 && newBoneyard.isNotEmpty) {
        cheaterHand.add(newBoneyard.removeAt(0));
      }
      updatedPlayers[cheaterIndex] =
          updatedPlayers[cheaterIndex].copyWith(hand: cheaterHand);

      return AccusationResult(
        newState: currentState.copyWith(
          players: updatedPlayers,
          boneyard: newBoneyard,
          boardChain: newBoardChain,
          currentPlayerIndex: accuserIndex,
          isGameOver: false,
          winnerIndex: null,
          clearLastMove: true,
          lastAccusation: AccusationEvent(
            accuserIndex: accuserIndex,
            cheaterIndex: cheaterIndex,
            wasCheating: true,
          ),
        ),
        wasCheating: true,
      );
    } else {
      // ═══ Acusación FALSA ═══
      if (newBoneyard.isEmpty) {
        return AccusationResult(
          newState: currentState.copyWith(
            currentPlayerIndex: _nextActivePlayer(updatedPlayers, accuserIndex),
            clearLastMove: true,
            lastAccusation: AccusationEvent(
              accuserIndex: accuserIndex,
              cheaterIndex: lastMove.playerIndex,
              wasCheating: false,
              turnSkipped: true,
            ),
          ),
          wasCheating: false,
          turnSkipped: true,
        );
      } else {
        final accuserHand =
            List<DominoPiece>.from(updatedPlayers[accuserIndex].hand);
        accuserHand.add(newBoneyard.removeAt(0));
        updatedPlayers[accuserIndex] =
            updatedPlayers[accuserIndex].copyWith(hand: accuserHand);

        return AccusationResult(
          newState: currentState.copyWith(
            players: updatedPlayers,
            boneyard: newBoneyard,
            clearLastMove: true,
            lastAccusation: AccusationEvent(
              accuserIndex: accuserIndex,
              cheaterIndex: lastMove.playerIndex,
              wasCheating: false,
            ),
          ),
          wasCheating: false,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // PASS TURN
  // ═══════════════════════════════════════════════════

  GameState passTurn({required GameState currentState}) {
    return currentState.copyWith(
      currentPlayerIndex: _nextActivePlayer(
          currentState.players, currentState.currentPlayerIndex),
      clearLastMove: true,
      clearAccusation: true,
    );
  }

  bool isGameBlocked(GameState state) {
    if (state.boneyard.isNotEmpty) return false;
    if (state.boardChain.isEmpty) return false;

    final leftValue = state.boardChain.first.a;
    final rightValue = state.boardChain.last.b;

    for (var player in state.players) {
      if (!player.isActive) continue;
      for (var piece in player.hand) {
        if (piece.a == leftValue ||
            piece.b == leftValue ||
            piece.a == rightValue ||
            piece.b == rightValue) {
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
      if (!state.players[i].isActive) continue;
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
