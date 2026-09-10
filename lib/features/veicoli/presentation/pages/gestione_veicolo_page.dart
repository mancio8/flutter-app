// File: lib/features/manutenzioni/presentation/pages/gestione_veicolo_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/manutenzione.dart';
import '../../../../core/models/scadenza_veicolo.dart';
import '../../providers/manutenzioni_provider.dart';

class GestioneVeicoloPage extends ConsumerStatefulWidget {
  final String veicoloId;
  final String nomeVeicolo;

  const GestioneVeicoloPage({
    super.key,
    required this.veicoloId,
    required this.nomeVeicolo,
  });

  @override
  ConsumerState<GestioneVeicoloPage> createState() =>
      _GestioneVeicoloPageState();
}

class _GestioneVeicoloPageState extends ConsumerState<GestioneVeicoloPage> {
  // 0 = Manutenzione, 1 = Scadenze
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manutenzioniAsync = ref.watch(manutenzioniProvider);
    final scadenzeAsync = ref.watch(scadenzeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(manutenzioniProvider.future);
          await ref.refresh(scadenzeProvider.future);
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
                    const Icon(Icons.directions_car, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.nomeVeicolo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      Icons.build_circle_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================
            // SELETTORE MANUTENZIONE / SCADENZE
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
                          label: 'Manutenzione',
                          icon: Icons.build_outlined,
                          isActive: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          label: 'Scadenze',
                          icon: Icons.event_note_outlined,
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
            // CONTENUTO — lista manutenzioni o scadenze
            // ============================================================
            if (_selectedTab == 0)
              _ManutenzioniListSliver(
                veicoloId: widget.veicoloId,
                asyncData: manutenzioniAsync,
                onAdd: () => _showAddManutenzioneDialog(context),
              )
            else
              _ScadenzeListSliver(
                veicoloId: widget.veicoloId,
                asyncData: scadenzeAsync,
                onAdd: () => _showAddScadenzaDialog(context),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedTab == 0) {
            _showAddManutenzioneDialog(context);
          } else {
            _showAddScadenzaDialog(context);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _showAddManutenzioneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ManutenzioneDialog(veicoloId: widget.veicoloId),
    );
  }

  void _showEditManutenzioneDialog(
    BuildContext context,
    Manutenzione manutenzione,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ManutenzioneDialog(
        veicoloId: widget.veicoloId,
        manutenzione: manutenzione,
      ),
    );
  }

