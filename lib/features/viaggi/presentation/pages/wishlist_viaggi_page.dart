import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/viaggio.dart';
import '../../providers/viaggi_provider.dart';

class WishlistViaggiPage extends ConsumerWidget {
  const WishlistViaggiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistViaggiProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(wishlistViaggiProvider),
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
                    const Icon(Icons.card_travel, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Destinazioni desiderate',
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
                      Icons.flight_takeoff,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: wishlistAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Errore: $e')),
                ),
                data: (viaggi) {
                  if (viaggi.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(onAdd: () => _showAddDialog(context, ref)),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final viaggio = viaggi[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ViaggioWishlistCard(
                          viaggio: viaggio,
                          onVisitato: () => _showMoveToVisitatoDialog(context, ref, viaggio),
                          onRemove: () => _confirmRemove(context, ref, viaggio),
                        ),
                      );
                    }, childCount: viaggi.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _AddDestinazioneDialog(ref: ref));
  }

  void _showMoveToVisitatoDialog(BuildContext context, WidgetRef ref, Viaggio viaggio) {
    showDialog(
      context: context,
      builder: (context) => _SegnaVisitatoDialog(ref: ref, viaggio: viaggio),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, Viaggio viaggio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rimuovere dalla lista?'),
        content: Text('"${viaggio.destinazione}" verrà rimossa dalle destinazioni desiderate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              ref.read(viaggiProvider.notifier).removeFromWishlist(viaggio.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
  }
}

class _ViaggioWishlistCard extends StatelessWidget {
  final Viaggio viaggio;
  final VoidCallback onVisitato;
  final VoidCallback onRemove;

  const _ViaggioWishlistCard({
    required this.viaggio,
    required this.onVisitato,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: viaggio.copertinaUrl != null && viaggio.copertinaUrl!.isNotEmpty
                  ? Image.network(
                      viaggio.copertinaUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme),
                    )
                  : _placeholder(theme),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(viaggio.destinazione,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (viaggio.paese != null) ...[
                    const SizedBox(height: 2),
                    Text(viaggio.paese!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  if (viaggio.budgetStimato != null) ...[
                    const SizedBox(height: 4),
                    Text('Budget stimato: €${viaggio.budgetStimato!.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ],
                  if (viaggio.note != null && viaggio.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(viaggio.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  tooltip: 'Segna come visitato',
                  onPressed: onVisitato,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Rimuovi',
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Icon(Icons.card_travel, color: theme.colorScheme.primary),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_travel, size: 80, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Nessuna destinazione salvata',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Aggiungi i posti che vorresti visitare',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi destinazione'),
          ),
        ],
      ),
    );
  }
}

// Dialog: aggiungi destinazione alla wishlist
class _AddDestinazioneDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddDestinazioneDialog({required this.ref});

  @override
  ConsumerState<_AddDestinazioneDialog> createState() => _AddDestinazioneDialogState();
}

class _AddDestinazioneDialogState extends ConsumerState<_AddDestinazioneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _destinazioneController = TextEditingController();
  final _paeseController = TextEditingController();
  final _copertinaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _destinazioneController.dispose();
    _paeseController.dispose();
    _copertinaController.dispose();
    _budgetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuova destinazione',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _destinazioneController,
                  decoration: const InputDecoration(labelText: 'Destinazione'),
                  validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paeseController,
                  decoration: const InputDecoration(labelText: 'Paese (opzionale)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(labelText: 'Budget stimato € (opzionale)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _copertinaController,
                  decoration: const InputDecoration(labelText: 'URL immagine (opzionale)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (opzionale)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Aggiungi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final viaggio = Viaggio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      destinazione: _destinazioneController.text.trim(),
      paese: _paeseController.text.trim().isEmpty ? null : _paeseController.text.trim(),
      copertinaUrl: _copertinaController.text.trim().isEmpty ? null : _copertinaController.text.trim(),
      budgetStimato: _budgetController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetController.text.trim()),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    widget.ref.read(viaggiProvider.notifier).addToWishlist(viaggio);
    Navigator.pop(context);
  }
}

// Dialog: segna come visitato
class _SegnaVisitatoDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Viaggio viaggio;

  const _SegnaVisitatoDialog({required this.ref, required this.viaggio});

  @override
  ConsumerState<_SegnaVisitatoDialog> createState() => _SegnaVisitatoDialogState();
}

class _SegnaVisitatoDialogState extends ConsumerState<_SegnaVisitatoDialog> {
  DateTime _dataVisita = DateTime.now();
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Hai visitato ${widget.viaggio.destinazione}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dataVisita,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dataVisita = date);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data visita'),
              child: Text('${_dataVisita.day}/${_dataVisita.month}/${_dataVisita.year}'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(
          onPressed: () async {
            await widget.ref
                .read(viaggiProvider.notifier)
                .moveToVisitato(widget.viaggio, _dataVisita, rating: _rating);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}