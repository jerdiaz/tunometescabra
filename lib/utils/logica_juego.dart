import 'dart:math';
import '../models/ficha.dart';
import '../models/jugador.dart';
import '../models/juego.dart';

class GameLogic {
  /// Inicia una nueva partida, creando el mazo, barajando y repartiendo.
  GameState startGame({int playerCount = 2, int initialHandSize = 7}) {
    // 1. Crear el mazo completo de 28 fichas.
    List<DominoPiece> deck = _createDeck();
    deck.shuffle(Random());

    // 2. Repartir las manos iniciales a los jugadores.
    List<Player> players = [];
    for (int i = 0; i < playerCount; i++) {
      List<DominoPiece> hand = deck.sublist(0, initialHandSize);
      deck.removeRange(0, initialHandSize);
      players.add(Player(id: i, hand: hand));
    }

    // 3. Determinar quién empieza (el que tenga el doble más alto).
    int startingPlayerIndex = -1;
    int highestDoubleValue = -1;
    DominoPiece? startingPiece;

    for (int i = 0; i < players.length; i++) {
      for (final piece in players[i].hand) {
        if (piece.a == piece.b && piece.a > highestDoubleValue) {
          highestDoubleValue = piece.a;
          startingPlayerIndex = i;
          startingPiece = piece;
        }
      }
    }

    // Si nadie tiene un doble, se podría implementar otra regla (ej. ficha más alta).
    // Por ahora, si no hay dobles, el jugador 0 empieza con su primera ficha.
    if (startingPlayerIndex == -1) {
      startingPlayerIndex = 0;
      startingPiece = players[0].hand[0];
    }

    // 4. Mover la ficha inicial de la mano del jugador al tablero.
    players[startingPlayerIndex].hand.remove(startingPiece!);
    final boardChain = [startingPiece];

    // 5. El turno es del siguiente jugador.
    final currentPlayerIndex = (startingPlayerIndex + 1) % playerCount;

    // 6. Devolver el estado inicial del juego.
    return GameState(
      players: players,
      boneyard: deck, // El resto del mazo es el pozo.
      boardChain: boardChain,
      currentPlayerIndex: currentPlayerIndex,
      status: GameStatus.playing,
    );
  }

  /// Procesa la jugada de una ficha por parte del jugador actual.
  GameState playPiece({
    required GameState currentState,
    required DominoPiece pieceToPlay,
    required String side, // 'left' or 'right'
  }) {
    final player = currentState.players[currentState.currentPlayerIndex];

    // 1. Validar si la jugada es legal.
    final bool isValid = _isMoveValid(
        piece: pieceToPlay,
        side: side,
        boardChain: currentState.boardChain
    );

    // 2. Quitar la ficha de la mano del jugador.
    final newHand = List<DominoPiece>.from(player.hand)..remove(pieceToPlay);
    final updatedPlayer = player.copyWith(hand: newHand);

    final newPlayers = List<Player>.from(currentState.players);
    newPlayers[currentState.currentPlayerIndex] = updatedPlayer;

    // 3. Añadir la ficha al tablero en la posición correcta.
    DominoPiece pieceForBoard = pieceToPlay;
    final newBoardChain = List<DominoPiece>.from(currentState.boardChain);

    if (side == 'left') {
      if (pieceForBoard.b != newBoardChain.first.a) {
        pieceForBoard = pieceForBoard.flipped;
      }
      newBoardChain.insert(0, pieceForBoard);
    } else { // 'right'
      if (pieceForBoard.a != newBoardChain.last.b) {
        pieceForBoard = pieceForBoard.flipped;
      }
      newBoardChain.add(pieceForBoard);
    }

    // 4. Crear el registro de la última jugada para posibles acusaciones.
    final lastMove = LastMove(
      playerIndex: currentState.currentPlayerIndex,
      domino: pieceToPlay,
      wasValid: isValid,
    );

    // 5. Comprobar si el jugador ha ganado.
    if (newHand.isEmpty) {
      return currentState.copyWith(
        players: newPlayers,
        boardChain: newBoardChain,
        status: GameStatus.gameOver,
        winnerId: player.id,
        lastMove: lastMove,
      );
    }

    // 6. Pasar al siguiente jugador.
    final nextPlayerIndex = (currentState.currentPlayerIndex + 1) % currentState.players.length;

    return currentState.copyWith(
      players: newPlayers,
      boardChain: newBoardChain,
      currentPlayerIndex: nextPlayerIndex,
      lastMove: lastMove,
    );
  }

