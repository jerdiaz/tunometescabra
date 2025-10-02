// FILE: lib/providers/game_provider.dart
import 'package:flutter/foundation.dart';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../utils/logica_juego.dart';

// Clase simple para manejar los mensajes que se mostrarán en diálogos.
class GameMessage {
  final String title;
  final String body;
  GameMessage({required this.title, required this.body});
}

class GameProvider with ChangeNotifier {
  late GameState _gameState;
  final GameLogic _logic = GameLogic();
  GameMessage? _message;

  // Getters públicos para que la UI no pueda modificar el estado directamente.
  GameState get gameState => _gameState;
  GameMessage? get message => _message;

  GameProvider() {
    // Inicializa el estado al crear el provider.
    _gameState = GameState.initial();
  }

  void startGame() {
    _gameState = _logic.startGame();
    notifyListeners();
  }

  void playPiece(DominoPiece piece, PlayEnd end) {
    // Se corrige la llamada para que coincida con la definición en GameLogic.
    _gameState = _logic.playPiece(
      currentState: _gameState,
      piece: piece,
      end: end,
    );
    _checkForEndGame(); // Revisa si la partida terminó después de la jugada.
    notifyListeners();
  }

  void drawPiece() {
    _gameState = _logic.drawPiece(currentState: _gameState);
    notifyListeners();
  }

  void accuse() {
    // 'accuse' ahora devuelve un AccusationResult, no un GameState.
    final result = _logic.accuse(currentState: _gameState);

    // Extraemos el nuevo estado del resultado.
    _gameState = result.newState;

    // Creamos un mensaje para la UI basado en si hubo trampa.
    if (result.wasCheating) {
      _message = GameMessage(title: '¡Trampa Descubierta!', body: 'El jugador anterior hizo trampa y roba 2 fichas de castigo.');
    } else {
      _message = GameMessage(title: '¡Acusación Falsa!', body: 'La jugada era válida. Robas 2 fichas como castigo.');
    }
    notifyListeners();
  }

  /// Revisa si la partida ha terminado y crea el mensaje de victoria.
  void _checkForEndGame() {
    if (_gameState.isGameOver) {
      _message = GameMessage(title: '¡Fin del Juego!', body: '¡El Jugador ${_gameState.winnerIndex! + 1} ha ganado!');
    }
  }

  /// Limpia el mensaje actual para que el diálogo no se muestre repetidamente.
  void clearMessage() {
    _message = null;
    // No notificamos a los listeners para evitar reconstrucciones innecesarias.
  }
}

