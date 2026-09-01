import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/rifornimento.dart';
import '../../../../core/models/veicolo.dart';
import '../../providers/rifornimenti_provider.dart';
import '../widgets/rifornimento_card.dart';

// La pagina principale per i rifornimenti
class RifornimentiPage extends ConsumerWidget {
  const RifornimentiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Osserva il provider per ottenere i dati
    final rifornimentiAsync = ref.watch(rifornimentiProvider);
    final veicoliAsync = ref.watch(veicoliProvider);
    final veicoloSelezionato = ref.watch(veicoloSelezionatoProvider);
    final stats = ref.watch(rifornimentiStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rifornimenti'),
      ),
      body: Column(
        children: [
          // Selettore veicolo
          _VeicoloSelector(
            veicoliAsync: veicoliAsync,
            veicoloSelezionato: veicoloSelezionato,
            onChanged: (veicoloId) {
              ref.read(veicoloSelezionatoProvider.notifier).state = veicoloId;
            },
          ),
          
          // Barra delle statistiche
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
          
          // Lista dei rifornimenti
          Expanded(
            child: rifornimentiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              
              error: (error, stackTrace) => Center(
                child: Text('Errore: $error'),
              ),
              
              data: (rifornimenti) {
                if (rifornimenti.isEmpty) {
                  return const Center(
                    child: Text('Nessun rifornimento registrato'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rifornimenti.length,
                  itemBuilder: (context, index) {
                    final rifornimento = rifornimenti[index];
                    return RifornimentoCard(
                      rifornimento: rifornimento,
                      onDelete: () {
                        ref.read(rifornimentiProvider.notifier)
                            .deleteRifornimento(rifornimento.id);
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddRifornimentoDialog(ref: ref),
    );
  }
}

// Widget per selezionare il veicolo
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
              ...veicoli.map((v) => DropdownMenuItem<String?>(
                value: v.id,
                child: Text(v.nome),
              )),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

// Widget per le statistiche
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

// Dialog per aggiungere un nuovo rifornimento
class _AddRifornimentoDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const _AddRifornimentoDialog({required this.ref});

  @override
  ConsumerState<_AddRifornimentoDialog> createState() => _AddRifornimentoDialogState();
}

class _AddRifornimentoDialogState extends ConsumerState<_AddRifornimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _litriController = TextEditingController();
  final _costoController = TextEditingController();
  final _chilometraggioController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _data = DateTime.now();
  String _tipoCarburante = 'Benzina';
  String? _veicoloSelezionato; // DICHIARAZIONE DELLA VARIABILE (mancava!)

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
      title: const Text('Nuovo Rifornimento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selezione veicolo
              veicoliAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Errore: $e'),
                data: (veicoli) {
                  return DropdownButtonFormField<String>(
                    value: _veicoloSelezionato,
                    decoration: const InputDecoration(
                      labelText: 'Veicolo',
                    ),
                    items: veicoli.map((v) => DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(v.nome),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _veicoloSelezionato = value;
                      });
                    },
                    validator: (value) => value == null ? 'Seleziona un veicolo' : null,
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Campo litri
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
              
              // Campo costo
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
              
              // Campo chilometraggio
              TextFormField(
                controller: _chilometraggioController,
                decoration: const InputDecoration(
                  labelText: 'Chilometraggio',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Dropdown tipo carburante
              DropdownButtonFormField<String>(
                value: _tipoCarburante,
                decoration: const InputDecoration(
                  labelText: 'Tipo Carburante',
                ),
                items: ['Benzina', 'Diesel', 'GPL', 'Metano', 'Elettrico']
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoCarburante = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Campo note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
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
          child: const Text('Salva'),
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

      final rifornimento = Rifornimento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        veicoloId: _veicoloSelezionato, // Ora la variabile esiste
        data: _data,
        litri: litri,
        costo: costo,
        prezzoPerLitro: costo / litri,
        tipoCarburante: _tipoCarburante,
        chilometraggio: chilometraggio,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      widget.ref.read(rifornimentiProvider.notifier).addRifornimento(rifornimento);
      Navigator.pop(context);
    }
  }
}