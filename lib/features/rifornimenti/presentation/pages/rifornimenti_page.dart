// File: lib/features/rifornimenti/presentation/pages/rifornimenti_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/rifornimento.dart';
import '../../../../core/models/veicolo.dart';
import '../../providers/rifornimenti_provider.dart';
import '../../services/rifornimenti_export_service.dart';
import '../widgets/rifornimento_card.dart';

class RifornimentiPage extends ConsumerWidget {
  const RifornimentiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rifornimentiAsync = ref.watch(rifornimentiProvider);
    final veicoliAsync = ref.watch(veicoliProvider);
    final veicoloSelezionato = ref.watch(veicoloSelezionatoProvider);
    final stats = ref.watch(rifornimentiStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(rifornimentiProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar personalizzato come BibliotecaPage
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
                    const Icon(Icons.local_gas_station, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Rifornimenti',
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
                      Icons.local_gas_station_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => _importJson(context, ref),
                  tooltip: 'Importa JSON',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _exportJson(context, ref),
                  tooltip: 'Esporta JSON',
                ),
              ],
            ),

            // Selettore veicolo
            SliverToBoxAdapter(
              child: _VeicoloSelector(
                veicoliAsync: veicoliAsync,
                veicoloSelezionato: veicoloSelezionato,
                onChanged: (veicoloId) {
                  ref.read(veicoloSelezionatoProvider.notifier).state =
                      veicoloId;
                },
              ),
            ),

            // Statistiche
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Totale Speso',
                      value: '€${stats.totaleSpeso.toStringAsFixed(2)}',
                      icon: Icons.euro,
                    ),
                    _StatItem(
                      label: 'Totale Litri',
                      value: '${stats.totaleLitri.toStringAsFixed(1)}L',
                      icon: Icons.local_gas_station,
                    ),
                    _StatItem(
                      label: 'Prezzo Medio',
                      value: '€${stats.prezzoMedio.toStringAsFixed(3)}/L',
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
              ),
            ),

            // Contatore rifornimenti
            SliverToBoxAdapter(
              child: rifornimentiAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (rifornimenti) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${rifornimenti.length} rifornimenti registrati',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Lista rifornimenti
            rifornimentiAsync.when(
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
                          ref.invalidate(rifornimentiProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (rifornimenti) {
                if (rifornimenti.isEmpty) {
                  return SliverFillRemaining(
                    child: _RifornimentiEmptyState(
                      onAdd: () => _showAddDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rifornimento = rifornimenti[index];
                        return RifornimentoCard(
                          rifornimento: rifornimento,
                          onDelete: () {
                            ref
                                .read(rifornimentiProvider.notifier)
                                .deleteRifornimento(rifornimento.id);
                          },
                          onEdit: () {
                            _showEditDialog(context, ref, rifornimento);
                          },
                        );
                      },
                      childCount: rifornimenti.length,
                    ),
                  ),
                );
              },
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

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final rifornimenti = ref.read(rifornimentiProvider).value ?? [];

    if (rifornimenti.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun dato da esportare'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await RifornimentiExportService.exportAndShareJson(rifornimenti);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Esportati ${rifornimenti.length} rifornimenti'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'esportazione: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    if (!context.mounted) return;

    final merge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Importa rifornimenti'),
        content: const Text(
          'Vuoi aggiungere i rifornimenti importati a quelli esistenti '
          '(saltando i duplicati per id) oppure sostituire completamente la lista?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sostituisci'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unisci'),
          ),
        ],
      ),
    );

    if (merge == null) return;

    try {
      final count = await ref
          .read(rifornimentiProvider.notifier)
          .importRifornimenti(jsonString, merge: merge);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merge
                ? '$count nuovi rifornimenti importati'
                : '$count rifornimenti importati (lista sostituita)',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddRifornimentoDialog(ref: ref),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Rifornimento rifornimento,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddRifornimentoDialog(ref: ref, rifornimento: rifornimento),
    );
  }
}

// Selettore veicolo in stile "barra ordinamento" della biblioteca
class _VeicoloSelector extends StatelessWidget {
  final AsyncValue<List<Veicolo>> veicoliAsync;
  final String? veicoloSelezionato;
  final Function(String?) onChanged;

  const _VeicoloSelector({
    required this.veicoliAsync,
    required this.veicoloSelezionato,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return veicoliAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Errore: $e'),
      ),
      data: (veicoli) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Veicolo:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: veicoloSelezionato,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: theme.colorScheme.surface,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tutti i veicoli'),
                    ),
                    ...veicoli.map(
                      (v) => DropdownMenuItem<String?>(
                        value: v.id,
                        child: Text(v.nome),
                      ),
                    ),
                  ],
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// Stato vuoto coerente con BibliotecaPage / WishlistPage
class _RifornimentiEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _RifornimentiEmptyState({required this.onAdd});

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
              Icons.local_gas_station_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun rifornimento registrato',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il tuo primo rifornimento\nScorri verso il basso per aggiornare',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi rifornimento'),
          ),
        ],
      ),
    );
  }
}