  /// Procesa la acción de robar una ficha del pozo.
  GameState drawPiece({required GameState currentState}) {
    if (currentState.boneyard.isEmpty) {
      // No se puede robar, se pasa el turno.
      final nextPlayerIndex = (currentState.currentPlayerIndex + 1) % currentState.players.length;
      return currentState.copyWith(
        currentPlayerIndex: nextPlayerIndex,
        clearLastMove: true, // Robar o pasar anula la posibilidad de acusar.
      );
    }

    final player = currentState.players[currentState.currentPlayerIndex];
    final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
    final pieceDrawn = newBoneyard.removeAt(0);

    final newHand = List<DominoPiece>.from(player.hand)..add(pieceDrawn);
    final updatedPlayer = player.copyWith(hand: newHand);

    final newPlayers = List<Player>.from(currentState.players);
    newPlayers[currentState.currentPlayerIndex] = updatedPlayer;

    return currentState.copyWith(
      players: newPlayers,
      boneyard: newBoneyard,
      clearLastMove: true, // Robar anula la posibilidad de acusar.
    );
  }

  /// Procesa una acusación de trampa.
  GameState accuse({required GameState currentState}) {
    final lastMove = currentState.lastMove;
    if (lastMove == null) return currentState; // No hay jugada que acusar.

    if (!lastMove.wasValid) {
      // ¡Acusación correcta! El tramposo es castigado.
      final cheaterIndex = lastMove.playerIndex;
      final cheater = currentState.players[cheaterIndex];

      // Devolver la ficha ilegal a la mano del tramposo.
      final newHand = List<DominoPiece>.from(cheater.hand)..add(lastMove.domino);

      // Quitar la ficha ilegal del tablero.
      final newBoardChain = List<DominoPiece>.from(currentState.boardChain)
        ..remove(lastMove.domino.flipped)
        ..remove(lastMove.domino);

      // Robar 2 fichas de castigo.
      final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
      if (newBoneyard.length >= 2) {
        newHand.add(newBoneyard.removeAt(0));
        newHand.add(newBoneyard.removeAt(0));
      } else if (newBoneyard.isNotEmpty) {
        newHand.add(newBoneyard.removeAt(0));
      }

      final punishedPlayer = cheater.copyWith(hand: newHand);
      final newPlayers = List<Player>.from(currentState.players);
      newPlayers[cheaterIndex] = punishedPlayer;

      return currentState.copyWith(
        players: newPlayers,
        boneyard: newBoneyard,
        boardChain: newBoardChain,
        clearLastMove: true, // La acusación resuelve la jugada.
      );

    } else {
      // ¡Acusación falsa! El acusador es castigado.
      final accuserIndex = currentState.currentPlayerIndex;
      final accuser = currentState.players[accuserIndex];
      final newHand = List<DominoPiece>.from(accuser.hand);

      // Robar 2 fichas de castigo.
      final newBoneyard = List<DominoPiece>.from(currentState.boneyard);
      if (newBoneyard.length >= 2) {
        newHand.add(newBoneyard.removeAt(0));
        newHand.add(newBoneyard.removeAt(0));
      } else if (newBoneyard.isNotEmpty) {
        newHand.add(newBoneyard.removeAt(0));
      }

      final punishedPlayer = accuser.copyWith(hand: newHand);
      final newPlayers = List<Player>.from(currentState.players);
      newPlayers[accuserIndex] = punishedPlayer;

      return currentState.copyWith(
        players: newPlayers,
        boneyard: newBoneyard,
        clearLastMove: true, // La acusación resuelve la jugada.
      );
    }
  }

  /// Comprueba si una jugada es válida.
  bool _isMoveValid({
    required DominoPiece piece,
    required String side,
    required List<DominoPiece> boardChain,
  }) {
    if (boardChain.isEmpty) return true; // La primera ficha siempre es válida.

    if (side == 'left') {
      final boardEnd = boardChain.first.a;
      return piece.a == boardEnd || piece.b == boardEnd;
    } else { // 'right'
      final boardEnd = boardChain.last.b;
      return piece.a == boardEnd || piece.b == boardEnd;
    }
  }

  /// Crea un mazo estándar de 28 fichas de dominó.
  List<DominoPiece> _createDeck() {
    List<DominoPiece> deck = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        deck.add(DominoPiece(a: i, b: j));
      }
    }
    return deck;
  }
}