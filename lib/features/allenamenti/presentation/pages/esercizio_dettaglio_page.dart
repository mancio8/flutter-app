import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/models/esercizio.dart';
import '../../../../core/models/serie_esercizio.dart';
import '../../providers/allenamenti_provider.dart';

class EsercizioDettaglioPage extends ConsumerWidget {
  final Esercizio esercizio;

  const EsercizioDettaglioPage({super.key, required this.esercizio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serieAsync = ref.watch(seriePerEsercizioProvider(esercizio.id));
    final progressoAsync = ref.watch(progressoEsercizioProvider(esercizio.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(esercizio.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteEsercizio(context, ref),
            tooltip: 'Elimina esercizio',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Grafico progressi ---
          Text(
            'Progressione peso massimo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          progressoAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Errore: $e'),
            data: (punti) {
              if (punti.length < 2) {
                return Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Servono almeno 2 sessioni per il grafico'),
                );
              }
              return _ProgressoChart(punti: punti);
            },
          ),

          const SizedBox(height: 24),

          // --- Storico serie ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storico',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              serieAsync.when(
                data: (serie) => Text(
                  '${serie.length} serie registrate',
                  style: theme.textTheme.bodySmall,
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          serieAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Errore: $e'),
            data: (serie) {
              if (serie.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Nessuna serie registrata')),
                );
              }
              final ordinateDesc = List<SerieEsercizio>.from(serie)
                ..sort((a, b) => b.data.compareTo(a.data));

              return Column(
                children: ordinateDesc
                    .map((s) => _SerieTile(serie: s))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSerieDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registra serie'),
      ),
    );
  }

  void _showAddSerieDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddSerieDialog(ref: ref, esercizioId: esercizio.id),
    );
  }

  void _confirmDeleteEsercizio(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare questo esercizio?'),
          content: Text(
            '"${esercizio.nome}" e tutto il suo storico '
            'verranno eliminati definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annulla'),
            ),

            ElevatedButton(
              onPressed: () async {
                // 1. Elimina dal database/storage
                await ref
                    .read(eserciziProvider.notifier)
                    .deleteEsercizio(esercizio.id);

                // 2. Chiude il dialog
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // 3. Torna alla lista
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
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
}

// --- Grafico con fl_chart ---
class _ProgressoChart extends StatelessWidget {
  final List<PuntoProgresso> punti;

  const _ProgressoChart({required this.punti});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = punti.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.pesoMassimo);
    }).toList();

    final minY = punti
        .map((p) => p.pesoMassimo)
        .reduce((a, b) => a < b ? a : b);
    final maxY = punti
        .map((p) => p.pesoMassimo)
        .reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2 + 2;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
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
      child: LineChart(
        LineChartData(
          minY: (minY - padding).clamp(0, double.infinity),
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (punti.length / 4)
                    .clamp(1, double.infinity)
                    .roundToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= punti.length)
                    return const SizedBox();
                  final data = punti[index].data;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${data.day}/${data.month}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final punto = punti[s.x.toInt()];
                return LineTooltipItem(
                  '${punto.pesoMassimo.toStringAsFixed(1)} kg\n${punto.data.day}/${punto.data.month}/${punto.data.year}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: punti.length <= 15),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SerieTile extends ConsumerWidget {
  final SerieEsercizio serie;

  const _SerieTile({required this.serie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.fitness_center, size: 18),
        ),
        title: Text('${serie.peso} kg × ${serie.ripetizioni} rip.'),
        subtitle: Text(
          '${serie.data.day}/${serie.data.month}/${serie.data.year}'
          '${serie.note != null && serie.note!.isNotEmpty ? ' — ${serie.note}' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () {
            ref.read(serieProvider.notifier).deleteSerie(serie.id);
          },
        ),
      ),
    );
  }
}

// --- Dialog registra serie ---
class _AddSerieDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String esercizioId;

  const _AddSerieDialog({required this.ref, required this.esercizioId});

  @override
  ConsumerState<_AddSerieDialog> createState() => _AddSerieDialogState();
}

class _AddSerieDialogState extends ConsumerState<_AddSerieDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _ripetizioniController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _data = DateTime.now();

  @override
  void dispose() {
    _pesoController.dispose();
    _ripetizioniController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registra serie'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Inserisci il peso';
                  if (double.tryParse(v.replaceAll(',', '.')) == null)
                    return 'Numero non valido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ripetizioniController,
                decoration: const InputDecoration(labelText: 'Ripetizioni'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Inserisci le ripetizioni';
                  if (int.tryParse(v) == null) return 'Numero non valido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _data,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _data = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data'),
                  child: Text('${_data.day}/${_data.month}/${_data.year}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (opzionali)',
                ),
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            widget.ref
                .read(serieProvider.notifier)
                .addSerie(
                  SerieEsercizio(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    esercizioId: widget.esercizioId,
                    peso: double.parse(
                      _pesoController.text.replaceAll(',', '.'),
                    ),
                    ripetizioni: int.parse(_ripetizioniController.text),
                    data: _data,
                    note: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
