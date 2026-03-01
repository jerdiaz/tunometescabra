// FILE: lib/models/jugador.dart
import 'package:flutter/foundation.dart';
import 'ficha.dart';

@immutable
class Player {
  final int id;
  final String name;
  final List<DominoPiece> hand;
  final bool isActive;

  const Player({
    required this.id,
    required this.name,
    required this.hand,
    this.isActive = true,
  });

  Player copyWith({String? name, List<DominoPiece>? hand, bool? isActive}) {
    return Player(
      id: id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hand': hand.map((p) => p.toMap()).toList(),
        'isActive': isActive,
      };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as int,
        name: m['name'] as String? ?? 'Jugador ${(m['id'] as int) + 1}',
        hand: (m['hand'] as List)
            .map((p) => DominoPiece.fromMap(Map<String, dynamic>.from(p)))
            .toList(),
        isActive: m['isActive'] as bool? ?? true,
      );
}
