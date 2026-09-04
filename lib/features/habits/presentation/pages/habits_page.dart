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
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          PopupMenuButton<String>(
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

      body: Column(
        children: [
          // ============================================================
          // PROGRESSO GIORNALIERO
          // ============================================================

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Oggi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.completatiOggi}/${stats.totale}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                LinearProgressIndicator(
                  value: stats.totale > 0
                      ? stats.percentuale / 100
                      : 0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 8),

                Text(
                  '${stats.percentuale.toStringAsFixed(0)}% completato',
                  style: theme.textTheme.bodySmall,
                ),

                if (stats.migliorStreak > 0) ...[
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Miglior streak: ${stats.migliorStreak} giorni',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ============================================================
          // LISTA ABITUDINI
          // ============================================================

          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Errore: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              data: (habits) {
                if (habits.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Nessuna abitudine'),
                        SizedBox(height: 8),
                        Text('Aggiungi la tua prima abitudine!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    100,
                  ),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
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
                          _showEditDialog(
                            context,
                            ref,
                            habit,
                          );
                        },

                        onDelete: () {
                          _confirmDelete(
                            context,
                            ref,
                            habit,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context, ref);
        },
        child: const Icon(Icons.add),
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
        _exportData(
          context,
          ref,
          'json',
        );
        break;

      case 'export_stats':
        _showExportStatsDialog(
          context,
          ref,
        );
        break;

      case 'export_csv':
        _exportData(
          context,
          ref,
          'csv',
        );
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
      _showSnackBar(
        context,
        'Nessun dato da esportare',
      );
      return;
    }

    // ---------------------------------------------------------------
    // Mostra loading
    // ---------------------------------------------------------------

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
      // -------------------------------------------------------------
      // Generazione file
      // -------------------------------------------------------------

      late final File file;

      if (format == 'csv') {
        file = await HabitsImportExportService.exportStatsToCsv(
          habits,
        );
      } else {
        file = await HabitsImportExportService.exportToJson(
          habits,
        );
      }

      // -------------------------------------------------------------
      // Chiudi il dialog PRIMA di Share
      // -------------------------------------------------------------

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
      }

      // -------------------------------------------------------------
      // Condivisione
      // -------------------------------------------------------------

      await Share.shareXFiles(
        [
          XFile(file.path),
        ],
      );

      // -------------------------------------------------------------
      // Feedback
      // -------------------------------------------------------------

      if (context.mounted) {
        _showSnackBar(
          context,
          'Esportati ${habits.length} habits',
        );
      }
    } catch (e) {
      // -------------------------------------------------------------
      // Chiudi eventuale loading
      // -------------------------------------------------------------

      if (context.mounted) {
        final navigator = Navigator.of(
          context,
          rootNavigator: true,
        );

        if (navigator.canPop()) {
          navigator.pop();
        }

        _showSnackBar(
          context,
          'Errore durante l\'esportazione: $e',
        );
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
          title: const Text(
            'Esporta Statistiche',
          ),
          content: const Text(
            'Scegli il formato:',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _exportStats(
                  context,
                  ref,
                  'json',
                );
              },
              child: const Text('JSON'),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _exportStats(
                  context,
                  ref,
                  'csv',
                );
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
      _showSnackBar(
        context,
        'Nessun dato da esportare',
      );
      return;
    }

    try {
      late final File file;

      if (format == 'json') {
        file = await HabitsImportExportService.exportStatsToJson(
          habits,
        );
      } else {
        file = await HabitsImportExportService.exportStatsToCsv(
          habits,
        );
      }

      await Share.shareXFiles(
        [
          XFile(file.path),
        ],
      );

      if (context.mounted) {
        _showSnackBar(
          context,
          'Statistiche esportate!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Errore durante l\'esportazione: $e',
        );
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
          title: const Text(
            'Importa Habits',
          ),
          content: const Text(
            'Come vuoi importare i dati?',
          ),
          actions: [
            // ---------------------------------------------------------
            // UNISCI
            // ---------------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _importHabits(
                  context,
                  ref,
                  merge: true,
                );
              },
              child: const Text('Unisci'),
            ),

            // ---------------------------------------------------------
            // SOSTITUISCI
            // ---------------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _importHabits(
                  context,
                  ref,
                  merge: false,
                );
              },
              child: const Text('Sostituisci'),
            ),

            // ---------------------------------------------------------
            // ANNULLA
            // ---------------------------------------------------------

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
      final habits =
          await HabitsImportExportService.importFromJson();

      if (habits.isEmpty) {
        if (context.mounted) {
          _showSnackBar(
            context,
            'Nessun dato importato',
          );
        }

        return;
      }

      // ---------------------------------------------------------------
      // MERGE
      // ---------------------------------------------------------------

      if (merge) {
        final aggiunti = await ref
            .read(habitsProvider.notifier)
            .importHabits(habits);

        if (context.mounted) {
          _showSnackBar(
            context,
            'Importati $aggiunti nuovi habits',
          );
        }

        return;
      }

      // ---------------------------------------------------------------
      // REPLACE
      // ---------------------------------------------------------------

      await ref
          .read(habitsProvider.notifier)
          .replaceAllHabits(habits);

      if (context.mounted) {
        _showSnackBar(
          context,
          'Sostituiti ${habits.length} habits',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Errore durante l\'importazione: $e',
        );
      }
    }
  }

  // ==================================================================
  // ADD HABIT
  // ==================================================================

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return _AddHabitDialog(
          ref: ref,
        );
      },
    );
  }

  // ==================================================================
  // EDIT HABIT
  // ==================================================================

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return _AddHabitDialog(
          ref: ref,
          habit: habit,
        );
      },
    );
  }

  // ==================================================================
  // DELETE CONFIRMATION
  // ==================================================================

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminare questa abitudine?',
          ),

          content: Text(
            '"${habit.nome}" verrà eliminata definitivamente.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),

            ElevatedButton(
              onPressed: () {
                ref
                    .read(habitsProvider.notifier)
                    .deleteHabit(habit.id);

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

  void _showSnackBar(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}

// ======================================================================
// DIALOG AGGIUNTA / MODIFICA ABITUDINE
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

class _AddHabitDialogState
    extends ConsumerState<_AddHabitDialog> {
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

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Modifica Abitudine'
            : 'Nuova Abitudine',
      ),

      content: Form(
        key: _formKey,

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ========================================================
              // NOME
              // ========================================================

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Es. Bere acqua',
                ),
                textCapitalization:
                    TextCapitalization.sentences,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
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
                decoration: const InputDecoration(
                  labelText: 'Descrizione (opzionale)',
                  hintText: 'Es. Bere 2 litri al giorno',
                ),
                textCapitalization:
                    TextCapitalization.sentences,
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // ========================================================
              // ICONA
              // ========================================================

              Text(
                'Icona',
                style: theme.textTheme.labelLarge,
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icone.map((icona) {
                  final selezionata =
                      icona == _icona;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _icona = icona;
                      });
                    },

                    child: Container(
                      padding:
                          const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: selezionata
                            ? theme
                                .colorScheme
                                .primaryContainer
                            : Colors.transparent,

                        borderRadius:
                            BorderRadius.circular(8),

                        border: Border.all(
                          color: selezionata
                              ? theme
                                  .colorScheme
                                  .primary
                              : Colors.grey[300]!,
                        ),
                      ),

                      child: Text(
                        icona,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ========================================================
              // COLORE
              // ========================================================

              Text(
                'Colore',
                style: theme.textTheme.labelLarge,
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colori.entries.map((entry) {
                  final selezionato =
                      entry.value == _colore;

                  final color = Color(
                    int.parse(
                      entry.value.replaceFirst(
                        '#',
                        '0xFF',
                      ),
                    ),
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _colore = entry.value;
                      });
                    },

                    child: Container(
                      width: 36,
                      height: 36,

                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: selezionato
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ========================================================
              // OBIETTIVO
              // ========================================================

              TextFormField(
                controller: _obiettivoController,

                decoration:
                    const InputDecoration(
                  labelText: 'Obiettivo mensile',
                  hintText:
                      'Quante volte al mese',
                  suffixText: 'volte',
                ),

                keyboardType:
                    TextInputType.number,

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Inserisci un obiettivo';
                  }

                  final numero =
                      int.tryParse(value);

                  if (numero == null) {
                    return 'Numero non valido';
                  }

                  if (numero <= 0) {
                    return 'Deve essere maggiore di 0';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),

      // ==============================================================
      // AZIONI
      // ==============================================================

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annulla'),
        ),

        ElevatedButton(
          onPressed: _save,
          child: Text(
            isEditing
                ? 'Salva'
                : 'Aggiungi',
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // SALVA
  // ==================================================================

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nome = _nomeController.text.trim();

    final descrizione =
        _descrizioneController.text.trim();

    final obiettivo =
        int.parse(
          _obiettivoController.text.trim(),
        );

    final habit = Habit(
      id: widget.habit?.id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),

      nome: nome,

      descrizione: descrizione.isEmpty
          ? null
          : descrizione,

      icona: _icona,

      colore: _colore,

      dataCreazione:
          widget.habit?.dataCreazione ??
              DateTime.now(),

      completamenti:
          widget.habit?.completamenti ??
              [],

      obiettivoMensile: obiettivo,
    );

    if (isEditing) {
      widget.ref
          .read(habitsProvider.notifier)
          .updateHabit(habit);
    } else {
      widget.ref
          .read(habitsProvider.notifier)
          .addHabit(habit);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}