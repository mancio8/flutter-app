import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/darts_models.dart';
import '../../domain/x01_game.dart';
import '../../providers/darts_provider.dart';

const _avatars = ['🎯', '🏹', '⚡', '🔥', '💎', '🦁', '🐉', '🦊', '👑', '🌟', '🦅', '🤖'];
const _palette = [
  '#00d68f', '#2d9ef5', '#ff4560', '#f5c842',
  '#9b6dff', '#ff6b35', '#00d4ff', '#ff3bff',
];

class DartsPage extends ConsumerStatefulWidget {
  const DartsPage({super.key});

  @override
  ConsumerState<DartsPage> createState() => _DartsPageState();
}

class _DartsPageState extends ConsumerState<DartsPage> {
  final List<DartsPlayer> _selected = []; // l'ordine di tocco = ordine di tiro
  final List<DartsPlayer> _guests = [];
  int _startScore = 501;
  OutRule _outRule = OutRule.double;

  void _toggle(DartsPlayer p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        _selected.add(p);
      }
    });
  }

  void _start() {
    context.push(
      '/darts/partita',
      extra: DartsGameConfig(
        players: List.of(_selected),
        startScore: _startScore,
        outRule: _outRule,
      ),
    );
  }

  Future<void> _delete(DartsPlayer p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminare ${p.name}?'),
        content: Text(p.isRegistered
            ? 'Verranno eliminate anche le sue statistiche sul server.'
            : 'Il giocatore ospite verrà rimosso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (p.isRegistered) {
      try {
        await ref.read(dartsPlayersProvider.notifier).remove(p.id!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _guests.remove(p);
        _selected.remove(p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(dartsPlayersProvider);
    final registered = playersAsync.valueOrNull ?? const <DartsPlayer>[];
    final all = [...registered, ..._guests];

    return Scaffold(
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _start,
              icon: Icon(_selected.length == 1 ? Icons.bolt : Icons.play_arrow),
              label: Text(_selected.length == 1 ? 'Allenamento' : 'Gioca'),
            ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dartsPlayersProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Row(
                  children: [
                    const Icon(Icons.adjust, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Freccette',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.gps_fixed,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Opzioni partita
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Punteggio',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [301, 501, 701].map((s) {
                        return ChoiceChip(
                          label: Text('$s'),
                          selected: _startScore == s,
                          onSelected: (_) => setState(() => _startScore = s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Chiusura',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<OutRule>(
                      showSelectedIcon: false,
                      segments: OutRule.values
                          .map((r) => ButtonSegment(
                                value: r,
                                label: Text(r.label.replaceAll(' out', '')),
                              ))
                          .toList(),
                      selected: {_outRule},
                      onSelectionChanged: (s) =>
                          setState(() => _outRule = s.first),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      switch (_outRule) {
                        OutRule.single => 'Si chiude con qualsiasi freccetta.',
                        OutRule.double => 'Si chiude con un doppio (o Bull).',
                        OutRule.master => 'Si chiude con doppio, triplo o Bull.',
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (playersAsync.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off),
                      title: const Text('Giocatori registrati non disponibili'),
                      subtitle: const Text(
                          'Puoi comunque giocare con gli ospiti.'),
                      trailing: TextButton(
                        onPressed: () => ref.invalidate(dartsPlayersProvider),
                        child: const Text('Riprova'),
                      ),
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  '1 giocatore = allenamento, 2 o più = partita. '
                  "L'ordine in cui li tocchi è l'ordine di tiro.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == all.length) {
                      return _AddCard(onTap: _showAddDialog);
                    }
                    final p = all[index];
                    final pos = _selected.indexOf(p);
                    return _PlayerCard(
                      player: p,
                      order: pos == -1 ? null : pos + 1,
                      onTap: () => _toggle(p),
                      onLongPress: () => _delete(p),
                    );
                  },
                  childCount: all.length + 1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddPlayerDialog(
        onGuest: (p) => setState(() => _guests.add(p)),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.order,
    required this.onTap,
    required this.onLongPress,
  });

  final DartsPlayer player;
  final int? order;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = order != null;
    final c = player.colorValue;

    return Material(
      color: selected ? c.withOpacity(0.12) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(player.avatar, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    if (player.isRegistered) ...[
                      Text(
                        '${player.gamesPlayed} partite · ${player.gamesWon} vinte',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        'media ${player.avgPpr.toStringAsFixed(1)}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ] else
                      Text('Ospite', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: c,
                    child: Text(
                      '$order',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            const Text('Nuovo giocatore',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AddPlayerDialog extends ConsumerStatefulWidget {
  const _AddPlayerDialog({required this.onGuest});
  final void Function(DartsPlayer) onGuest;

  @override
  ConsumerState<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends ConsumerState<_AddPlayerDialog> {
  final _name = TextEditingController();
  String _avatar = _avatars.first;
  bool _registered = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final color = _palette[name.length % _palette.length];

    if (!_registered) {
      widget.onGuest(DartsPlayer(name: name, avatar: _avatar, color: color));
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(dartsPlayersProvider.notifier).add(name, _avatar, color);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossibile creare il giocatore: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo giocatore'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Con account')),
                ButtonSegment(value: false, label: Text('Ospite')),
              ],
              selected: {_registered},
              onSelectionChanged: (s) => setState(() => _registered = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _registered
                  ? 'Viene creato sul server: le statistiche vengono salvate.'
                  : 'Solo per questa sessione, nessuna statistica salvata.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            Wrap(
              spacing: 6,
              children: _avatars
                  .map((e) => ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 20)),
                        selected: _avatar == e,
                        onSelected: (_) => setState(() => _avatar = e),
                      ))
                  .toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Aggiungi'),
        ),
      ],
    );
  }
}