class _AddRifornimentoDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Rifornimento? rifornimento;

  const _AddRifornimentoDialog({required this.ref, this.rifornimento});

  @override
  ConsumerState<_AddRifornimentoDialog> createState() =>
      _AddRifornimentoDialogState();
}

class _AddRifornimentoDialogState
    extends ConsumerState<_AddRifornimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _litriController;
  late final TextEditingController _costoController;
  late final TextEditingController _chilometraggioController;
  late final TextEditingController _noteController;

  DateTime _data = DateTime.now();
  String _tipoCarburante = 'Benzina';
  String? _veicoloSelezionato;

  bool get isEditing => widget.rifornimento != null;

  @override
  void initState() {
    super.initState();

    final rifornimento = widget.rifornimento;

    _litriController = TextEditingController(
      text: rifornimento?.litri.toString() ?? '',
    );
    _costoController = TextEditingController(
      text: rifornimento?.costo.toString() ?? '',
    );
    _chilometraggioController = TextEditingController(
      text: rifornimento?.chilometraggio?.toString() ?? '',
    );
    _noteController = TextEditingController(text: rifornimento?.note ?? '');

    if (rifornimento != null) {
      _data = rifornimento.data;
      _tipoCarburante = rifornimento.tipoCarburante;
      _veicoloSelezionato = rifornimento.veicoloId;
    }
  }

  @override
  void dispose() {
    _litriController.dispose();
    _costoController.dispose();
    _chilometraggioController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veicoliAsync = ref.watch(veicoliProvider);
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
                // Header con icona come _AddBookDialog
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
                      isEditing ? 'Modifica Rifornimento' : 'Nuovo Rifornimento',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Selettore veicolo
                veicoliAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Errore: $e'),
                  data: (veicoli) {
                    return DropdownButtonFormField<String>(
                      value: _veicoloSelezionato,
                      decoration: InputDecoration(
                        labelText: 'Veicolo',
                        prefixIcon: const Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: veicoli
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(v.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _veicoloSelezionato = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleziona un veicolo' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _litriController,
                  decoration: InputDecoration(
                    labelText: 'Litri',
                    suffixText: 'L',
                    prefixIcon: const Icon(Icons.local_gas_station),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci i litri';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Inserisci un numero valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _costoController,
                  decoration: InputDecoration(
                    labelText: 'Costo Totale',
                    prefixText: '€ ',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il costo';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Inserisci un numero valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Data picker in stile _AddBookDialog
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _data,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (date != null && mounted) {
                      setState(() {
                        _data = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${_data.day}/${_data.month}/${_data.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _chilometraggioController,
                  decoration: InputDecoration(
                    labelText: 'Chilometraggio (opzionale)',
                    suffixText: 'km',
                    hintText: 'Lascia vuoto se non lo sai',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _tipoCarburante,
                  decoration: InputDecoration(
                    labelText: 'Tipo Carburante',
                    prefixIcon: const Icon(Icons.local_gas_station_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Benzina', 'Diesel', 'GPL', 'Metano', 'Elettrico']
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoCarburante = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionali)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Bottoni in stile _AddBookDialog
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
                        onPressed: () => _save(),
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
    if (_formKey.currentState!.validate()) {
      final litri = double.parse(_litriController.text);
      final costo = double.parse(_costoController.text);
      final chilometraggio = _chilometraggioController.text.isEmpty
          ? null
          : double.parse(_chilometraggioController.text);

      if (isEditing) {
        final rifornimentoAggiornato = widget.rifornimento!.copyWith(
          veicoloId: _veicoloSelezionato,
          data: _data,
          litri: litri,
          costo: costo,
          prezzoPerLitro: costo / litri,
          tipoCarburante: _tipoCarburante,
          chilometraggio: chilometraggio,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          clearChilometraggio: _chilometraggioController.text.isEmpty,
          clearNote: _noteController.text.isEmpty,
        );

        widget.ref
            .read(rifornimentiProvider.notifier)
            .updateRifornimento(rifornimentoAggiornato);
      } else {
        final rifornimento = Rifornimento(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          veicoloId: _veicoloSelezionato,
          data: _data,
          litri: litri,
          costo: costo,
          prezzoPerLitro: costo / litri,
          tipoCarburante: _tipoCarburante,
          chilometraggio: chilometraggio,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );

        widget.ref
            .read(rifornimentiProvider.notifier)
            .addRifornimento(rifornimento);
      }

      Navigator.pop(context);
    }
  }
}