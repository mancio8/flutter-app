import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../domain/cricket_game.dart';
import '../../domain/darts_models.dart';
import '../../domain/x01_game.dart' show DartThrow;
import '../widgets/darts_widgets.dart';

class CricketGamePage extends StatefulWidget {
  const CricketGamePage({super.key, required this.config});
  final DartsGameConfig config;

  @override
  State<CricketGamePage> createState() => _CricketGamePageState();
}

class _CricketGamePageState extends State<CricketGamePage> {
  late CricketGame _game;
  int _mult = 1;
  String? _banner;

  DartsGameConfig get _cfg => widget.config;

  CricketGame _newGame() => CricketGame(playerCount: _cfg.players.length);

  @override
  void initState() {
    super.initState();
    _game = _newGame();
  }

  // ---------------- input ----------------

  void _throw(int value) {
    if (_game.isOver) return;
    final dart = DartThrow(value, value == 0 ? 1 : _mult);
    final turnsBefore = _game.turnsDone;

    HapticFeedback.selectionClick();
    setState(() {
      _game.throwDart(dart);
      _mult = 1;
    });

    if (_game.isOver) {
      _finish();
      return;
    }
    if (_game.turnsDone > turnsBefore && _cfg.players.length > 1) {
      HapticFeedback.mediumImpact();
      setState(() => _banner = 'Tocca a ${_cfg.players[_game.current].name}');
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _banner = null);
      });
    }
  }

  void _undo() {
    setState(() {
      _game.undo();
      _mult = 1;
      _banner = null;
    });
  }

  void _toggleMult(int m) {
    HapticFeedback.selectionClick();
    setState(() => _mult = _mult == m ? 1 : m);
  }

  // ---------------- fine e uscita ----------------

  Future<void> _finish() async {
    final solo = _cfg.isSolo;
    final w = _game.winner!;

    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(solo ? '🎯 Tutto chiuso!' : '🏆 ${_cfg.players[w].name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _cfg.players.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(_cfg.players[i].avatar,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(
                    '${_cfg.players[i].name}${w == i ? ' 🏆' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Punti ${_game.points[i]} · '
                    'Segni/turno ${_game.mpr(i).toStringAsFixed(2)}\n'
                    '${_game.dartsThrown[i]} freccette',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Esci'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rivincita'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (again == true) {
      setState(() {
        _game = _newGame();
        _mult = 1;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _confirmExit() async {
    if (!_game.canUndo) {
      context.pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abbandonare la partita?'),
        content: const Text('I progressi andranno persi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Resta'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.pop();
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regole del Cricket'),
        content: const Text(
          '• Si giocano 20, 19, 18, 17, 16, 15 e Bull.\n'
          '• Servono 3 segni per chiudere un numero: singolo = 1, doppio = 2, triplo = 3.\n'
          '• Il Bull non ha il triplo.\n'
          '• Se hai chiuso un numero e un avversario no, ogni segno extra ti dà i punti di quel numero.\n'
          '• Vince chi ha chiuso tutto e ha punti uguali o superiori agli avversari.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cricket'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Regole',
              onPressed: _showRules,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _scoreboard(theme),
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _banner == null ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 10),
                                ],
                              ),
                              child: Text(
                                _banner ?? '',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _turnPanel(theme),
                    const SizedBox(height: 10),
                    _keypad(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- tabellone ----------

  Widget _scoreboard(ThemeData theme) {
    final n = _cfg.players.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              for (var i = 0; i < n; i++)
                Expanded(child: _playerHead(theme, i)),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < cricketNumbers.length; r++)
            Expanded(child: _numberRow(theme, r)),
        ],
      ),
    );
  }

  Widget _playerHead(ThemeData theme, int i) {
    final p = _cfg.players[i];
    final c = p.colorValue;
    final active = i == _game.current && !_game.isOver;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? c : theme.colorScheme.outlineVariant,
          width: active ? 2.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text('${p.avatar} ${p.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(
            '${_game.points[i]}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: active ? c : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'MPR ${_game.mpr(i).toStringAsFixed(1)}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _numberRow(ThemeData theme, int r) {
    final closed = _game.closedByAll(r);

    return Opacity(
      opacity: closed ? 0.35 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Center(
                child: Text(
                  cricketLabel(cricketNumbers[r]),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            for (var i = 0; i < _cfg.players.length; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: (i == _game.current && !_game.isOver)
                      ? _cfg.players[i].colorValue.withOpacity(0.07)
                      : null,
                  child: Center(
                    child: _MarkSymbol(
                      marks: _game.marks[i][r],
                      color: _cfg.players[i].colorValue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- turno ----------

  Widget _turnPanel(ThemeData theme) {
    final p = _cfg.players[_game.current];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _cfg.isSolo ? p.name : 'Tocca a ${p.name}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Giro ${_game.round}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var k = 0; k < 3; k++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: DartSlot(
                    dart: k < _game.turnDarts.length ? _game.turnDarts[k] : null,
                    subText: k < _game.turnDarts.length
                        ? _marksText(_game.turnDarts[k])
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _marksText(DartThrow d) {
    final m = CricketGame.marksFor(d);
    return m == 0 ? '—' : (m == 1 ? '1 segno' : '$m segni');
  }

  // ---------- tastiera ----------

  Widget _multButton(String label, int m) {
    final sel = _mult == m;
    final c = multColor(m);
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleMult(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          decoration: BoxDecoration(
            color: sel ? c : c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: sel ? Colors.white : c,
            ),
          ),
        ),
      ),
    );
  }

  Widget _numKey(ThemeData theme, int v) {
    final idx = cricketNumbers.indexOf(v);
    final dim = _game.closedByAll(idx);
    final tinted = _mult > 1;
    final c = multColor(_mult);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: switch (_mult) {
        3 => 'Triplo $v',
        2 => 'Doppio $v',
        _ => '$v',
      },
      child: Opacity(
        opacity: dim ? 0.4 : 1,
        child: Material(
          color: tinted ? c.withOpacity(0.16) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _throw(v),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: tinted ? c : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (tinted)
                    Text(
                      '$_mult segni',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: c),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey(
    ThemeData theme, {
    required String label,
    String? sub,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: color)),
                    if (sub != null)
                      Text(sub, style: TextStyle(fontSize: 10, color: color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypad(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _multButton('DOPPIO', 2),
            const SizedBox(width: 8),
            _multButton('TRIPLO', 3),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.3,
          children: [
            for (final v in cricketNumbers.where((n) => n != 25))
              _numKey(theme, v),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _actionKey(
              theme,
              label: 'BULL',
              sub: _mult == 2 ? '2 segni' : null,
              onTap: _mult == 3 ? null : () => _throw(25), // niente triplo bull
              color: const Color(0xFFF9A825),
            ),
            const SizedBox(width: 6),
            _actionKey(
              theme,
              label: 'MISS',
              onTap: () => _throw(0),
              color: const Color(0xFF607D8B),
            ),
            const SizedBox(width: 6),
            _actionKey(
              theme,
              label: 'ANNULLA',
              onTap: _game.canUndo ? _undo : null,
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ],
    );
  }
}

// ======================= segni =======================

class _MarkSymbol extends StatelessWidget {
  const _MarkSymbol({required this.marks, required this.color});
  final int marks;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = (c.maxHeight.isFinite ? c.maxHeight : 32.0)
            .clamp(18.0, 34.0)
            .toDouble();
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(painter: _MarkPainter(marks, color)),
        );
      },
    );
  }
}

/// 1 segno = barra, 2 = X, 3 = X cerchiata (come sulla lavagna)
class _MarkPainter extends CustomPainter {
  _MarkPainter(this.marks, this.color);
  final int marks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = w * 0.1;

    if (marks == 0) {
      canvas.drawCircle(
        size.center(Offset.zero),
        stroke * 0.6,
        Paint()..color = color.withOpacity(0.25),
      );
      return;
    }

    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final a = w * 0.25;
    final b = w * 0.75;
    if (marks >= 1) canvas.drawLine(Offset(a, b), Offset(b, a), p);
    if (marks >= 2) canvas.drawLine(Offset(a, a), Offset(b, b), p);
    if (marks >= 3) canvas.drawCircle(size.center(Offset.zero), w * 0.45, p);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.marks != marks || old.color != color;
}