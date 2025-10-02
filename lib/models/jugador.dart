// FILE: lib/models/jugador.dart
import 'ficha.dart';

class Player {
  final int id;
  final List<DominoPiece> hand;

  Player({required this.id, required this.hand});

  Player copyWith({List<DominoPiece>? hand}) {
    return Player(
      id: id,
      hand: hand ?? this.hand,
    );
  }
}
