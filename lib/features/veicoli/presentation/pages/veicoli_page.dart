import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/veicolo.dart';
import '../../../../core/widgets/refreshable_widgets.dart';
import '../../providers/veicoli_provider.dart';

class VeicoliPage extends ConsumerWidget {
  const VeicoliPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final veicoliAsync = ref.watch(veicoliProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Veicoli'),
      ),
      body: veicoliAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => RefreshableError(
          message: 'Errore: $error',
          onRetry: () => ref.refresh(veicoliProvider.future),
        ),
        data: (veicoli) {
          if (veicoli.isEmpty) {
            return RefreshableEmptyState(
              onRefresh: () => ref.refresh(veicoliProvider.future),
              icon: Icons.directions_car_outlined,
              title: 'Nessun veicolo registrato',
              subtitle: 'Aggiungi il tuo primo veicolo per iniziare\nScorri verso il basso per aggiornare',
            );
          }

          return RefreshableList(
            onRefresh: () => ref.refresh(veicoliProvider.future),
            padding: const EdgeInsets.all(16),
            itemCount: veicoli.length,
            itemBuilder: (context, index) {
              final veicolo = veicoli[index];
              return _VeicoloCard(
                veicolo: veicolo,
                onEdit: () => _showEditVeicoloDialog(context, ref, veicolo),
                onDelete: () => _confirmDelete(context, ref, veicolo),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVeicoloDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Veicolo'),
      ),
    );
  }

  void _showAddVeicoloDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _VeicoloDialog(ref: ref),
    );
  }

  void _showEditVeicoloDialog(BuildContext context, WidgetRef ref, Veicolo veicolo) {
    showDialog(
      context: context,
      builder: (context) => _VeicoloDialog(ref: ref, veicolo: veicolo),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Veicolo veicolo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questo veicolo?'),
        content: Text('Il veicolo "${veicolo.nome}" verrà eliminato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(veicoliProvider.notifier).deleteVeicolo(veicolo.id);
              Navigator.pop(context);
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

class _VeicoloCard extends StatelessWidget {
  final Veicolo veicolo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VeicoloCard({
    required this.veicolo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.directions_car,
            color: theme.colorScheme.primary,
            size: 30,
          ),
        ),
        title: Text(
          veicolo.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (veicolo.targa != null) ...[
              const SizedBox(height: 4),
              Text('Targa: ${veicolo.targa}'),
            ],
            if (veicolo.tipo != null) ...[
              const SizedBox(height: 2),
              Text('Tipo: ${veicolo.tipo}'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Modifica',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Elimina',
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _VeicoloDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Veicolo? veicolo;

  const _VeicoloDialog({required this.ref, this.veicolo});

  @override
  ConsumerState<_VeicoloDialog> createState() => _VeicoloDialogState();
}

class _VeicoloDialogState extends ConsumerState<_VeicoloDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _targaController;
  late final TextEditingController _tipoController;

  bool get isEditing => widget.veicolo != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.veicolo?.nome ?? '');
    _targaController = TextEditingController(text: widget.veicolo?.targa ?? '');
    _tipoController = TextEditingController(text: widget.veicolo?.tipo ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _targaController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Modifica Veicolo' : 'Nuovo Veicolo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Veicolo',
                  hintText: 'Es. Fiat Panda',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome del veicolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targaController,
                decoration: const InputDecoration(
                  labelText: 'Targa (opzionale)',
                  hintText: 'Es. AB123CD',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipoController.text.isEmpty ? null : _tipoController.text,
                decoration: const InputDecoration(
                  labelText: 'Tipo Veicolo (opzionale)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                  DropdownMenuItem(value: 'Camion', child: Text('Camion')),
                  DropdownMenuItem(value: 'Furgone', child: Text('Furgone')),
                  DropdownMenuItem(value: 'Altro', child: Text('Altro')),
                ],
                onChanged: (value) {
                  _tipoController.text = value ?? '';
                },
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
          onPressed: _save,
          child: Text(isEditing ? 'Salva Modifiche' : 'Aggiungi'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final veicolo = Veicolo(
        id: widget.veicolo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        targa: _targaController.text.trim().isEmpty ? null : _targaController.text.trim(),
        tipo: _tipoController.text.trim().isEmpty ? null : _tipoController.text.trim(),
      );

      if (isEditing) {
        widget.ref.read(veicoliProvider.notifier).updateVeicolo(veicolo);
      } else {
        widget.ref.read(veicoliProvider.notifier).addVeicolo(veicolo);
      }

      Navigator.pop(context);
    }
  }
}