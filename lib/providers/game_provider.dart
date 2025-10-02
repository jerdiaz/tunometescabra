// FILE: lib/providers/game_provider.dart
import 'package:flutter/foundation.dart';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../utils/logica_juego.dart';

class GameMessage {
  final String title;
  final String body;
  GameMessage({required this.title, required this.body});
}

class GameProvider with ChangeNotifier {
  late GameState _gameState;
  final GameLogic _logic = GameLogic();
  GameMessage? _message;

  GameState get gameState => _gameState;
  GameMessage? get message => _message;

  GameProvider() {
    _gameState = GameState.initial();
  }

  void startGame(int playerCount) {
    _gameState = _logic.startGame(playerCount: playerCount);
    notifyListeners();
  }

  void playPiece(DominoPiece piece, PlayEnd end) {
    _gameState = _logic.playPiece(
      currentState: _gameState,
      piece: piece,
      end: end,
    );
    _checkForEndGame();
    notifyListeners();
  }

  void drawPiece() {
    _gameState = _logic.drawPiece(currentState: _gameState);
    notifyListeners();
  }

  void accuse() {
    final result = _logic.accuse(currentState: _gameState);
    _gameState = result.newState;

    if (result.wasCheating) {
      _message = GameMessage(title: '¡Trampa Descubierta!', body: 'El jugador anterior hizo trampa y roba 2 fichas de castigo.');
    } else if (result.turnSkipped) {
      _message = GameMessage(title: '¡Acusación Falsa!', body: 'La jugada era válida y no hay fichas para robar. ¡Pierdes el turno!');
    } else {
      _message = GameMessage(title: '¡Acusación Falsa!', body: 'La jugada era válida. Robas 2 fichas como castigo.');
    }
    notifyListeners();
  }

  void passTurn() {
    _gameState = _logic.passTurn(currentState: _gameState);
    notifyListeners();
  }

  void _checkForEndGame() {
    if (_gameState.isGameOver) {
      _message = GameMessage(title: '¡Fin del Juego!', body: '¡El Jugador ${_gameState.winnerIndex! + 1} ha ganado!');
    }
  }

  void clearMessage() {
    _message = null;
  }
}