  void _showAddScadenzaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ScadenzaDialog(veicoloId: widget.veicoloId),
    );
  }

  void _showEditScadenzaDialog(
    BuildContext context,
    ScadenzaVeicolo scadenza,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ScadenzaDialog(
        veicoloId: widget.veicoloId,
        scadenza: scadenza,
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
// LISTA MANUTENZIONI come SLIVER
// ============================================================

class _ManutenzioniListSliver extends ConsumerWidget {
  final String veicoloId;
  final AsyncValue<List<Manutenzione>> asyncData;
  final VoidCallback onAdd;

  const _ManutenzioniListSliver({
    required this.veicoloId,
    required this.asyncData,
    required this.onAdd,
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
          onRetry: () => ref.invalidate(manutenzioniProvider),
        ),
      ),
      data: (lista) {
        final filtrate =
            lista.where((m) => m.veicoloId == veicoloId).toList();

        if (filtrate.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              icon: Icons.build_outlined,
              title: 'Nessun intervento registrato',
              subtitle: 'Registra tagliandi, riparazioni o cambi olio',
              onAdd: onAdd,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final manutenzione = filtrate[index];
                return _ManutenzioneCard(
                  manutenzione: manutenzione,
                  onDelete: () {
                    _confirmDeleteManutenzione(context, ref, manutenzione);
                  },
                );
              },
              childCount: filtrate.length,
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteManutenzione(
    BuildContext context,
    WidgetRef ref,
    Manutenzione m,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminare questa manutenzione?'),
        content: Text('"${m.titolo}" verrà eliminata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(manutenzioniProvider.notifier).deleteManutenzione(m.id);
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

class _ManutenzioneCard extends StatelessWidget {
  final Manutenzione manutenzione;
  final VoidCallback onDelete;

  const _ManutenzioneCard({required this.manutenzione, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            // Icona
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.build,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Contenuto espandibile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manutenzione.titolo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BadgeInfo(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat(
                          'dd/MM/yyyy',
                        ).format(manutenzione.data),
                        theme: theme,
                      ),
                      if (manutenzione.chilometraggio != null)
                        _BadgeInfo(
                          icon: Icons.speed_outlined,
                          label: '${manutenzione.chilometraggio!.toInt()} km',
                          theme: theme,
                        ),
                      if (manutenzione.costo > 0)
                        _BadgeInfo(
                          icon: Icons.euro_outlined,
                          label: '€ ${manutenzione.costo.toStringAsFixed(2)}',
                          theme: theme,
                        ),
                    ],
                  ),
                  if (manutenzione.note != null &&
                      manutenzione.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      manutenzione.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Delete compatto
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
}

// ============================================================
// LISTA SCADENZE come SLIVER
// ============================================================

class _ScadenzeListSliver extends ConsumerWidget {
  final String veicoloId;
  final AsyncValue<List<ScadenzaVeicolo>> asyncData;
  final VoidCallback onAdd;

  const _ScadenzeListSliver({
    required this.veicoloId,
    required this.asyncData,
    required this.onAdd,
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
          onRetry: () => ref.invalidate(scadenzeProvider),
        ),
      ),
      data: (lista) {
        final filtrate =
            lista.where((s) => s.veicoloId == veicoloId).toList();

        if (filtrate.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Nessuna scadenza impostata',
              subtitle: 'Tieni traccia di bollo, assicurazione e revisioni',
              onAdd: onAdd,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final scadenza = filtrate[index];
                return _ScadenzaCard(
                  scadenza: scadenza,
                  onToggle: (val) {
                    if (val != null) {
                      ref
                          .read(scadenzeProvider.notifier)
                          .toggleCompletato(scadenza.id, val);
                    }
                  },
                  onDelete: () {
                    _confirmDeleteScadenza(context, ref, scadenza);
                  },
                );
              },
              childCount: filtrate.length,
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteScadenza(
    BuildContext context,
    WidgetRef ref,
    ScadenzaVeicolo s,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminare questa scadenza?'),
        content: Text(
          '${s.tipoLabel} del ${DateFormat('dd/MM/yyyy').format(s.dataScadenza)} verrà eliminata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(scadenzeProvider.notifier).deleteScadenza(s.id);
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

class _ScadenzaCard extends StatelessWidget {
  final ScadenzaVeicolo scadenza;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const _ScadenzaCard({
    required this.scadenza,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor = Colors.green;
    if (scadenza.isScaduto) {
      statusColor = theme.colorScheme.error;
    } else if (scadenza.giorniRimanenti <= 30) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: !scadenza.completato && scadenza.isInScadenza
            ? Border.all(color: Colors.orange, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox compatta
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: scadenza.completato,
                onChanged: onToggle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),

            // Contenuto espandibile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Riga 1: titolo + badge giorni
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scadenza.tipoLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: scadenza.completato
                                ? TextDecoration.lineThrough
                                : null,
                            color: scadenza.completato
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scadenza.completato
                              ? theme.colorScheme.surfaceContainerHighest
                              : statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scadenza.completato
                              ? 'Fatto'
                              : scadenza.isScaduto
                              ? 'Scaduto'
                              : '${scadenza.giorniRimanenti} gg',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scadenza.completato
                                ? theme.colorScheme.onSurfaceVariant
                                : statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Riga 2: badge data + importo
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BadgeInfo(
                        icon: Icons.calendar_month_outlined,
                        label: DateFormat(
                          'dd/MM/yyyy',
                        ).format(scadenza.dataScadenza),
                        theme: theme,
                      ),
                      if (scadenza.importoStimato != null)
                        _BadgeInfo(
                          icon: Icons.euro_outlined,
                          label:
                              '€ ${scadenza.importoStimato!.toStringAsFixed(2)}',
                          theme: theme,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete compatto
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
}

// ============================================================
// COMPONENTI COMUNI
// ============================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
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
              child: Icon(icon, size: 70, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$subtitle\nScorri verso il basso per aggiornare',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi ora'),
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

// ============================================================
// DIALOG MANUTENZIONE (add + edit)
// ============================================================

class _ManutenzioneDialog extends ConsumerStatefulWidget {
  final String veicoloId;
  final Manutenzione? manutenzione;

  const _ManutenzioneDialog({required this.veicoloId, this.manutenzione});

  @override
  ConsumerState<_ManutenzioneDialog> createState() =>
      _ManutenzioneDialogState();
}

class _ManutenzioneDialogState extends ConsumerState<_ManutenzioneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  late final TextEditingController _costoController;
  late final TextEditingController _kmController;
  late final TextEditingController _noteController;
  late DateTime _data;

  bool get isEditing => widget.manutenzione != null;

  @override
  void initState() {
    super.initState();
    _titoloController = TextEditingController(
      text: widget.manutenzione?.titolo ?? '',
    );
    _costoController = TextEditingController(
      text: widget.manutenzione?.costo.toString() ?? '',
    );
    _kmController = TextEditingController(
      text: widget.manutenzione?.chilometraggio?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.manutenzione?.note ?? '',
    );
    _data = widget.manutenzione?.data ?? DateTime.now();
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _costoController.dispose();
    _kmController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Modifica Manutenzione'
                            : 'Nuova Manutenzione',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Titolo
                TextFormField(
                  controller: _titoloController,
                  decoration: InputDecoration(
                    labelText: 'Intervento',
                    hintText: 'Es. Tagliando, Cambio Freni',
                    prefixIcon: const Icon(Icons.build_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 16),

                // Costo + Km
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Costo',
                          prefixText: '€ ',
                          prefixIcon: const Icon(Icons.euro),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v.replaceAll(',', '.')) == null) {
                            return 'Numero non valido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _kmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Km',
                          suffixText: 'km',
                          prefixIcon: const Icon(Icons.speed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Data
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _data,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _data = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data intervento',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_data)),
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionali)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottoni
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
                        child: Text(isEditing ? 'Salva' : 'Aggiungi'),
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

    final manutenzione = Manutenzione(
      id: widget.manutenzione?.id ?? '',
      veicoloId: widget.veicoloId,
      titolo: _titoloController.text.trim(),
      data: _data,
      costo: double.tryParse(_costoController.text.replaceAll(',', '.')) ?? 0.0,
      chilometraggio: _kmController.text.trim().isEmpty
          ? null
          : double.tryParse(_kmController.text),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (isEditing) {
      ref.read(manutenzioniProvider.notifier).updateManutenzione(manutenzione);
    } else {
      ref.read(manutenzioniProvider.notifier).addManutenzione(manutenzione);
    }

    Navigator.pop(context);
  }
}

// ============================================================
// DIALOG SCADENZA (add + edit)
// ============================================================

class _ScadenzaDialog extends ConsumerStatefulWidget {
  final String veicoloId;
  final ScadenzaVeicolo? scadenza;

  const _ScadenzaDialog({required this.veicoloId, this.scadenza});

  @override
  ConsumerState<_ScadenzaDialog> createState() => _ScadenzaDialogState();
}

class _ScadenzaDialogState extends ConsumerState<_ScadenzaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _importoController;
  late String _tipo;
  late DateTime _dataScadenza;

  bool get isEditing => widget.scadenza != null;

  static const _tipi = [
    ('assicurazione', 'Assicurazione'),
    ('bollo', 'Bollo'),
    ('revisione', 'Revisione'),
    ('altro', 'Altro'),
  ];

  @override
  void initState() {
    super.initState();
    _tipo = widget.scadenza?.tipo ?? 'assicurazione';
    _dataScadenza =
        widget.scadenza?.dataScadenza ??
        DateTime.now().add(const Duration(days: 30));
    _importoController = TextEditingController(
      text: widget.scadenza?.importoStimato?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _importoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifica Scadenza' : 'Nuova Scadenza',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tipo
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: InputDecoration(
                    labelText: 'Tipo Scadenza',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _tipi
                      .map(
                        (t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 16),

                // Importo
                TextFormField(
                  controller: _importoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo stimato',
                    prefixText: '€ ',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Numero non valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Data scadenza
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dataScadenza,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (picked != null) setState(() => _dataScadenza = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data di scadenza',
                      prefixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_dataScadenza)),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottoni
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
                        child: Text(isEditing ? 'Salva' : 'Aggiungi'),
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

    final scadenza = ScadenzaVeicolo(
      id: widget.scadenza?.id ?? '',
      veicoloId: widget.veicoloId,
      tipo: _tipo,
      dataScadenza: _dataScadenza,
      importoStimato: _importoController.text.trim().isEmpty
          ? null
          : double.tryParse(_importoController.text.replaceAll(',', '.')),
      completato: widget.scadenza?.completato ?? false,
    );

    if (isEditing) {
      ref.read(scadenzeProvider.notifier).updateScadenza(scadenza);
    } else {
      ref.read(scadenzeProvider.notifier).addScadenza(scadenza);
    }

    Navigator.pop(context);
  }
}