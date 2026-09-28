// File: lib/features/biblioteca/presentation/pages/biblioteca_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/libro.dart';
import '../../providers/biblioteca_provider.dart';
import '../widgets/book_card.dart';

class BibliotecaPage extends ConsumerStatefulWidget {
  const BibliotecaPage({super.key});

  @override
  ConsumerState<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends ConsumerState<BibliotecaPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libriAsync = ref.watch(bibliotecaProvider);
    final ordinamento = ref.watch(ordinamentoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(bibliotecaProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
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
                  icon: const Icon(Icons.bookmark_outline),
                  onPressed: () => context.push('/wishlist'),
                  tooltip: 'Wishlist',
                ),
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

            // Card: ricerca + ordinamento
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
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
                child: Column(
                  children: [
                    // Ricerca
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Cerca per titolo o autore...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ordinamento
                    Row(
                      children: [
                        Icon(
                          Icons.sort,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
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
                              DropdownMenuItem(
                                value: 'title',
                                child: Text('Titolo'),
                              ),
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
                                ref
                                    .read(ordinamentoProvider.notifier)
                                    .state = value;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Contatore
            SliverToBoxAdapter(
              child: libriAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (libri) {
                  var filtrati = libri;
                  if (_query.trim().isNotEmpty) {
                    final q = _query.toLowerCase().trim();
                    filtrati = libri.where((l) {
                      return l.titolo.toLowerCase().contains(q) ||
                          l.autore.toLowerCase().contains(q);
                    }).toList();
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _query.trim().isEmpty
                          ? '${libri.length} libri nella collezione'
                          : '${filtrati.length} di ${libri.length} libri',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Griglia
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
                            ref.invalidate(bibliotecaProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Riprova'),
                        ),
                      ],
                    ),
                  ),
                ),

                data: (libri) {
                  // 1) Filtro
                  var filtrati = libri;
                  if (_query.trim().isNotEmpty) {
                    final q = _query.toLowerCase().trim();
                    filtrati = libri.where((l) {
                      return l.titolo.toLowerCase().contains(q) ||
                          l.autore.toLowerCase().contains(q);
                    }).toList();
                  }

                  // 2) Ordinamento
                  final libriOrdinati = List<Libro>.from(filtrati);
                  switch (ordinamento) {
                    case 'title':
                      libriOrdinati.sort(
                        (a, b) => a.titolo
                            .toLowerCase()
                            .compareTo(b.titolo.toLowerCase()),
                      );
                      break;
                    case 'author':
                      libriOrdinati.sort(
                        (a, b) => a.autore
                            .toLowerCase()
                            .compareTo(b.autore.toLowerCase()),
                      );
                      break;
                    case 'read_date':
                      libriOrdinati.sort((a, b) {
                        final da = a.dataLettura ?? DateTime(0);
                        final db = b.dataLettura ?? DateTime(0);
                        return db.compareTo(da);
                      });
                      break;
                  }

                  // 3) Stato vuoto
                  if (libriOrdinati.isEmpty) {
                    if (_query.trim().isNotEmpty) {
                      return SliverFillRemaining(
                        child: _NoResultsState(query: _query),
                      );
                    }
                    return SliverFillRemaining(
                      child: _EmptyState(
                        onAdd: () => _showAddDialog(context, ref),
                      ),
                    );
                  }

                  // 4) Griglia
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final libro = libriOrdinati[index];
                      return BookCard(
                        libro: libro,
                        onEdit: () => _showEditDialog(context, ref, libro),
                        onDelete: () => _confirmDelete(context, ref, libro),
                        onIncrementVolume:
                            libro.isSerie && !libro.isSerieCompleta
                                ? () => _incrementVolume(context, ref, libro)
                                : null,
                      );
                    }, childCount: libriOrdinati.length),
                  );
                },
              ),
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _incrementVolume(BuildContext context, WidgetRef ref, Libro libro) {
    final nuovo = libro.copyWith(
      volumiLetti: libro.volumiLetti + 1,
      dataUltimaLettura: DateTime.now(),
    );
    ref.read(bibliotecaProvider.notifier).updateLibro(nuovo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Letto volume ${nuovo.volumiLetti}'
          '${libro.volumiTotali != null ? "/${libro.volumiTotali}" : ""}'
          ' di "${libro.titolo}"',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esportazione in corso...')),
      );

      final jsonString = await ref.read(bibliotecaExportProvider.future);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/biblioteca_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)]);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esportazione completata!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'esportazione: $e')),
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

    if (merge == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Importazione in corso...'),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final count = await ref
          .read(bibliotecaProvider.notifier)
          .importJson(jsonString, merge: merge);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ref.invalidate(bibliotecaProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merge
                ? '$count nuovi libri importati'
                : '$count libri importati (libreria sostituita)',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'importazione: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
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

// ============================================================
// STATO VUOTO
// ============================================================

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
            'Aggiungi il tuo primo libro per iniziare\nScorri verso il basso per aggiornare',
            textAlign: TextAlign.center,
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

// ============================================================
// STATO NESSUN RISULTATO
// ============================================================

class _NoResultsState extends StatelessWidget {
  final String query;

  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 80,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun risultato',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nessun libro trovato per "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG AGGIUNTA / MODIFICA
// ============================================================

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
  late final TextEditingController _volumiTotaliController;
  late final TextEditingController _volumiLettiController;

  DateTime _dataLettura = DateTime.now();
  String _tipo = 'libro';

  bool get isEditing => widget.libro != null;

  @override
  void initState() {
    super.initState();
    _titoloController =
        TextEditingController(text: widget.libro?.titolo ?? '');
    _autoreController =
        TextEditingController(text: widget.libro?.autore ?? '');
    _copertinaController = TextEditingController(
      text: widget.libro?.copertinaUrl ?? '',
    );
    _volumiTotaliController = TextEditingController(
      text: widget.libro?.volumiTotali?.toString() ?? '',
    );
    _volumiLettiController = TextEditingController(
      text: (widget.libro?.volumiLetti ?? 0) > 0
          ? widget.libro!.volumiLetti.toString()
          : '',
    );

    if (widget.libro != null) {
      _dataLettura = widget.libro!.dataLettura ?? DateTime.now();
      _tipo = widget.libro!.tipo;
    }
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _autoreController.dispose();
    _copertinaController.dispose();
    _volumiTotaliController.dispose();
    _volumiLettiController.dispose();
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
                // Header
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

                // Titolo
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

                // Autore
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

                // Data
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dataLettura,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                    );
                    if (date != null && mounted) {
                      setState(() => _dataLettura = date);
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
                const SizedBox(height: 16),

                // Tipo
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'libro', child: Text('Libro')),
                    DropdownMenuItem(value: 'manga', child: Text('Manga')),
                    DropdownMenuItem(value: 'fumetto', child: Text('Fumetto')),
                    DropdownMenuItem(value: 'serie', child: Text('Serie')),
                    DropdownMenuItem(value: 'rivista', child: Text('Rivista')),
                  ],
                  onChanged: (v) => setState(() => _tipo = v ?? 'libro'),
                ),
                const SizedBox(height: 16),

                // Volumi (solo per manga / fumetto / serie)
                if (_tipo == 'manga' ||
                    _tipo == 'fumetto' ||
                    _tipo == 'serie') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _volumiTotaliController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Volumi totali',
                            suffixText: 'vol.',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _volumiLettiController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Volumi letti',
                            suffixText: 'vol.',
                            prefixIcon:
                                const Icon(Icons.check_circle_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final letti = int.tryParse(v);
                            final totali =
                                int.tryParse(_volumiTotaliController.text);
                            if (letti == null) return 'Numero non valido';
                            if (totali != null && letti > totali) {
                              return 'Troppi';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Bottoni
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
        id: widget.libro?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        titolo: _titoloController.text,
        autore: _autoreController.text,
        dataLettura: _dataLettura,
        copertinaUrl: _copertinaController.text.isEmpty
            ? null
            : _copertinaController.text,
        tipo: _tipo,
        volumiTotali: int.tryParse(_volumiTotaliController.text),
        volumiLetti: int.tryParse(_volumiLettiController.text) ?? 0,
        dataUltimaLettura: _dataLettura,
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