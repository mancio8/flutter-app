import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/rifornimento.dart';
import '../../../../core/models/veicolo.dart';
import '../../../../core/widgets/refreshable_widgets.dart';
import '../../providers/rifornimenti_provider.dart';
import '../../services/rifornimenti_export_service.dart';
import '../widgets/rifornimento_card.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class RifornimentiPage extends ConsumerWidget {
  const RifornimentiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rifornimentiAsync = ref.watch(rifornimentiProvider);
    final veicoliAsync = ref.watch(veicoliProvider);
    final veicoloSelezionato = ref.watch(veicoloSelezionatoProvider);
    final stats = ref.watch(rifornimentiStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rifornimenti'),
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
      body: Column(
        children: [
          _VeicoloSelector(
            veicoliAsync: veicoliAsync,
            veicoloSelezionato: veicoloSelezionato,
            onChanged: (veicoloId) {
              ref.read(veicoloSelezionatoProvider.notifier).state = veicoloId;
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Totale Speso',
                  value: '€${stats.totaleSpeso.toStringAsFixed(2)}',
                ),
                _StatItem(
                  label: 'Totale Litri',
                  value: '${stats.totaleLitri.toStringAsFixed(1)}L',
                ),
                _StatItem(
                  label: 'Prezzo Medio',
                  value: '€${stats.prezzoMedio.toStringAsFixed(3)}/L',
                ),
              ],
            ),
          ),
          Expanded(
            child: rifornimentiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => RefreshableError(
                message: 'Errore: $error',
                onRetry: () => ref.refresh(rifornimentiProvider.future),
              ),
              data: (rifornimenti) {
                if (rifornimenti.isEmpty) {
                  return RefreshableEmptyState(
                    onRefresh: () => ref.refresh(rifornimentiProvider.future),
                    icon: Icons.local_gas_station_outlined,
                    title: 'Nessun rifornimento registrato',
                    subtitle: 'Aggiungi il tuo primo rifornimento\nScorri verso il basso per aggiornare',
                  );
                }

                return RefreshableList(
                  onRefresh: () => ref.refresh(rifornimentiProvider.future),
                  padding: const EdgeInsets.all(16),
                  itemCount: rifornimenti.length,
                  itemBuilder: (context, index) {
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
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
    return veicoliAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Errore: $e'),
      data: (veicoli) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String?>(
            value: veicoloSelezionato,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tutti i veicoli'),
              ),
              ...veicoli.map(
                (v) =>
                    DropdownMenuItem<String?>(value: v.id, child: Text(v.nome)),
              ),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
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

    return AlertDialog(
      title: Text(isEditing ? 'Modifica Rifornimento' : 'Nuovo Rifornimento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              veicoliAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Errore: $e'),
                data: (veicoli) {
                  return DropdownButtonFormField<String>(
                    value: _veicoloSelezionato,
                    decoration: const InputDecoration(labelText: 'Veicolo'),
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
                decoration: const InputDecoration(
                  labelText: 'Litri',
                  suffixText: 'L',
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
                decoration: const InputDecoration(
                  labelText: 'Costo Totale',
                  prefixText: '€ ',
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
              TextFormField(
                controller: _chilometraggioController,
                decoration: const InputDecoration(
                  labelText: 'Chilometraggio (opzionale)',
                  suffixText: 'km',
                  hintText: 'Lascia vuoto se non lo sai',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoCarburante,
                decoration: const InputDecoration(labelText: 'Tipo Carburante'),
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
                decoration: const InputDecoration(
                  labelText: 'Note (opzionali)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => _save(),
          child: Text(isEditing ? 'Salva Modifiche' : 'Salva'),
        ),
      ],
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