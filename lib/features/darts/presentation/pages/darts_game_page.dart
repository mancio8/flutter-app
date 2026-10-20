import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/training_store.dart';
import '../../domain/darts_models.dart';
import '../../domain/x01_game.dart';
import '../../providers/darts_provider.dart';

// Come sul bersaglio: triplo rosso, doppio verde
Color _multColor(int m) => switch (m) {
      3 => const Color(0xFFE53935),
      2 => const Color(0xFF2E9E5B),
      _ => const Color(0xFF607D8B),
    };

class DartsGamePage extends ConsumerStatefulWidget {
  const DartsGamePage({super.key, required this.config});
  final DartsGameConfig config;

  @override
  ConsumerState<DartsGamePage> createState() => _DartsGamePageState();
}

class _DartsGamePageState extends ConsumerState<DartsGamePage> {
  late X01Game _game;
  int _mult = 1;
  double? _bestAvg;
  bool _bust = false;

  DartsGameConfig get _cfg => widget.config;

  X01Game _newGame() => X01Game(
        startScore: _cfg.startScore,
        outRule: _cfg.outRule,
        playerCount: _cfg.players.length,
      );

  @override
  void initState() {
    super.initState();
    _game = _newGame();
    _loadBest();
  }

  Future<void> _loadBest() async {
    if (!_cfg.isSolo) return;
    final p = _cfg.players.first;
    double? v;
    try {
      v = p.isRegistered
          ? await ref
              .read(dartsRepositoryProvider)
              .bestTrainingAvg(p.id!, _cfg.startScore, _cfg.outRule)
          : await TrainingStore.bestAvg(p.name, _cfg.startScore, _cfg.outRule);
    } catch (_) {
      // record non disponibile: si gioca lo stesso
    }
    if (mounted) setState(() => _bestAvg = v);
  }

  // ---------------- input ----------------

