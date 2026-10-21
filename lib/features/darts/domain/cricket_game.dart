import 'x01_game.dart' show DartThrow;

/// Numeri in gioco, dall'alto verso il basso. 25 = Bull.
const cricketNumbers = [20, 19, 18, 17, 16, 15, 25];

String cricketLabel(int n) => n == 25 ? 'B' : '$n';

class CricketGame {
  CricketGame({required this.playerCount}) {
    _recompute();
  }

  final int playerCount;
  final List<DartThrow> _throws = [];

  late List<List<int>> marks; // [giocatore][indice numero] 0..3
  late List<int> points;
  late List<int> dartsThrown;
  late List<int> marksThrown;
  late List<DartThrow> turnDarts;
  late int current;
  late int turnsDone;
  int? winner;

  bool get isOver => winner != null;
  bool get canUndo => _throws.isNotEmpty;
  int get round => turnsDone ~/ playerCount + 1;

  double mpr(int i) =>
      dartsThrown[i] == 0 ? 0 : marksThrown[i] / dartsThrown[i] * 3;

  bool closedByAll(int idx) => marks.every((m) => m[idx] >= 3);

  /// Segni validi di una freccetta (il Bull non ha il triplo)
  static int marksFor(DartThrow t) {
    if (!cricketNumbers.contains(t.value)) return 0;
    return t.value == 25 && t.mult > 2 ? 2 : t.mult;
  }

  void throwDart(DartThrow t) {
    if (isOver) return;
    _throws.add(t);
    _apply(t);
  }

  void undo() {
    if (_throws.isEmpty) return;
    _throws.removeLast();
    _recompute();
  }

  void _recompute() {
    marks = List.generate(
      playerCount,
      (_) => List.filled(cricketNumbers.length, 0),
    );
    points = List.filled(playerCount, 0);
    dartsThrown = List.filled(playerCount, 0);
    marksThrown = List.filled(playerCount, 0);
    turnDarts = [];
    current = 0;
    turnsDone = 0;
    winner = null;
    for (final t in _throws) {
      _apply(t);
    }
  }

  void _apply(DartThrow t) {
    final p = current;
    dartsThrown[p]++;
    turnDarts.add(t);

    final hits = marksFor(t);
    if (hits > 0) {
      final idx = cricketNumbers.indexOf(t.value);
      marksThrown[p] += hits;
      for (var k = 0; k < hits; k++) {
        if (marks[p][idx] < 3) {
          marks[p][idx]++;
        } else if (_othersOpen(p, idx)) {
          points[p] += t.value;
        }
      }
    }

    if (_hasWon(p)) {
      winner = p;
      return;
    }
    if (turnDarts.length == 3) {
      turnDarts = [];
      turnsDone++;
      current = (current + 1) % playerCount;
    }
  }

  bool _othersOpen(int p, int idx) {
    for (var q = 0; q < playerCount; q++) {
      if (q != p && marks[q][idx] < 3) return true;
    }
    return false;
  }

  bool _hasWon(int p) {
    if (marks[p].any((m) => m < 3)) return false;
    for (var q = 0; q < playerCount; q++) {
      if (q != p && points[q] > points[p]) return false;
    }
    return true;
  }
}