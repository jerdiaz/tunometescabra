// FILE: lib/services/firestore_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/juego.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera un código alfanumérico aleatorio de 4 caracteres.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  /// Crea una sala de espera (sin gameState aún).
  Future<String> createRoom(String hostName) async {
    String code = _generateRoomCode();

    var doc = await _db.collection('rooms').doc(code).get();
    int attempts = 0;
    while (doc.exists && attempts < 10) {
      code = _generateRoomCode();
      doc = await _db.collection('rooms').doc(code).get();
      attempts++;
    }

    await _db.collection('rooms').doc(code).set({
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'playerNames': [hostName],
      'hostIndex': 0,
      'gameState': null,
    });

    return code;
  }

  /// Se une a una sala existente. Devuelve el índice del jugador o -1 si falla.
  Future<int> joinRoom(String code, String playerName) async {
    final docRef = _db.collection('rooms').doc(code.toUpperCase());
    final doc = await docRef.get();

    if (!doc.exists) return -1;

    final data = doc.data()!;
    if (data['status'] != 'waiting') return -1;

    final names = List<String>.from(data['playerNames'] ?? []);
    if (names.length >= 4) return -1; // Máximo 4

    names.add(playerName);
    await docRef.update({'playerNames': names});

    return names.length - 1; // Índice del nuevo jugador
  }

  /// El host inicia la partida: sube el gameState y cambia status a playing.
  Future<void> startGame(String code, GameState initialState) async {
    await _db.collection('rooms').doc(code.toUpperCase()).update({
      'status': 'playing',
      'gameState': initialState.toMap(),
    });
  }

  /// Actualiza el estado del juego en Firestore.
  Future<void> updateGameState(String code, GameState state,
      {String? status}) async {
    final data = <String, dynamic>{
      'gameState': state.toMap(),
    };
    if (status != null) {
      data['status'] = status;
    }
    await _db.collection('rooms').doc(code.toUpperCase()).update(data);
  }

  /// Escucha cambios en tiempo real del documento de la sala.
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToRoom(String code) {
    return _db.collection('rooms').doc(code.toUpperCase()).snapshots();
  }

  /// Marca la sala como abandonada.
  Future<void> leaveRoom(String code) async {
    try {
      await _db
          .collection('rooms')
          .doc(code.toUpperCase())
          .update({'status': 'abandoned'});
    } catch (_) {}
  }

  /// Reinicia la sala a estado de espera (para volver al lobby después de una partida).
  Future<void> resetRoom(String code) async {
    try {
      await _db.collection('rooms').doc(code.toUpperCase()).update({
        'status': 'waiting',
        'gameState': null,
      });
    } catch (_) {}
  }
}
