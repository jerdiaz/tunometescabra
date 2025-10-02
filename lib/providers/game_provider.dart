import 'package:flutter/foundation.dart';
import '../models/ficha.dart';
import '../models/juego.dart';
import '../utils/logica_juego.dart';

class GameProvider with ChangeNotifier {
  // Instancia privada de la lógica del juego.
  final GameLogic _gameLogic = GameLogic();

  // Estado privado del juego. La UI no puede modificarlo directamente.
  late GameState _gameState;

  // Getter público para que la UI pueda leer el estado actual.
  GameState get gameState => _gameState;

  GameProvider() {
    // Inicializa el juego cuando se crea el provider.
    _startNewGame();
  }

  /// Inicia una nueva partida.
  void _startNewGame() {
    _gameState = _gameLogic.startGame();
    // No es necesario notificar a los oyentes aquí, ya que el estado se establece
    // antes de que la UI se construya por primera vez.
  }

  /// Reinicia el juego a su estado inicial.
  void restartGame() {
    _startNewGame();
    notifyListeners(); // Notifica a la UI para que se reconstruya con el nuevo juego.
  }

  /// Llama a la lógica para jugar una ficha y actualiza el estado.
  void playPiece(DominoPiece piece, String side) {
    _gameState = _gameLogic.playPiece(
      currentState: _gameState,
      pieceToPlay: piece,
      side: side,
    );
    notifyListeners(); // Notifica a la UI sobre el cambio.
  }

  /// Llama a la lógica para robar una ficha y actualiza el estado.
  void drawPiece() {
    _gameState = _gameLogic.drawPiece(currentState: _gameState);
    notifyListeners();
  }

  /// Llama a la lógica para procesar una acusación y actualiza el estado.
  void accuse() {
    _gameState = _gameLogic.accuse(currentState: _gameState);
    notifyListeners();
  }
}