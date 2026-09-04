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
      appBar: AppBar(title: const Text('Note')),
      body: Column(
        children: [
          // Filtro categorie
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _CategoriaChip(
                  label: 'Tutte',
                  selezionata: filtro == null,
                  onTap: () => ref.read(filtroCategoriaProvider.notifier).state = null,
                ),
                ...CategoriaNota.values.map((c) => _CategoriaChip(
                      label: c.label,
                      icon: c.icon,
                      selezionata: filtro == c,
                      onTap: () => ref.read(filtroCategoriaProvider.notifier).state = c,
                    )),
              ],
            ),
          ),
          Expanded(
            child: noteAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (note) {
                if (note.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add_outlined, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('Nessuna nota'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: note.length,
                  itemBuilder: (context, index) {
                    final nota = note[index];
                    return NotaCard(
                      nota: nota,
                      onTap: () => _showEditDialog(context, ref, nota),
                      onDelete: () => _confirmDelete(context, ref, nota),
                      onTogglePin: () =>
                          ref.read(noteProvider.notifier).togglePin(nota.id),
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _NotaDialog(ref: ref));
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Nota nota) {
    showDialog(context: context, builder: (context) => _NotaDialog(ref: ref, nota: nota));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Nota nota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Elimina'),
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

// Dialog per aggiungere/modificare una nota
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifica nota' : 'Nuova nota',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Testo nota
              TextFormField(
                controller: _testoController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Scrivi qui...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Categoria
              const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w600)),
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

              // Colore
              const Text('Colore', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          color: selezionato ? Colors.black87 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selezionato ? const Icon(Icons.check, size: 18) : null,
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
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
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