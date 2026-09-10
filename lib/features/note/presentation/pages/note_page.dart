import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/nota.dart';
import '../../providers/note_provider.dart';
import '../widgets/nota_card.dart';

class NotePage extends ConsumerWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteFiltrateProvider);
    final filtro = ref.watch(filtroCategoriaProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(noteProvider.notifier).refreshNote();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar coerente con Biblioteca/Raccolta
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
                    const Icon(Icons.sticky_note_2_outlined, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Note',
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
                      Icons.push_pin_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Filtro categorie — card con ombra invece di barra "nuda"
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoriaChip(
                        label: 'Tutte',
                        selezionata: filtro == null,
                        onTap: () =>
                            ref.read(filtroCategoriaProvider.notifier).state =
                                null,
                      ),
                      ...CategoriaNota.values.map(
                        (c) => _CategoriaChip(
                          label: c.label,
                          icon: c.icon,
                          selezionata: filtro == c,
                          onTap: () =>
                              ref.read(filtroCategoriaProvider.notifier).state =
                                  c,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Contatore note — stesso stile del contatore libri in Biblioteca
            SliverToBoxAdapter(
              child: noteAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (note) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${note.length} note',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Griglia note
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: noteAsync.when(
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
                          onPressed: () => ref.invalidate(noteProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Riprova'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (note) {
                  if (note.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(
                        onAdd: () => _showAddDialog(context, ref),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final nota = note[index];
                      return NotaCard(
                        nota: nota,
                        onTap: () => _showEditDialog(context, ref, nota),
                        onDelete: () => _confirmDelete(context, ref, nota),
                        onTogglePin: () =>
                            ref.read(noteProvider.notifier).togglePin(nota.id),
                      );
                    }, childCount: note.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _NotaDialog(ref: ref),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Nota nota) {
    showDialog(
      context: context,
      builder: (context) => _NotaDialog(ref: ref, nota: nota),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Nota nota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminare questa nota?'),
        content: const Text('L\'operazione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(noteProvider.notifier).deleteNota(nota.id);
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

// Stato vuoto — stesso linguaggio visivo di _EmptyState in Biblioteca
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

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
              Icons.note_add_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessuna nota',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi la tua prima nota per iniziare',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi nota'),
          ),
        ],
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selezionata;
  final VoidCallback onTap;

  const _CategoriaChip({
    required this.label,
    this.icon,
    required this.selezionata,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 16) : null,
        selected: selezionata,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}

// Dialog per aggiungere/modificare una nota — invariato, già coerente
class _NotaDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Nota? nota;

  const _NotaDialog({required this.ref, this.nota});

  @override
  ConsumerState<_NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends ConsumerState<_NotaDialog> {
  late final TextEditingController _testoController;
  late CategoriaNota _categoria;
  late int _colore;

  bool get isEditing => widget.nota != null;

  @override
  void initState() {
    super.initState();
    _testoController = TextEditingController(text: widget.nota?.testo ?? '');
    _categoria = widget.nota?.categoria ?? CategoriaNota.generale;
    _colore = widget.nota?.colore ?? ColoreNota.palette[0].value;
  }

  @override
  void dispose() {
    _testoController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    isEditing ? 'Modifica nota' : 'Nuova nota',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _testoController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Scrivi qui...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Categoria',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoriaNota.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 16),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                'Colore',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ColoreNota.palette.map((c) {
                  final selezionato = c.value == _colore;
                  return InkWell(
                    onTap: () => setState(() => _colore = c.value),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selezionato
                              ? Colors.black87
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selezionato
                          ? const Icon(Icons.check, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

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
    );
  }

  void _save() {
    if (_testoController.text.trim().isEmpty) return;

    final nota = Nota(
      id: widget.nota?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      testo: _testoController.text.trim(),
      categoria: _categoria,
      colore: _colore,
      dataCreazione: widget.nota?.dataCreazione ?? DateTime.now(),
      fissata: widget.nota?.fissata ?? false,
    );

    if (isEditing) {
      widget.ref.read(noteProvider.notifier).updateNota(nota);
    } else {
      widget.ref.read(noteProvider.notifier).addNota(nota);
    }

    Navigator.pop(context);
  }
}
