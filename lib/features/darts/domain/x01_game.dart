enum OutRule { single, double, master }

extension OutRuleX on OutRule {
  String get label => switch (this) {
        OutRule.single => 'Single out',
        OutRule.double => 'Double out',
        OutRule.master => 'Master out',
      };
  String get apiValue => name.toUpperCase();
}

class DartThrow {
  const DartThrow(this.value, this.mult);
  final int value; // 0 = miss, 1..20, 25 = bull
  final int mult; // 1, 2, 3

  int get points => value * mult;

  String get label {
    if (value == 0) return '—';
    if (value == 25) return mult == 2 ? 'Bull' : '25';
    final prefix = mult == 3 ? 'T' : (mult == 2 ? 'D' : '');
    return '$prefix$value';
  }
}

class TurnRecord {
  const TurnRecord(this.player, this.darts, this.score, this.bust);
  final int player;
  final List<DartThrow> darts;
  final int score;
  final bool bust;
}

/// Lo stato è sempre ricalcolato dalla lista delle freccette:
/// l'annulla è quindi banale e non può andare fuori sincrono.
class X01Game {
  X01Game({
    required this.startScore,
    required this.outRule,
    required this.playerCount,
  }) {
    _recompute();
  }

  final int startScore;
  final OutRule outRule;
  final int playerCount;
  final List<DartThrow> _throws = [];

  late List<int> remaining;
  late List<int> dartsThrown;
  late List<int> scored;
  late List<int> highTurn;
  late List<int> busts;
  late List<int> coAttempts;
  late List<int> coHits;
  late List<TurnRecord> turns;
  late List<DartThrow> turnDarts;
  late int current;
  late int _turnStart;
  int? winner;

  bool get isOver => winner != null;
  bool get canUndo => _throws.isNotEmpty;
  int get dartsLeftInTurn => 3 - turnDarts.length;
  int get turnPoints => turnDarts.fold(0, (s, d) => s + d.points);

  double avg(int i) {
    if (dartsThrown[i] == 0) return 0;
    final pts = scored[i] + (i == current ? turnPoints : 0);
    return pts / dartsThrown[i] * 3;
  }

  String checkoutText(int i) => coAttempts[i] == 0
      ? '—'
      : '${(coHits[i] / coAttempts[i] * 100).round()}%';

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
    remaining = List.filled(playerCount, startScore);
    dartsThrown = List.filled(playerCount, 0);
    scored = List.filled(playerCount, 0);
    highTurn = List.filled(playerCount, 0);
    busts = List.filled(playerCount, 0);
    coAttempts = List.filled(playerCount, 0);
    coHits = List.filled(playerCount, 0);
    turns = [];
    turnDarts = [];
    current = 0;
    _turnStart = startScore;
    winner = null;
    for (final t in _throws) {
      _apply(t);
    }
  }

  void _apply(DartThrow t) {
    final i = current;
    final before = remaining[i];
    final rem = before - t.points;

    dartsThrown[i]++;
    if (before <= 170) coAttempts[i]++;
    turnDarts.add(t);

    final validFinish = switch (outRule) {
      OutRule.single => true,
      OutRule.double => t.mult == 2,
      OutRule.master => t.mult >= 2,
    };
    final bust = rem < 0 ||
        (outRule != OutRule.single && rem == 1) ||
        (rem == 0 && !validFinish);

    if (bust) {
      busts[i]++;
      dartsThrown[i] += 3 - turnDarts.length; // le freccette rimaste contano
      _closeTurn(bust: true);
      return;
    }

    remaining[i] = rem;
    if (rem == 0) {
      coHits[i]++;
      winner = i;
      _closeTurn(bust: false, advance: false);
      return;
    }
    if (turnDarts.length == 3) _closeTurn(bust: false);
  }

  void _closeTurn({required bool bust, bool advance = true}) {
    final i = current;
    final score = bust ? 0 : turnPoints;
    if (bust) remaining[i] = _turnStart;
    scored[i] += score;
    if (score > highTurn[i]) highTurn[i] = score;
    turns.add(TurnRecord(i, List.of(turnDarts), score, bust));
    turnDarts = [];
    if (advance) {
      current = (current + 1) % playerCount;
      _turnStart = remaining[current];
    }
  }
}

/// Suggerimento di chiusura (max 3 freccette). Null se impossibile.
List<DartThrow>? checkoutFor(int score, OutRule rule, int darts) {
  if (score < 1 || score > 170 || darts < 1) return null;

  final pool = <DartThrow>[
    for (var v = 1; v <= 20; v++) ...[
      DartThrow(v, 3),
      DartThrow(v, 2),
      DartThrow(v, 1),
    ],
    const DartThrow(25, 2),
    const DartThrow(25, 1),
  ]..sort((a, b) => b.points.compareTo(a.points));

  bool finishes(DartThrow d) => switch (rule) {
        OutRule.single => true,
        OutRule.double => d.mult == 2,
        OutRule.master => d.mult >= 2,
      };

  List<DartThrow>? solve(int rem, int n) {
    if (n == 1) {
      for (final d in pool) {
        if (d.points == rem && finishes(d)) return [d];
      }
      return null;
    }
    for (final d in pool) {
      if (d.points >= rem) continue;
      final rest = solve(rem - d.points, n - 1);
      if (rest != null) return [d, ...rest];
    }
    return null;
  }

  for (var n = 1; n <= darts; n++) {
    final r = solve(score, n);
    if (r != null) return r;
  }
  return null;
}