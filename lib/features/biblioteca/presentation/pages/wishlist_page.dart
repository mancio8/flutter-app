// File: lib/features/biblioteca/presentation/pages/wishlist_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/libro.dart';
import '../../providers/biblioteca_provider.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(wishlistProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar personalizzato come in BibliotecaPage
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
                    const Icon(Icons.bookmark, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Lista dei Desideri',
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
                      Icons.bookmark_add_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context, ref),
                  tooltip: 'Cerca libri',
                ),
              ],
            ),

            // Contatore libri
            SliverToBoxAdapter(
              child: wishlistAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (libri) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    '${libri.length} libri nella wishlist',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Lista libri
            wishlistAsync.when(
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
                          ref.invalidate(wishlistProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (libri) {
                if (libri.isEmpty) {
                  return SliverFillRemaining(
                    child: _WishlistEmptyState(
                      onSearch: () => _showSearchDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final libro = libri[index];
                        return _WishlistCard(
                          libro: libro,
                          onMoveToRead: () =>
                              _showMoveToReadDialog(context, ref, libro),
                          onRemove: () => _confirmRemove(context, ref, libro),
                        );
                      },
                      childCount: libri.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SearchBooksDialog(ref: ref),
    );
  }

  void _showMoveToReadDialog(BuildContext context, WidgetRef ref, Libro libro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Segna come letto'),
        content: Text('Quando hai letto "${libro.titolo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null && context.mounted) {
                await ref
                    .read(bibliotecaProvider.notifier)
                    .moveToRead(libro, date);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, Libro libro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rimuovere dalla wishlist?'),
        content: Text(
          '"${libro.titolo}" verrà rimosso dalla lista dei desideri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(bibliotecaProvider.notifier)
                  .removeFromWishlist(libro.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
  }
}

// Stato vuoto coerente con _EmptyState della biblioteca
class _WishlistEmptyState extends StatelessWidget {
  final VoidCallback onSearch;

  const _WishlistEmptyState({required this.onSearch});

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
              Icons.bookmark_border,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun libro nella wishlist',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cerca e aggiungi libri che vuoi leggere\nScorri verso il basso per aggiornare',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text('Cerca libri'),
          ),
        ],
      ),
    );
  }
}

// Card wishlist con stile coerente (margini, ombre, bordi arrotondati)
class _WishlistCard extends StatelessWidget {
  final Libro libro;
  final VoidCallback onMoveToRead;
  final VoidCallback onRemove;

  const _WishlistCard({
    required this.libro,
    required this.onMoveToRead,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Copertina con angoli arrotondati
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: libro.copertinaUrl != null
                  ? Image.network(
                      libro.copertinaUrl!,
                      width: 60,
                      height: 85,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 85,
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.menu_book),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 85,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.menu_book),
                    ),
            ),
            const SizedBox(width: 12),

            // Titolo + autore
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    libro.titolo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    libro.autore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge "In wishlist"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Da leggere',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Azioni
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: onMoveToRead,
                  tooltip: 'Segna come letto',
                  color: Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                  tooltip: 'Rimuovi',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog ricerca con stile coerente (bordi arrotondati 20)
class _SearchBooksDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _SearchBooksDialog({required this.ref});

  @override
  ConsumerState<_SearchBooksDialog> createState() => _SearchBooksDialogState();
}

class _SearchBooksDialogState extends ConsumerState<_SearchBooksDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Libro> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.ref
          .read(bibliotecaProvider.notifier)
          .searchOnline(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella ricerca: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icona come _AddBookDialog
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cerca libri',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cerca per titolo o autore...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_results.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Cerca libri da aggiungere alla wishlist'
                        : 'Nessun risultato trovato',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final libro = _results[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: libro.copertinaUrl != null
                              ? Image.network(
                                  libro.copertinaUrl!,
                                  width: 40,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 60,
                                      color: theme.colorScheme.surfaceVariant,
                                      child: const Icon(Icons.menu_book),
                                    );
                                  },
                                )
                              : Container(
                                  width: 40,
                                  height: 60,
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Icon(Icons.menu_book),
                                ),
                        ),
                        title: Text(
                          libro.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(libro.autore),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_add_outlined),
                          color: theme.colorScheme.primary,
                          onPressed: () async {
                            await widget.ref
                                .read(bibliotecaProvider.notifier)
                                .addToWishlist(libro);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${libro.titolo} aggiunto alla wishlist',
                                  ),
                                ),
                              );
                            }
                          },
                          tooltip: 'Aggiungi alla wishlist',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}