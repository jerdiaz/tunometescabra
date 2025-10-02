// FILE: lib/models/jugador.dart
import 'package:flutter/foundation.dart';
import 'ficha.dart';

@immutable
class Player {
  final int id;
  final List<DominoPiece> hand;

  const Player({required this.id, required this.hand});

  Player copyWith({List<DominoPiece>? hand}) {
    return Player(
      id: id,
      hand: hand ?? this.hand,
    );
  }
}