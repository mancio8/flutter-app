// File: lib/features/habits/presentation/pages/habits_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../services/habits_import_export_service.dart';
import '../widgets/habit_card.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final stats = ref.watch(habitsStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(habitsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ============================================================
            // APP BAR coerente con le altre pagine
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
                    const Icon(Icons.checklist_rtl, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Habit Tracker',
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
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    _handleMenuAction(context, ref, value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.upload),
                          SizedBox(width: 8),
                          Text('Importa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Esporta dati'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export_stats',
                      child: Row(
                        children: [
                          Icon(Icons.assessment),
                          SizedBox(width: 8),
                          Text('Esporta statistiche'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export_csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart),
                          SizedBox(width: 8),
                          Text('Esporta CSV'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ============================================================
            // HEADER "OGGI" con barretta laterale
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Oggi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // CARD PROGRESSO GIORNALIERO
            // ============================================================
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.today,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progresso di oggi',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${stats.percentuale.toStringAsFixed(0)}% completato',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${stats.completatiOggi}/${stats.totale}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: stats.totale > 0
                            ? stats.percentuale / 100
                            : 0,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceVariant,
                      ),
                    ),
                    if (stats.migliorStreak > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Miglior streak: ${stats.migliorStreak} giorni',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ============================================================
            // HEADER "LE TUE ABITUDINI"
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Le tue abitudini',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // LISTA ABITUDINI
            // ============================================================
            habitsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      const Text('Errore nel caricamento'),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(habitsProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (habits) {
                if (habits.isEmpty) {
                  return SliverFillRemaining(
                    child: _HabitsEmptyState(
                      onAdd: () => _showAddDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = habits[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HabitCard(
                            habit: habit,
                            onToggle: () {
                              ref
                                  .read(habitsProvider.notifier)
                                  .toggleCompletamento(
                                    habit.id,
                                    DateTime.now(),
                                  );
                            },
                            onEdit: () {
                              _showEditDialog(context, ref, habit);
                            },
                            onDelete: () {
                              _confirmDelete(context, ref, habit);
                            },
                          ),
                        );
                      },
                      childCount: habits.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  // ==================================================================
  // MENU
  // ==================================================================

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) {
    switch (action) {
      case 'import':
        _showImportDialog(context, ref);
        break;

      case 'export':
        _exportData(context, ref, 'json');
        break;

      case 'export_stats':
        _showExportStatsDialog(context, ref);
        break;

      case 'export_csv':
        _exportData(context, ref, 'csv');
        break;
    }
  }

  // ==================================================================
  // EXPORT DATI
  // ==================================================================

  Future<void> _exportData(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    final habits = ref.read(habitsProvider).value ?? [];

    if (habits.isEmpty) {
      _showSnackBar(context, 'Nessun dato da esportare');
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );

    try {
      late final File file;

      if (format == 'csv') {
        file = await HabitsImportExportService.exportStatsToCsv(habits);
      } else {
        file = await HabitsImportExportService.exportToJson(habits);
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Share.shareXFiles([XFile(file.path)]);

      if (context.mounted) {
        _showSnackBar(context, 'Esportati ${habits.length} habits');
      }
    } catch (e) {
      if (context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
        _showSnackBar(context, 'Errore durante l\'esportazione: $e');
      }
    }
  }

  // ==================================================================
  // EXPORT STATISTICHE - DIALOG
  // ==================================================================

  void _showExportStatsDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Esporta Statistiche'),
          content: const Text('Scegli il formato:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportStats(context, ref, 'json');
              },
              child: const Text('JSON'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportStats(context, ref, 'csv');
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  // ==================================================================
  // EXPORT STATISTICHE
  // ==================================================================

  Future<void> _exportStats(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    final habits = ref.read(habitsProvider).value ?? [];

    if (habits.isEmpty) {
      _showSnackBar(context, 'Nessun dato da esportare');
      return;
    }

    try {
      late final File file;

      if (format == 'json') {
        file = await HabitsImportExportService.exportStatsToJson(habits);
      } else {
        file = await HabitsImportExportService.exportStatsToCsv(habits);
      }

      await Share.shareXFiles([XFile(file.path)]);

      if (context.mounted) {
        _showSnackBar(context, 'Statistiche esportate!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Errore durante l\'esportazione: $e');
      }
    }
  }

  // ==================================================================
  // IMPORT DIALOG
  // ==================================================================

  void _showImportDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Importa Habits'),
          content: const Text('Come vuoi importare i dati?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _importHabits(context, ref, merge: true);
              },
              child: const Text('Unisci'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _importHabits(context, ref, merge: false);
              },
              child: const Text('Sostituisci'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  // ==================================================================
  // IMPORT
  // ==================================================================

  Future<void> _importHabits(
    BuildContext context,
    WidgetRef ref, {
    required bool merge,
  }) async {
    try {
      final habits = await HabitsImportExportService.importFromJson();

      if (habits.isEmpty) {
        if (context.mounted) {
          _showSnackBar(context, 'Nessun dato importato');
        }
        return;
      }

      if (merge) {
        final aggiunti = await ref
            .read(habitsProvider.notifier)
            .importHabits(habits);

        if (context.mounted) {
          _showSnackBar(context, 'Importati $aggiunti nuovi habits');
        }
        return;
      }

      await ref.read(habitsProvider.notifier).replaceAllHabits(habits);

      if (context.mounted) {
        _showSnackBar(context, 'Sostituiti ${habits.length} habits');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Errore durante l\'importazione: $e');
      }
    }
  }

  // ==================================================================
  // ADD / EDIT / DELETE
  // ==================================================================

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddHabitDialog(ref: ref),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddHabitDialog(ref: ref, habit: habit),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Eliminare questa abitudine?'),
          content: Text('"${habit.nome}" verrà eliminata definitivamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(habitsProvider.notifier).deleteHabit(habit.id);
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  // ==================================================================
  // SNACKBAR
  // ==================================================================

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ======================================================================
// STATO VUOTO coerente con le altre pagine
// ======================================================================

class _HabitsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _HabitsEmptyState({required this.onAdd});

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
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessuna abitudine',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi la tua prima abitudine per iniziare\nScorri verso il basso per aggiornare',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi abitudine'),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// DIALOG AGGIUNTA / MODIFICA ABITUDINE — ridisegnato in stile coerente
// ======================================================================

class _AddHabitDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Habit? habit;

  const _AddHabitDialog({
    required this.ref,
    this.habit,
  });

  @override
  ConsumerState<_AddHabitDialog> createState() {
    return _AddHabitDialogState();
  }
}

class _AddHabitDialogState extends ConsumerState<_AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _descrizioneController;
  late final TextEditingController _obiettivoController;

  String _icona = '✅';
  String _colore = '#2196F3';

  bool get isEditing => widget.habit != null;

  final List<String> _icone = [
    '✅',
    '💧',
    '📚',
    '🏃',
    '🧘',
    '🥗',
    '😴',
    '💪',
    '🎯',
    '📝',
    '🎨',
    '🎵',
    '🌅',
    '🚭',
    '💰',
    '🙏',
  ];

  final Map<String, String> _colori = {
    'Blu': '#2196F3',
    'Verde': '#4CAF50',
    'Rosso': '#F44336',
    'Arancione': '#FF9800',
    'Viola': '#9C27B0',
    'Rosa': '#E91E63',
    'Teal': '#009688',
    'Indaco': '#3F51B5',
  };

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(
      text: widget.habit?.nome ?? '',
    );
    _descrizioneController = TextEditingController(
      text: widget.habit?.descrizione ?? '',
    );
    _obiettivoController = TextEditingController(
      text: widget.habit?.obiettivoMensile.toString() ?? '30',
    );

    if (widget.habit != null) {
      _icona = widget.habit!.icona;
      _colore = widget.habit!.colore;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    _obiettivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================================
                // HEADER
                // ========================================================
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
                    Text(
                      isEditing ? 'Modifica Abitudine' : 'Nuova Abitudine',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ========================================================
                // NOME
                // ========================================================
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Es. Bere acqua',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci un nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ========================================================
                // DESCRIZIONE
                // ========================================================
                TextFormField(
                  controller: _descrizioneController,
                  decoration: InputDecoration(
                    labelText: 'Descrizione (opzionale)',
                    hintText: 'Es. Bere 2 litri al giorno',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // ========================================================
                // ICONA
                // ========================================================
                Row(
                  children: [
                    Icon(
                      Icons.emoji_emotions_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Icona',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icone.map((icona) {
                    final selezionata = icona == _icona;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _icona = icona;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selezionata
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selezionata
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selezionata ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          icona,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ========================================================
                // COLORE
                // ========================================================
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Colore',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colori.entries.map((entry) {
                    final selezionato = entry.value == _colore;
                    final color = Color(
                      int.parse(
                        entry.value.replaceFirst('#', '0xFF'),
                      ),
                    );
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _colore = entry.value;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selezionato
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selezionato
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: selezionato
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ========================================================
                // OBIETTIVO
                // ========================================================
                TextFormField(
                  controller: _obiettivoController,
                  decoration: InputDecoration(
                    labelText: 'Obiettivo mensile',
                    hintText: 'Quante volte al mese',
                    suffixText: 'volte',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci un obiettivo';
                    }
                    final numero = int.tryParse(value);
                    if (numero == null) {
                      return 'Numero non valido';
                    }
                    if (numero <= 0) {
                      return 'Deve essere maggiore di 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ========================================================
                // BOTTONI
                // ========================================================
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
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

  // ==================================================================
  // SALVA
  // ==================================================================

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final descrizione = _descrizioneController.text.trim();
    final obiettivo = int.parse(_obiettivoController.text.trim());

    final habit = Habit(
      id: widget.habit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      descrizione: descrizione.isEmpty ? null : descrizione,
      icona: _icona,
      colore: _colore,
      dataCreazione: widget.habit?.dataCreazione ?? DateTime.now(),
      completamenti: widget.habit?.completamenti ?? [],
      obiettivoMensile: obiettivo,
    );

    if (isEditing) {
      widget.ref.read(habitsProvider.notifier).updateHabit(habit);
    } else {
      widget.ref.read(habitsProvider.notifier).addHabit(habit);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}