  void _throw(int value) {
    if (_game.isOver) return;
    final dart = DartThrow(value, value == 0 ? 1 : _mult);
    final turnsBefore = _game.turns.length;

    HapticFeedback.selectionClick();
    setState(() {
      _game.throwDart(dart);
      _mult = 1;
    });

    if (_game.turns.length > turnsBefore && _game.turns.last.bust) {
      HapticFeedback.heavyImpact();
      setState(() => _bust = true);
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _bust = false);
      });
    }
    if (_game.isOver) _finish(completed: true);
  }

  void _undo() {
    setState(() {
      _game.undo();
      _mult = 1;
      _bust = false;
    });
  }

  void _toggleMult(int m) {
    HapticFeedback.selectionClick();
    setState(() => _mult = _mult == m ? 1 : m);
  }

  // ---------------- fine partita ----------------

  Future<void> _finish({required bool completed}) async {
    String? note;

    final solo = _cfg.isSolo;
    final hasRegistered = _cfg.players.any((p) => p.isRegistered);

    if (solo && !_cfg.players.first.isRegistered) {
      // Ospite in allenamento: storico solo sul telefono
      if (_game.dartsThrown[0] >= 3) {
        final record = await TrainingStore.save(
          _cfg.players.first.name,
          _cfg.startScore,
          _cfg.outRule,
          avg: _game.avg(0),
          darts: _game.dartsThrown[0],
          highTurn: _game.highTurn[0],
          completed: completed,
        );
        if (record) note = '🏅 Nuovo record personale!';
      }
    } else if (hasRegistered && (!solo || _game.dartsThrown[0] >= 3)) {
      final avg = _game.avg(0);
      try {
        await ref
            .read(dartsRepositoryProvider)
            .saveGame(game: _game, players: _cfg.players);
        ref.invalidate(dartsPlayersProvider);
        note = (solo && completed && _bestAvg != null && avg > _bestAvg!)
            ? '🏅 Nuovo record personale!'
            : 'Statistiche salvate';
      } catch (e) {
        note = 'Statistiche NON salvate: $e';
      }
    }

    if (!mounted) return;

    final title = solo
        ? (completed ? '🎯 Chiusura!' : 'Allenamento concluso')
        : '🏆 ${_cfg.players[_game.winner!].name}';

    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
                    '${_cfg.players[i].name}${_game.winner == i ? ' 🏆' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Media ${_game.avg(i).toStringAsFixed(1)} · '
                    'Miglior turno ${_game.highTurn[i]} · '
                    'Bust ${_game.busts[i]} · '
                    'Chiusure ${_game.checkoutText(i)}\n'
                    '${_game.dartsThrown[i]} freccette',
                  ),
                ),
              if (note != null) ...[
                const Divider(),
                Text(note, textAlign: TextAlign.center),
              ],
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
      _loadBest();
    } else {
      context.pop();
    }
  }

  Future<void> _confirmEndTraining() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terminare l'allenamento?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Termina'),
          ),
        ],
      ),
    );
    if (ok == true) _finish(completed: false);
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
        content: const Text('I progressi non salvati andranno persi.'),
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

  // ---------------- UI ----------------

  String? _hint() {
    if (_game.isOver) return null;
    final r = checkoutFor(
      _game.remaining[_game.current],
      _cfg.outRule,
      _game.dartsLeftInTurn,
    );
    return r?.map((d) => d.label).join('  →  ');
  }

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
          title: Text('${_cfg.startScore} · ${_cfg.outRule.label}'),
          actions: [
            if (_cfg.isSolo)
              TextButton.icon(
                onPressed: _confirmEndTraining,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Termina'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < _cfg.players.length; i++)
                            _PlayerTile(
                              player: _cfg.players[i],
                              startScore: _cfg.startScore,
                              remaining: _game.remaining[i],
                              active: i == _game.current && !_game.isOver,
                              avg: _game.avg(i),
                              highTurn: _game.highTurn[i],
                              busts: _game.busts[i],
                            ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _bust ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: AnimatedScale(
                              scale: _bust ? 1 : 0.6,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '💥 BUST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
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

  // ---------- pannello del turno ----------

  Widget _turnPanel(ThemeData theme) {
    final p = _cfg.players[_game.current];
    final hint = _hint();
    final pts = _game.turnPoints;

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
            if (_cfg.isSolo && _bestAvg != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.emoji_events, size: 16),
                  label: Text('Record ${_bestAvg!.toStringAsFixed(1)}'),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: pts > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                pts > 0 ? '+$pts' : '—',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: pts > 0
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
                  child: _DartSlot(
                    dart: k < _game.turnDarts.length ? _game.turnDarts[k] : null,
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: hint == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chiusura: $hint',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ---------- tastiera ----------

  Widget _multButton(String label, int m) {
    final sel = _mult == m;
    final c = _multColor(m);
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
    final tinted = _mult > 1;
    final c = _multColor(_mult);
    return Material(
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: tinted ? c : theme.colorScheme.onSurface,
                ),
              ),
              if (tinted)
                Text(
                  '${v * _mult}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
            ],
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
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.primary;
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: c.withOpacity(0.14),
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
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: c,
                      ),
                    ),
                    if (sub != null)
                      Text(sub, style: TextStyle(fontSize: 10, color: c)),
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
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.45,
          children: [for (var v = 1; v <= 20; v++) _numKey(theme, v)],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _actionKey(
              theme,
              label: 'BULL',
              sub: _mult == 2 ? '50' : '25',
              onTap: _mult == 3 ? null : () => _throw(25), // niente triplo bull
              color: const Color(0xFFF9A825),
            ),
            const SizedBox(width: 6),
            _actionKey(
              theme,
              label: 'MISS',
              sub: '0',
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

// ======================= componenti =======================

class _DartSlot extends StatelessWidget {
  const _DartSlot({required this.dart});
  final DartThrow? dart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dart;
    final c = d == null
        ? theme.colorScheme.outlineVariant
        : (d.value == 0 ? const Color(0xFF607D8B) : _multColor(d.mult));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: d == null ? Colors.transparent : c.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c, width: d == null ? 1 : 2),
      ),
      child: Column(
        children: [
          Text(
            d?.label ?? '·',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: d == null ? theme.colorScheme.outline : c,
            ),
          ),
          Text(
            d == null ? ' ' : '${d.points}',
            style: TextStyle(fontSize: 11, color: c),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.startScore,
    required this.remaining,
    required this.active,
    required this.avg,
    required this.highTurn,
    required this.busts,
  });

  final DartsPlayer player;
  final int startScore;
  final int remaining;
  final bool active;
  final double avg;
  final int highTurn;
  final int busts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = player.colorValue;
    final progress = ((startScore - remaining) / startScore).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(active ? 16 : 12),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.10) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? c : theme.colorScheme.outlineVariant,
          width: active ? 2.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(player.avatar,
                  style: TextStyle(fontSize: active ? 34 : 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: active ? 17 : 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniStat('Media', avg.toStringAsFixed(1)),
                        _MiniStat('Best', '$highTurn'),
                        if (busts > 0) _MiniStat('Bust', '$busts'),
                      ],
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(end: remaining),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '$v',
                  style: TextStyle(
                    fontSize: active ? 58 : 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: active ? c : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 450),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  color: c,
                  backgroundColor: c.withOpacity(0.18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}