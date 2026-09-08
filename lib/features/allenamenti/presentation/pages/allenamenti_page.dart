import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/esercizio.dart';
import '../../providers/allenamenti_provider.dart';
import 'esercizio_dettaglio_page.dart';

class AllenamentiPage extends ConsumerWidget {
  const AllenamentiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eserciziAsync = ref.watch(eserciziProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Allenamenti')),
      body: eserciziAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (esercizi) {
          if (esercizi.isEmpty) {
            return const Center(child: Text('Nessun esercizio. Aggiungine uno.'));
          }

          // Raggruppa per categoria
          final Map<CategoriaEsercizio, List<Esercizio>> perCategoria = {};
          for (final e in esercizi) {
            perCategoria.putIfAbsent(e.categoria, () => []).add(e);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: perCategoria.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      entry.key.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  ...entry.value.map((esercizio) => _EsercizioTile(esercizio: esercizio)),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEsercizioDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEsercizioDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _AddEsercizioDialog(ref: ref));
  }
}

class _EsercizioTile extends ConsumerWidget {
  final Esercizio esercizio;

  const _EsercizioTile({required this.esercizio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ultimaSerieAsync = ref.watch(ultimaSerieProvider(esercizio.id));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
        ),
        title: Text(esercizio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: ultimaSerieAsync.when(
          data: (ultima) => ultima == null
              ? const Text('Nessuna serie registrata')
              : Text('Ultimo: ${ultima.peso} kg × ${ultima.ripetizioni} rip.'),
          loading: () => const Text('...'),
          error: (_, __) => const Text('—'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EsercizioDettaglioPage(esercizio: esercizio),
            ),
          );
        },
      ),
    );
  }
}

class _AddEsercizioDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AddEsercizioDialog({required this.ref});

  @override
  ConsumerState<_AddEsercizioDialog> createState() => _AddEsercizioDialogState();
}

class _AddEsercizioDialogState extends ConsumerState<_AddEsercizioDialog> {
  final _nomeController = TextEditingController();
  CategoriaEsercizio _categoria = CategoriaEsercizio.altro;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo esercizio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomeController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome esercizio'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CategoriaEsercizio>(
            value: _categoria,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: CategoriaEsercizio.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _categoria = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(
          onPressed: () {
            if (_nomeController.text.trim().isEmpty) return;
            widget.ref.read(eserciziProvider.notifier).addEsercizio(
                  Esercizio(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nome: _nomeController.text.trim(),
                    categoria: _categoria,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}