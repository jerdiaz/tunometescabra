// FILE: lib/providers/game_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../utils/logica_juego.dart';

class GameMessage {
  final String title;
  final String body;
  final String icon;
  GameMessage({required this.title, required this.body, this.icon = ''});
}

class GameProvider with ChangeNotifier {
  late GameState _gameState;
  final GameLogic _logic = GameLogic();
  GameMessage? _message;

  // Timer
  Timer? _turnTimer;
  int _remainingSeconds = 30;
  static const int turnDuration = 30;

  GameState get gameState => _gameState;
  GameMessage? get message => _message;
  int get remainingSeconds => _remainingSeconds;

  GameProvider() {
    _gameState = GameState.initial();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingSeconds = turnDuration;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _gameState = _logic.passTurn(currentState: _gameState);
        _message = GameMessage(
          title: '⏰ ¡Tiempo Agotado!',
          body: 'Se acabó el tiempo. El turno pasa automáticamente.',
          icon: 'timer',
        );
        if (!_gameState.isGameOver) {
          _startTurnTimer();
        }
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _turnTimer?.cancel();
  }

  void startGame(int playerCount) {
    _gameState = _logic.startGame(playerCount: playerCount);
    _startTurnTimer();
    notifyListeners();
  }

  void playPiece(DominoPiece piece, PlayEnd end) {
    _gameState = _logic.playPiece(
      currentState: _gameState,
      piece: piece,
      end: end,
    );
    if (_gameState.isGameOver) {
      _stopTimer();
    } else {
      _startTurnTimer();
    }
    _checkForEndGame();
    notifyListeners();
  }

  void drawPiece() {
    _gameState = _logic.drawPiece(currentState: _gameState);
    // No reiniciar timer — sigue siendo el turno del mismo jugador.
    notifyListeners();
  }

  void accuse() {
    final result = _logic.accuse(currentState: _gameState);
    _gameState = result.newState;

    if (result.wasCheating) {
      _message = GameMessage(
        title: '🚨 ¡Trampa Descubierta!',
        body: 'El jugador anterior hizo trampa. Recupera su ficha y roba 1 ficha de castigo.',
        icon: 'cheating',
      );
    } else if (result.turnSkipped) {
      _message = GameMessage(
        title: '❌ ¡Acusación Falsa!',
        body: 'La jugada era válida y no hay fichas para comer. ¡Pierdes el turno!',
        icon: 'false',
      );
    } else {
      _message = GameMessage(
        title: '❌ ¡Acusación Falsa!',
        body: 'La jugada era válida. Robas 1 ficha como castigo.',
        icon: 'false',
      );
    }
    if (!_gameState.isGameOver) {
      _startTurnTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void passTurn() {
    _gameState = _logic.passTurn(currentState: _gameState);
    _checkForEndGame();
    if (!_gameState.isGameOver) {
      _startTurnTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void _checkForEndGame() {
    if (_gameState.isGameOver) {
      _stopTimer();
      _message = GameMessage(
        title: '🏆 ¡Fin del Juego!',
        body: '¡El Jugador ${_gameState.winnerIndex! + 1} ha ganado!',
        icon: 'winner',
      );
    } else if (_logic.isGameBlocked(_gameState)) {
      final winnerIndex = _logic.getWinnerByLowestScore(_gameState);
      _gameState = _gameState.copyWith(
        isGameOver: true,
        winnerIndex: winnerIndex,
      );
      _stopTimer();
      _message = GameMessage(
        title: '🔒 ¡Juego Bloqueado!',
        body: 'Nadie puede jugar. Gana el Jugador ${winnerIndex + 1} por tener menos puntos.',
        icon: 'blocked',
      );
    }
  }

  void clearMessage() {
    _message = null;
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }
}