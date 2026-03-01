// FILE: lib/providers/game_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/juego.dart';
import '../models/ficha.dart';
import '../utils/logica_juego.dart';
import '../services/firestore_service.dart';

class GameMessage {
  final String title;
  final String body;
  final String icon;
  GameMessage({required this.title, required this.body, this.icon = ''});
}

class GameProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final GameLogic _logic = GameLogic();

  GameState _gameState = GameState.initial();
  GameMessage? _message;
  DominoPiece? _pendingPiece;

  // Online state
  String _roomCode = '';
  int _localPlayerIndex = 0;
  bool _opponentLeft = false;
  StreamSubscription? _roomSubscription;

  // Lobby state
  List<String> _playerNames = [];
  String _roomStatus = 'waiting';
  bool _isHost = false;

  // Timestamp to avoid duplicate accusation messages
  AccusationEvent? _lastProcessedAccusation;

  // Timer
  Timer? _turnTimer;
  int _remainingSeconds = 30;
  static const int turnDuration = 30;

  // ═══════════ Getters ═══════════
  GameState get gameState => _gameState;
  GameMessage? get message => _message;
  int get remainingSeconds => _remainingSeconds;
  DominoPiece? get pendingPiece => _pendingPiece;
  String get roomCode => _roomCode;
  int get localPlayerIndex => _localPlayerIndex;
  bool get opponentLeft => _opponentLeft;
  List<String> get playerNames => _playerNames;
  String get roomStatus => _roomStatus;
  bool get isHost => _isHost;

  bool get isMyTurn =>
      _roomStatus == 'playing' &&
      _gameState.currentPlayerIndex == _localPlayerIndex;

  bool get isGameStarted => _roomStatus == 'playing';

  String get localPlayerName => _localPlayerIndex < _playerNames.length
      ? _playerNames[_localPlayerIndex]
      : 'Tú';

  String get currentTurnPlayerName {
    if (_gameState.players.isNotEmpty &&
        _gameState.currentPlayerIndex < _gameState.players.length) {
      return _gameState.players[_gameState.currentPlayerIndex].name;
    }
    return '';
  }

  // ═══════════════════════════════════════════════════
  // ONLINE ROOM MANAGEMENT
  // ═══════════════════════════════════════════════════

  Future<String> createRoom(String playerName) async {
    _isHost = true;
    _localPlayerIndex = 0;
    _playerNames = [playerName];
    _roomCode = await _firestoreService.createRoom(playerName);
    _roomStatus = 'waiting';
    _listenToRoom();
    notifyListeners();
    return _roomCode;
  }

  Future<bool> joinRoom(String code, String playerName) async {
    final index = await _firestoreService.joinRoom(code, playerName);
    if (index < 0) return false;

    _roomCode = code.toUpperCase();
    _localPlayerIndex = index;
    _isHost = false;
    _roomStatus = 'waiting';
    _listenToRoom();
    return true;
  }

  Future<void> startGame() async {
    if (!_isHost || _playerNames.length < 2) return;
    final initialState = _logic.startGame(
      playerCount: _playerNames.length,
      playerNames: _playerNames,
    );
    _gameState = initialState;
    await _firestoreService.startGame(_roomCode, initialState);
  }

  /// Escucha cambios en tiempo real del documento de la sala.
  void _listenToRoom() {
    _roomSubscription?.cancel();
    _roomSubscription =
        _firestoreService.listenToRoom(_roomCode).listen((snapshot) {
      if (!snapshot.exists) {
        _opponentLeft = true;
        _stopTimer();
        notifyListeners();
        return;
      }

      final data = snapshot.data()!;
      final status = data['status'] as String? ?? '';

      if (status == 'abandoned') {
        _opponentLeft = true;
        _stopTimer();
        notifyListeners();
        return;
      }

      if (data['playerNames'] != null) {
        _playerNames = List<String>.from(data['playerNames']);
      }

      _roomStatus = status;

      if ((status == 'playing' || status == 'finished') &&
          data['gameState'] != null) {
        final newState =
            GameState.fromMap(Map<String, dynamic>.from(data['gameState']));
        _gameState = newState;

        // ═══ Generar mensajes de acusación para el jugador remoto ═══
        _processRemoteAccusation(newState);

        // ═══ Verificar fin de juego ═══
        if (newState.isGameOver && _message == null) {
          _checkForEndGame();
        }

        // Timer
        if (isMyTurn && !_gameState.isGameOver) {
          _startTurnTimer();
        } else {
          _stopTimer();
          _remainingSeconds = turnDuration;
        }
      }

      notifyListeners();
    });
  }

  /// Procesa AccusationEvent del estado remoto para mostrar mensajes al jugador
  /// que NO fue quien presionó "Acusar" (el que lo presionó ya vio su mensaje local).
  void _processRemoteAccusation(GameState state) {
    final accusation = state.lastAccusation;
    if (accusation == null) return;

    // Evitar procesar la misma acusación dos veces
    if (_lastProcessedAccusation != null &&
        _lastProcessedAccusation!.accuserIndex == accusation.accuserIndex &&
        _lastProcessedAccusation!.cheaterIndex == accusation.cheaterIndex &&
        _lastProcessedAccusation!.wasCheating == accusation.wasCheating) {
      return;
    }
    _lastProcessedAccusation = accusation;

    // Si YO fui el acusador, ya vi el mensaje local → no duplicar
    if (accusation.accuserIndex == _localPlayerIndex) return;

    final accuserName = state.players[accusation.accuserIndex].name;

    if (accusation.wasCheating) {
      // Yo soy el tramposo (o un espectador)
      if (accusation.cheaterIndex == _localPlayerIndex) {
        final playerCount = state.players.length;
        final penaltyText = playerCount < 4
            ? 'Se te devuelve la ficha, robas 1 de castigo y pierdes el turno.'
            : 'Se te devuelve la ficha y pierdes el turno.';
        _message = GameMessage(
          title: '🚨 ¡Te pillaron!',
          body: '$accuserName descubrió tu trampa. $penaltyText',
          icon: 'caught',
        );
      } else {
        // Soy otro jugador — me notifico de lo que pasó
        final cheaterName = state.players[accusation.cheaterIndex].name;
        _message = GameMessage(
          title: '🚨 ¡Trampa Descubierta!',
          body: '$accuserName pilló a $cheaterName haciendo trampa.',
          icon: 'cheating',
        );
      }
    } else {
      // Acusación falsa — yo soy el acusado inocente (o espectador)
      if (accusation.cheaterIndex == _localPlayerIndex) {
        _message = GameMessage(
          title: '✅ ¡Inocente!',
          body:
              '$accuserName te acusó pero tu jugada era válida. ¡${accuserName} es penalizado!',
          icon: 'innocent',
        );
      } else {
        _message = GameMessage(
          title: '❌ Acusación Falsa',
          body: '$accuserName acusó falsamente.',
          icon: 'false',
        );
      }
    }
  }

  Future<void> leaveRoom() async {
    _stopTimer();

    // Si el juego está en curso, eliminar al jugador (no abandonar la sala)
    if (_roomStatus == 'playing' &&
        _roomCode.isNotEmpty &&
        _gameState.players.isNotEmpty &&
        _localPlayerIndex < _gameState.players.length &&
        _gameState.players[_localPlayerIndex].isActive) {
      _gameState = _logic.eliminatePlayer(
        currentState: _gameState,
        playerIndex: _localPlayerIndex,
      );
      // Subir el estado con el jugador eliminado
      final status = _gameState.isGameOver ? 'finished' : null;
      await _firestoreService.updateGameState(_roomCode, _gameState,
          status: status);
    } else if (_roomCode.isNotEmpty) {
      // Sala en espera → marcar como abandonada
      await _firestoreService.leaveRoom(_roomCode);
    }

    _roomSubscription?.cancel();
    _roomCode = '';
    _opponentLeft = false;
    _pendingPiece = null;
    _playerNames = [];
    _roomStatus = 'waiting';
    _isHost = false;
    _lastProcessedAccusation = null;
    _gameState = GameState.initial();
    notifyListeners();
  }

  /// Vuelve al lobby de la sala (no abandona).
  /// Reinicia el estado del juego pero mantiene la sala y los jugadores.
  Future<void> returnToLobby() async {
    _stopTimer();
    _pendingPiece = null;
    _message = null;
    _lastProcessedAccusation = null;
    _gameState = GameState.initial();
    _roomStatus = 'waiting';

    // El host resetea la sala en Firestore
    if (_isHost && _roomCode.isNotEmpty) {
      await _firestoreService.resetRoom(_roomCode);
    }
    // La suscripción sigue activa para recibir el update
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════

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
        _pendingPiece = null;
        _syncToFirestore();
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _turnTimer?.cancel();
  }

  // ═══════════════════════════════════════════════════
  // GAME ACTIONS
  // ═══════════════════════════════════════════════════

  void playPiece(DominoPiece piece, PlayEnd end) {
    if (!isMyTurn) return;
    _gameState = _logic.playPiece(
      currentState: _gameState,
      piece: piece,
      end: end,
    );
    if (_gameState.isGameOver) _stopTimer();
    _checkForEndGame();
    _syncToFirestore();
    notifyListeners();
  }

  void drawPiece() {
    if (!isMyTurn) return;
    _gameState = _logic.drawPiece(currentState: _gameState);
    _syncToFirestore();
    notifyListeners();
  }

  void accuse() {
    if (!isMyTurn) return;

    final result = _logic.accuse(currentState: _gameState);
    _gameState = result.newState;

    // Guardar la acusación para no duplicar cuando llegue de Firestore
    _lastProcessedAccusation = result.newState.lastAccusation;

    // ═══ Mensaje LOCAL para el ACUSADOR ═══
    if (result.wasCheating) {
      final cheaterName = result
          .newState.players[result.newState.lastAccusation!.cheaterIndex].name;
      _message = GameMessage(
        title: '✅ ¡Acusación Correcta!',
        body:
            '¡$cheaterName estaba haciendo trampa! Se le devuelve su ficha y pierde el turno.',
        icon: 'correct',
      );
    } else if (result.turnSkipped) {
      _message = GameMessage(
        title: '❌ ¡Acusación Falsa!',
        body:
            'La jugada era válida y no hay fichas para comer. ¡Pierdes el turno!',
        icon: 'false',
      );
    } else {
      _message = GameMessage(
        title: '❌ ¡Acusación Falsa!',
        body: 'La jugada era válida. Robas 1 ficha como castigo.',
        icon: 'false',
      );
    }

    if (_gameState.isGameOver) _stopTimer();
    _syncToFirestore();
    notifyListeners();
  }

  void passTurn() {
    if (!isMyTurn) return;
    _gameState = _logic.passTurn(currentState: _gameState);
    _checkForEndGame();
    if (_gameState.isGameOver) _stopTimer();
    _pendingPiece = null;
    _syncToFirestore();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // PENDING PIECE
  // ═══════════════════════════════════════════════════

  void setPendingPiece(DominoPiece piece) {
    _pendingPiece = piece;
    notifyListeners();
  }

  void flipPendingPiece() {
    if (_pendingPiece != null) {
      _pendingPiece = _pendingPiece!.flipped;
      notifyListeners();
    }
  }

  void clearPendingPiece() {
    _pendingPiece = null;
    notifyListeners();
  }

  void confirmPlay(PlayEnd end) {
    if (_pendingPiece != null) {
      playPiece(_pendingPiece!, end);
      _pendingPiece = null;
    }
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  void _checkForEndGame() {
    if (_gameState.isGameOver) {
      _stopTimer();
      final winnerName = _gameState.players[_gameState.winnerIndex!].name;
      if (_gameState.winnerIndex == _localPlayerIndex) {
        _message = GameMessage(
          title: '🏆 ¡Ganaste!',
          body: '¡Felicidades, $winnerName! Has ganado la partida.',
          icon: 'winner',
        );
      } else {
        _message = GameMessage(
          title: '🏆 ¡Fin del Juego!',
          body: '¡$winnerName ha ganado la partida!',
          icon: 'winner',
        );
      }
    } else if (_logic.isGameBlocked(_gameState)) {
      final winnerIndex = _logic.getWinnerByLowestScore(_gameState);
      _gameState = _gameState.copyWith(
        isGameOver: true,
        winnerIndex: winnerIndex,
      );
      _stopTimer();
      final winnerName = _gameState.players[winnerIndex].name;
      _message = GameMessage(
        title: '🔒 ¡Juego Bloqueado!',
        body: 'Nadie puede jugar. ¡$winnerName gana por tener menos puntos!',
        icon: 'blocked',
      );
    }
  }

  Future<void> _syncToFirestore() async {
    if (_roomCode.isEmpty) return;
    final status = _gameState.isGameOver ? 'finished' : null;
    await _firestoreService.updateGameState(_roomCode, _gameState,
        status: status);
  }

  void clearMessage() {
    _message = null;
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }
}
