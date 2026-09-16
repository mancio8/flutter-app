// File: lib/features/viaggi/presentation/pages/viaggi_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/viaggio.dart';
import '../../providers/viaggi_provider.dart';

class ViaggiPage extends ConsumerStatefulWidget {
  const ViaggiPage({super.key});

  @override
  ConsumerState<ViaggiPage> createState() => _ViaggiPageState();
}

class _ViaggiPageState extends ConsumerState<ViaggiPage> {
  // 0 = Visitati, 1 = Wishlist
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viaggiFattiAsync = ref.watch(viaggiProvider);
    final wishlistAsync = ref.watch(wishlistViaggiProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(viaggiProvider);
          ref.invalidate(wishlistViaggiProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ============================================================
            // SLIVER APP BAR — identica alle altre pagine
            // ============================================================
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
                      'I Miei Viaggi',
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

            // ============================================================
            // SELETTORE VISITATI / WISHLIST — fuori dalla SliverAppBar
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Visitati',
                          icon: Icons.check_circle_outline,
                          isActive: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          label: 'Wishlist',
                          icon: Icons.favorite_border,
                          isActive: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // CONTENUTO — lista visitati o wishlist
            // ============================================================
            if (_selectedTab == 0)
              _ViaggiFattiListSliver(asyncData: viaggiFattiAsync)
            else
              _WishlistListSliver(
                asyncData: wishlistAsync,
                onVisitato: (viaggio) =>
                    _showMoveToVisitatoDialog(context, viaggio),
                onRemove: (viaggio) =>
                    _confirmRemoveFromWishlist(context, viaggio),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedTab == 0) {
            _showAddViaggioFattoDialog(context);
          } else {
            _showAddWishlistDialog(context);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _showAddWishlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddDestinazioneDialog(ref: ref),
    );
  }

  void _showAddViaggioFattoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddViaggioFattoDialog(ref: ref),
    );
  }

  void _showMoveToVisitatoDialog(BuildContext context, Viaggio viaggio) {
    showDialog(
      context: context,
      builder: (_) => _SegnaVisitatoDialog(ref: ref, viaggio: viaggio),
    );
  }

  void _confirmRemoveFromWishlist(BuildContext context, Viaggio viaggio) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rimuovere dalla lista?'),
        content: Text(
          '"${viaggio.destinazione}" verrà rimossa dalle destinazioni desiderate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(viaggiProvider.notifier).removeFromWishlist(viaggio.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB BUTTON — stile coerente con selettore giorni di RaccoltaPage
// ============================================================

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LISTA VISITATI — sliver
// ============================================================

class _ViaggiFattiListSliver extends ConsumerWidget {
  final AsyncValue<List<Viaggio>> asyncData;

  const _ViaggiFattiListSliver({required this.asyncData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncData.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: _ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(viaggiProvider),
        ),
      ),
      data: (viaggi) {
        if (viaggi.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Nessun viaggio registrato',
              subtitle: 'Aggiungi i posti che hai già visitato',
              buttonLabel: 'Aggiungi viaggio',
              onAdd: () => showDialog(
                context: context,
                builder: (_) => _AddViaggioFattoDialog(ref: ref),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final viaggio = viaggi[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ViaggioFattoCard(
                    viaggio: viaggio,
                    onDelete: () => _confirmDelete(context, ref, viaggio),
                  ),
                );
              },
              childCount: viaggi.length,
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Viaggio v) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminare questo viaggio?'),
        content: Text('"${v.destinazione}" verrà eliminato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(viaggiProvider.notifier).deleteViaggio(v.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LISTA WISHLIST — sliver
// ============================================================

class _WishlistListSliver extends ConsumerWidget {
  final AsyncValue<List<Viaggio>> asyncData;
  final Function(Viaggio) onVisitato;
  final Function(Viaggio) onRemove;

  const _WishlistListSliver({
    required this.asyncData,
    required this.onVisitato,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncData.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: _ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(wishlistViaggiProvider),
        ),
      ),
      data: (viaggi) {
        if (viaggi.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              icon: Icons.card_travel,
              title: 'Nessuna destinazione salvata',
              subtitle: 'Aggiungi i posti che vorresti visitare',
              buttonLabel: 'Aggiungi destinazione',
              onAdd: () => showDialog(
                context: context,
                builder: (_) => _AddDestinazioneDialog(ref: ref),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final viaggio = viaggi[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ViaggioWishlistCard(
                    viaggio: viaggio,
                    onVisitato: () => onVisitato(viaggio),
                    onRemove: () => onRemove(viaggio),
                  ),
                );
              },
              childCount: viaggi.length,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CARD VIAGGIO FATTO
// ============================================================

class _ViaggioFattoCard extends StatelessWidget {
  final Viaggio viaggio;
  final VoidCallback onDelete;

  const _ViaggioFattoCard({required this.viaggio, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: viaggio.copertinaUrl != null &&
                      viaggio.copertinaUrl!.isNotEmpty
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
                  Text(
                    viaggio.destinazione,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (viaggio.paese != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      viaggio.paese!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (viaggio.dataVisita != null)
                        _BadgeInfo(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat('dd/MM/yyyy')
                              .format(viaggio.dataVisita!),
                          theme: theme,
                        ),
                      if (viaggio.rating != null && viaggio.rating! > 0)
                        _RatingBadge(rating: viaggio.rating!, theme: theme),
                    ],
                  ),
                  if (viaggio.note != null && viaggio.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      viaggio.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: theme.colorScheme.error,
                onPressed: onDelete,
                tooltip: 'Elimina',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
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

// ============================================================
// CARD WISHLIST
// ============================================================

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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: viaggio.copertinaUrl != null &&
                      viaggio.copertinaUrl!.isNotEmpty
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
                  Text(
                    viaggio.destinazione,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (viaggio.paese != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      viaggio.paese!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (viaggio.budgetStimato != null) ...[
                    const SizedBox(height: 6),
                    _BadgeInfo(
                      icon: Icons.euro_outlined,
                      label:
                          'Budget: €${viaggio.budgetStimato!.toStringAsFixed(0)}',
                      theme: theme,
                    ),
                  ],
                  if (viaggio.note != null && viaggio.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      viaggio.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    color: Colors.green,
                    tooltip: 'Segna come visitato',
                    onPressed: onVisitato,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: theme.colorScheme.error,
                    tooltip: 'Rimuovi',
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
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

// ============================================================
// COMPONENTI COMUNI
// ============================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Errore nel caricamento'),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _BadgeInfo({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final int rating;
  final ThemeData theme;

  const _RatingBadge({required this.rating, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            i < rating ? Icons.star : Icons.star_border,
            size: 12,
            color: Colors.amber[800],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG: aggiungi destinazione alla wishlist
// ============================================================

class _AddDestinazioneDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddDestinazioneDialog({required this.ref});

  @override
  ConsumerState<_AddDestinazioneDialog> createState() =>
      _AddDestinazioneDialogState();
}

class _AddDestinazioneDialogState
    extends ConsumerState<_AddDestinazioneDialog> {
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
    final theme = Theme.of(context);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nuova destinazione',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _destinazioneController,
                  decoration: InputDecoration(
                    labelText: 'Destinazione',
                    hintText: 'Es. Tokyo',
                    prefixIcon: const Icon(Icons.place_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paeseController,
                  decoration: InputDecoration(
                    labelText: 'Paese (opzionale)',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    labelText: 'Budget stimato (opzionale)',
                    prefixText: '€ ',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _copertinaController,
                  decoration: InputDecoration(
                    labelText: 'URL immagine (opzionale)',
                    prefixIcon: const Icon(Icons.image_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
      paese: _paeseController.text.trim().isEmpty
          ? null
          : _paeseController.text.trim(),
      copertinaUrl: _copertinaController.text.trim().isEmpty
          ? null
          : _copertinaController.text.trim(),
      budgetStimato: _budgetController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    widget.ref.read(viaggiProvider.notifier).addToWishlist(viaggio);
    Navigator.pop(context);
  }
}

// ============================================================
// DIALOG: aggiungi viaggio già fatto
// ============================================================

class _AddViaggioFattoDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddViaggioFattoDialog({required this.ref});

  @override
  ConsumerState<_AddViaggioFattoDialog> createState() =>
      _AddViaggioFattoDialogState();
}

class _AddViaggioFattoDialogState
    extends ConsumerState<_AddViaggioFattoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _destinazioneController = TextEditingController();
  final _paeseController = TextEditingController();
  final _copertinaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _dataVisita = DateTime.now();
  int _rating = 3;

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
    final theme = Theme.of(context);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nuovo viaggio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _destinazioneController,
                  decoration: InputDecoration(
                    labelText: 'Destinazione',
                    hintText: 'Es. Parigi',
                    prefixIcon: const Icon(Icons.place_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paeseController,
                  decoration: InputDecoration(
                    labelText: 'Paese (opzionale)',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dataVisita,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dataVisita = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data visita',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_dataVisita),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    labelText: 'Budget speso (opzionale)',
                    prefixText: '€ ',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _copertinaController,
                  decoration: InputDecoration(
                    labelText: 'URL immagine (opzionale)',
                    prefixIcon: const Icon(Icons.image_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
      paese: _paeseController.text.trim().isEmpty
          ? null
          : _paeseController.text.trim(),
      copertinaUrl: _copertinaController.text.trim().isEmpty
          ? null
          : _copertinaController.text.trim(),
      budgetStimato: _budgetController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      dataVisita: _dataVisita,
      rating: _rating,
    );

    widget.ref.read(viaggiProvider.notifier).addViaggioFatto(viaggio);
    Navigator.pop(context);
  }
}

// ============================================================
// DIALOG: segna come visitato (dalla wishlist)
// ============================================================

class _SegnaVisitatoDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Viaggio viaggio;

  const _SegnaVisitatoDialog({required this.ref, required this.viaggio});

  @override
  ConsumerState<_SegnaVisitatoDialog> createState() =>
      _SegnaVisitatoDialogState();
}

class _SegnaVisitatoDialogState extends ConsumerState<_SegnaVisitatoDialog> {
  DateTime _dataVisita = DateTime.now();
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hai visitato ${widget.viaggio.destinazione}?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataVisita,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dataVisita = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data visita',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_dataVisita)),
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
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await widget.ref
                          .read(viaggiProvider.notifier)
                          .moveToVisitato(
                            widget.viaggio,
                            _dataVisita,
                            rating: _rating,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Conferma'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}