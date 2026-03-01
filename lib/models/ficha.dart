// FILE: lib/models/ficha.dart
import 'package:flutter/foundation.dart';

@immutable
class DominoPiece {
  final int a;
  final int b;

  const DominoPiece({required this.a, required this.b});

  bool get isDouble => a == b;

  DominoPiece get flipped => DominoPiece(a: b, b: a);

  Map<String, dynamic> toMap() => {'a': a, 'b': b};

  factory DominoPiece.fromMap(Map<String, dynamic> m) =>
      DominoPiece(a: m['a'] as int, b: m['b'] as int);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DominoPiece &&
        ((other.a == a && other.b == b) || (other.a == b && other.b == a));
  }

  @override
  int get hashCode => a < b ? Object.hash(a, b) : Object.hash(b, a);

  @override
  String toString() => '[$a|$b]';
}
