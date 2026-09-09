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
      appBar: AppBar(
        title: const Text('Lista dei Desideri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
            tooltip: 'Cerca libri',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(wishlistProvider.future);
        },
        child: wishlistAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Errore: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(wishlistProvider),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (libri) {
            if (libri.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 80,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('Nessun libro nella wishlist'),
                          const SizedBox(height: 8),
                          Text(
                            'Cerca e aggiungi libri che vuoi leggere\nScorri verso il basso per aggiornare',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: libri.length,
              itemBuilder: (context, index) {
                final libro = libri[index];
                return _WishlistCard(
                  libro: libro,
                  onMoveToRead: () => _showMoveToReadDialog(context, ref, libro),
                  onRemove: () => _confirmRemove(context, ref, libro),
                );
              },
            );
          },
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
                await ref.read(bibliotecaProvider.notifier)
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
        title: const Text('Rimuovere dalla wishlist?'),
        content: Text('"${libro.titolo}" verrà rimosso dalla lista dei desideri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bibliotecaProvider.notifier)
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: libro.copertinaUrl != null
            ? Image.network(
                libro.copertinaUrl!,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 70,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.menu_book),
                  );
                },
              )
            : Container(
                width: 50,
                height: 70,
                color: theme.colorScheme.surfaceVariant,
                child: const Icon(Icons.menu_book),
              ),
        title: Text(
          libro.titolo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(libro.autore),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    return ListTile(
                      leading: libro.copertinaUrl != null
                          ? Image.network(
                              libro.copertinaUrl!,
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.menu_book);
                              },
                            )
                          : const Icon(Icons.menu_book),
                      title: Text(libro.titolo),
                      subtitle: Text(libro.autore),
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_add_outlined),
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