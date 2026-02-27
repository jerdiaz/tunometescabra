// FILE: test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tunometescabra/models/ficha.dart';
import 'package:tunometescabra/models/juego.dart';
import 'package:tunometescabra/models/jugador.dart';
import 'package:tunometescabra/utils/logica_juego.dart';

void main() {
  late GameLogic logic;

  setUp(() {
    logic = GameLogic();
  });

  group('startGame', () {
    test('crea la partida con el número correcto de jugadores', () {
      final state = logic.startGame(playerCount: 2);
      expect(state.players.length, 2);
    });

    test('cada jugador recibe 7 fichas', () {
      final state = logic.startGame(playerCount: 2);
      final totalEnMano =
          state.players.fold<int>(0, (sum, p) => sum + p.hand.length);
      final totalEnTablero = state.boardChain.length;
      expect(totalEnMano + totalEnTablero, 14);
    });

    test('lanza error si el número de jugadores es inválido', () {
      expect(() => logic.startGame(playerCount: 1), throwsArgumentError);
      expect(() => logic.startGame(playerCount: 5), throwsArgumentError);
    });
  });

  group('playPiece - Mecánica de Trampa', () {
    test('ficha inválida SÍ aparece en el tablero (trampa)', () {
      final state = GameState(
        players: [
          Player(id: 0, hand: const [DominoPiece(a: 0, b: 1)]),
          const Player(id: 1, hand: []),
        ],
        boneyard: const [],
        boardChain: const [DominoPiece(a: 3, b: 4)],
        currentPlayerIndex: 0,
      );

      // Jugar [0|1] a la derecha → inválido (0 != 4), pero se coloca igual.
      final newState = logic.playPiece(
        currentState: state,
        piece: const DominoPiece(a: 0, b: 1),
        end: PlayEnd.right,
      );

      // La ficha SÍ aparece en el tablero (mecánica de trampa).
      expect(newState.boardChain.length, 2);
      expect(newState.lastMove!.wasValid, false);
      expect(newState.lastMove!.end, PlayEnd.right);
      expect(newState.players[0].hand, isEmpty);
    });

    test('ficha válida aparece en el tablero correctamente', () {
      final state = GameState(
        players: [
          Player(id: 0, hand: const [DominoPiece(a: 4, b: 5)]),
          const Player(id: 1, hand: []),
        ],
        boneyard: const [],
        boardChain: const [DominoPiece(a: 3, b: 4)],
        currentPlayerIndex: 0,
      );

      final newState = logic.playPiece(
        currentState: state,
        piece: const DominoPiece(a: 4, b: 5),
        end: PlayEnd.right,
      );

      expect(newState.boardChain.length, 2);
      expect(newState.lastMove!.wasValid, true);
    });

    test('orientación elegida por el jugador se respeta', () {
      final state = GameState(
        players: [
          Player(id: 0, hand: const [DominoPiece(a: 3, b: 4)]),
          const Player(id: 1, hand: []),
        ],
        boneyard: const [],
        boardChain: const [DominoPiece(a: 5, b: 5)],
        currentPlayerIndex: 0,
      );

      // Jugar [3|4] a la derecha → piece.a=3 != board.last.b=5 → inválido
      final result1 = logic.playPiece(
        currentState: state,
        piece: const DominoPiece(a: 3, b: 4),
        end: PlayEnd.right,
      );
      expect(result1.lastMove!.wasValid, false);

      // Jugar [4|3] (flipped) a la derecha → piece.a=4 != 5 → también inválido
      final state2 = GameState(
        players: [
          Player(id: 0, hand: const [DominoPiece(a: 4, b: 3)]),
          const Player(id: 1, hand: []),
        ],
        boneyard: const [],
        boardChain: const [DominoPiece(a: 5, b: 5)],
        currentPlayerIndex: 0,
      );
      final result2 = logic.playPiece(
        currentState: state2,
        piece: const DominoPiece(a: 4, b: 3),
        end: PlayEnd.right,
      );
      expect(result2.lastMove!.wasValid, false);

      // Jugar [5|3] a la derecha → piece.a=5 == board.last.b=5 → VÁLIDO
      final state3 = GameState(
        players: [
          Player(id: 0, hand: const [DominoPiece(a: 5, b: 3)]),
          const Player(id: 1, hand: []),
        ],
        boneyard: const [],
        boardChain: const [DominoPiece(a: 5, b: 5)],
        currentPlayerIndex: 0,
      );
      final result3 = logic.playPiece(
        currentState: state3,
        piece: const DominoPiece(a: 5, b: 3),
        end: PlayEnd.right,
      );
      expect(result3.lastMove!.wasValid, true);
    });
  });

  group('accuse - Penalizaciones', () {
    test('acusación correcta: tramposo roba 1 ficha y pieza se quita del tablero', () {
      final state = GameState(
        players: const [
          Player(id: 0, hand: [DominoPiece(a: 1, b: 2)]),
          Player(id: 1, hand: []),
        ],
        boneyard: const [DominoPiece(a: 5, b: 5), DominoPiece(a: 6, b: 6)],
        boardChain: const [DominoPiece(a: 3, b: 4), DominoPiece(a: 0, b: 1)],
        currentPlayerIndex: 1,
        lastMove: const LastMove(
          playerIndex: 0,
          piece: DominoPiece(a: 0, b: 1),
          wasValid: false,
          end: PlayEnd.right,
        ),
      );

      final result = logic.accuse(currentState: state);

      expect(result.wasCheating, true);
      // Tramposo recupera ficha + 1 castigo = 1 + 1 + 1 = 3
      expect(result.newState.players[0].hand.length, 3);
      // La ficha trampa fue removida del tablero
      expect(result.newState.boardChain.length, 1);
      expect(result.newState.boneyard.length, 1);
      expect(result.newState.currentPlayerIndex, 0);
    });

    test('acusación falsa: acusador roba 1 ficha de castigo', () {
      final state = GameState(
        players: const [
          Player(id: 0, hand: [DominoPiece(a: 1, b: 2)]),
          Player(id: 1, hand: []),
        ],
        boneyard: const [DominoPiece(a: 5, b: 5), DominoPiece(a: 6, b: 6)],
        boardChain: const [DominoPiece(a: 3, b: 4)],
        currentPlayerIndex: 1,
        lastMove: const LastMove(
          playerIndex: 0,
          piece: DominoPiece(a: 3, b: 4),
          wasValid: true,
          end: PlayEnd.right,
        ),
      );

      final result = logic.accuse(currentState: state);

      expect(result.wasCheating, false);
      expect(result.newState.players[1].hand.length, 1);
      expect(result.newState.boneyard.length, 1);
    });
  });

  group('Bloqueo total', () {
    test('detecta cuando todos los jugadores están bloqueados', () {
      const state = GameState(
        players: [
          Player(id: 0, hand: [DominoPiece(a: 0, b: 0)]),
          Player(id: 1, hand: [DominoPiece(a: 1, b: 1)]),
        ],
        boneyard: [],
        boardChain: [DominoPiece(a: 5, b: 6)],
        currentPlayerIndex: 0,
      );
      expect(logic.isGameBlocked(state), true);
    });

    test('no detecta bloqueo si alguien puede jugar', () {
      const state = GameState(
        players: [
          Player(id: 0, hand: [DominoPiece(a: 5, b: 3)]),
          Player(id: 1, hand: [DominoPiece(a: 1, b: 1)]),
        ],
        boneyard: [],
        boardChain: [DominoPiece(a: 5, b: 6)],
        currentPlayerIndex: 0,
      );
      expect(logic.isGameBlocked(state), false);
    });
  });
}
