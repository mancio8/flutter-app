import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/libro.dart';
import '../../providers/biblioteca_provider.dart';
import '../widgets/book_card.dart';
import 'package:file_picker/file_picker.dart';

class BibliotecaPage extends ConsumerWidget {
  const BibliotecaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libriAsync = ref.watch(bibliotecaProvider);
    final ordinamento = ref.watch(ordinamentoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personalizzato
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
                  const Icon(Icons.menu_book, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'La tua biblioteca',
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
                    Icons.auto_stories,
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

          // Barra ordinamento
          SliverToBoxAdapter(
            child: Container(
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
                  Icon(Icons.sort, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Ordina per:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: ordinamento,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: theme.colorScheme.surface,
                      items: const [
                        DropdownMenuItem(value: 'title', child: Text('Titolo')),
                        DropdownMenuItem(
                          value: 'author',
                          child: Text('Autore'),
                        ),
                        DropdownMenuItem(
                          value: 'read_date',
                          child: Text('Data lettura'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(ordinamentoProvider.notifier).state = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contatore libri
          SliverToBoxAdapter(
            child: libriAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (libri) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${libri.length} libri nella collezione',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),

          // Griglia libri
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: libriAsync.when(
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
                      Text('Errore nel caricamento'),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              data: (libri) {
                if (libri.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      onAdd: () => _showAddDialog(context, ref),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final libro = libri[index];
                    return BookCard(
                      libro: libro,
                      onEdit: () => _showEditDialog(context, ref, libro),
                      onDelete: () => _confirmDelete(context, ref, libro),
                    );
                  }, childCount: libri.length),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final jsonString = await ref.read(bibliotecaExportProvider.future);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/biblioteca_$timestamp.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)]);
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
        title: const Text('Importa libri'),
        content: const Text(
          'Vuoi aggiungere i libri importati a quelli esistenti '
          '(saltando i duplicati) oppure sostituire completamente la libreria?',
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
          .read(bibliotecaProvider.notifier)
          .importJson(jsonString, merge: merge);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merge
                ? '$count nuovi libri importati'
                : '$count libri importati (libreria sostituita)',
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
      builder: (context) => _AddBookDialog(ref: ref),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Libro libro) {
    showDialog(
      context: context,
      builder: (context) => _AddBookDialog(ref: ref, libro: libro),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Libro libro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminare questo libro?'),
        content: Text('"${libro.titolo}" verrà eliminato definitivamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bibliotecaProvider.notifier).deleteLibro(libro.id);
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

// Stato vuoto migliorato
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
              Icons.auto_stories,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun libro trovato',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il tuo primo libro per iniziare',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi libro'),
          ),
        ],
      ),
    );
  }
}

// Dialog migliorato
class _AddBookDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Libro? libro;

  const _AddBookDialog({required this.ref, this.libro});

  @override
  ConsumerState<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends ConsumerState<_AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  late final TextEditingController _autoreController;
  late final TextEditingController _copertinaController;
  DateTime _dataLettura = DateTime.now();

  bool get isEditing => widget.libro != null;

  @override
  void initState() {
    super.initState();
    _titoloController = TextEditingController(text: widget.libro?.titolo ?? '');
    _autoreController = TextEditingController(text: widget.libro?.autore ?? '');
    _copertinaController = TextEditingController(
      text: widget.libro?.copertinaUrl ?? '',
    );
    if (widget.libro != null) {
      _dataLettura = widget.libro!.dataLettura;
    }
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _autoreController.dispose();
    _copertinaController.dispose();
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
                // Titolo del dialog
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
                      isEditing ? 'Modifica Libro' : 'Aggiungi Libro',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Campo titolo
                TextFormField(
                  controller: _titoloController,
                  decoration: InputDecoration(
                    labelText: 'Titolo',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Inserisci il titolo' : null,
                ),

                const SizedBox(height: 16),

                // Campo autore
                TextFormField(
                  controller: _autoreController,
                  decoration: InputDecoration(
                    labelText: 'Autore',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Inserisci l\'autore' : null,
                ),

                const SizedBox(height: 16),

                // Data lettura
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dataLettura,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _dataLettura = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data lettura',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${_dataLettura.day}/${_dataLettura.month}/${_dataLettura.year}',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // URL copertina
                TextFormField(
                  controller: _copertinaController,
                  decoration: InputDecoration(
                    labelText: 'URL copertina (opzionale)',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),

                const SizedBox(height: 24),

                // Pulsanti
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
      final libro = Libro(
        id:
            widget.libro?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        titolo: _titoloController.text,
        autore: _autoreController.text,
        dataLettura: _dataLettura,
        copertinaUrl: _copertinaController.text.isEmpty
            ? null
            : _copertinaController.text,
      );

      if (isEditing) {
        widget.ref.read(bibliotecaProvider.notifier).updateLibro(libro);
      } else {
        widget.ref.read(bibliotecaProvider.notifier).addLibro(libro);
      }

      Navigator.pop(context);
    }
  }
}
