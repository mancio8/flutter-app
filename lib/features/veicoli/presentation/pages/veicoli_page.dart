// File: lib/features/veicoli/presentation/pages/veicoli_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/veicolo.dart';
import '../../providers/veicoli_provider.dart';

class VeicoliPage extends ConsumerWidget {
  const VeicoliPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final veicoliAsync = ref.watch(veicoliProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(veicoliProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar coerente con le altre pagine
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
                    Text(
                      'I Miei Veicoli',
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
                      Icons.garage_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Contatore veicoli
            SliverToBoxAdapter(
              child: veicoliAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (veicoli) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    '${veicoli.length} ${veicoli.length == 1 ? 'veicolo' : 'veicoli'} nel garage',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Lista veicoli
            veicoliAsync.when(
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
                          ref.invalidate(veicoliProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (veicoli) {
                if (veicoli.isEmpty) {
                  return SliverFillRemaining(
                    child: _VeicoliEmptyState(
                      onAdd: () => _showAddVeicoloDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final veicolo = veicoli[index];
                        return _VeicoloCard(
                          veicolo: veicolo,
                          onEdit: () =>
                              _showEditVeicoloDialog(context, ref, veicolo),
                          onDelete: () =>
                              _confirmDelete(context, ref, veicolo),
                        );
                      },
                      childCount: veicoli.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVeicoloDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _showAddVeicoloDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _VeicoloDialog(ref: ref),
    );
  }

  void _showEditVeicoloDialog(
    BuildContext context,
    WidgetRef ref,
    Veicolo veicolo,
  ) {
    showDialog(
      context: context,
      builder: (context) => _VeicoloDialog(ref: ref, veicolo: veicolo),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Veicolo veicolo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

// Stato vuoto coerente con BibliotecaPage / WishlistPage / RifornimentiPage
class _VeicoliEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _VeicoliEmptyState({required this.onAdd});

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
              Icons.directions_car_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun veicolo registrato',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il tuo primo veicolo per iniziare\nScorri verso il basso per aggiornare',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi veicolo'),
          ),
        ],
      ),
    );
  }
}

// Card veicolo ridisegnata con stile coerente
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icona in box colorato
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.directions_car,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            // Nome + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    veicolo.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Badge targa e tipo come chip
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (veicolo.targa != null && veicolo.targa!.isNotEmpty)
                        _InfoBadge(
                          icon: Icons.badge_outlined,
                          label: veicolo.targa!,
                          theme: theme,
                        ),
                      if (veicolo.tipo != null && veicolo.tipo!.isNotEmpty)
                        _InfoBadge(
                          icon: Icons.category_outlined,
                          label: veicolo.tipo!,
                          theme: theme,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Azioni
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Modifica',
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Elimina',
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Badge per targa / tipo
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
                // Header con icona
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
                      isEditing ? 'Modifica Veicolo' : 'Nuovo Veicolo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome Veicolo',
                    hintText: 'Es. Fiat Panda',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  decoration: InputDecoration(
                    labelText: 'Targa (opzionale)',
                    hintText: 'Es. AB123CD',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue:
                      _tipoController.text.isEmpty ? null : _tipoController.text,
                  decoration: InputDecoration(
                    labelText: 'Tipo Veicolo (opzionale)',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 24),

                // Bottoni in stile _AddBookDialog / _AddRifornimentoDialog
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
    if (_formKey.currentState!.validate()) {
      final veicolo = Veicolo(
        id: widget.veicolo?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        targa: _targaController.text.trim().isEmpty
            ? null
            : _targaController.text.trim(),
        tipo: _tipoController.text.trim().isEmpty
            ? null
            : _tipoController.text.trim(),
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