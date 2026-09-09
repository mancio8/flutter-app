// File: lib/features/biblioteca/providers/biblioteca_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/libro.dart';
import '../repository/biblioteca_repository.dart';
import '../../../core/providers/supabase_provider.dart';

final bibliotecaRepositoryProvider = Provider<BibliotecaRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BibliotecaRepository(supabase);
});

final ordinamentoProvider = StateProvider<String>((ref) {
  return 'title';
});

final libriLettiProvider = FutureProvider<List<Libro>>((ref) async {
  final repository = ref.watch(bibliotecaRepositoryProvider);
  return repository.getLibriLetti();
});

final wishlistProvider = FutureProvider<List<Libro>>((ref) async {
  final repository = ref.watch(bibliotecaRepositoryProvider);
  return repository.getWishlist();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Libro>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final repository = ref.watch(bibliotecaRepositoryProvider);
  return repository.searchBooksOnline(query);
});

class BibliotecaNotifier extends AsyncNotifier<List<Libro>> {
  @override
  Future<List<Libro>> build() async {
    final repository = ref.watch(bibliotecaRepositoryProvider);
    try {
      return await repository.getLibriLetti();
    } catch (e) {
      print('Errore nel build: $e');
      rethrow;
    }
  }

  Future<void> addLibro(Libro libro) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.addLibro(libro);
      await _reload();
    } catch (e, stackTrace) {
      print('Errore aggiunta libro: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> updateLibro(Libro libro) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.updateLibro(libro);
      await _reload();
    } catch (e, stackTrace) {
      print('Errore aggiornamento libro: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteLibro(String id) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.deleteLibro(id);
      await _reload();
    } catch (e, stackTrace) {
      print('Errore eliminazione libro: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> addToWishlist(Libro libro) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.addToWishlist(libro);
      ref.invalidate(wishlistProvider);
    } catch (e) {
      print('Errore aggiunta wishlist: $e');
      rethrow;
    }
  }

  Future<void> moveToRead(Libro libro, DateTime dataLettura) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.moveToRead(libro, dataLettura);
      await _reload();
      ref.invalidate(wishlistProvider);
    } catch (e) {
      print('Errore spostamento: $e');
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String id) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      await repository.removeFromWishlist(id);
      ref.invalidate(wishlistProvider);
    } catch (e) {
      print('Errore rimozione wishlist: $e');
      rethrow;
    }
  }

  Future<List<Libro>> searchOnline(String query) async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    return repository.searchBooksOnline(query);
  }

  Future<int> importJson(String jsonString, {bool merge = true}) async {
    final repository = ref.read(bibliotecaRepositoryProvider);

    try {
      final count = await repository.importFromJson(jsonString, merge: merge);
      await _reload();
      return count;
    } catch (e, stackTrace) {
      print('Errore importazione: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> _reload() async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    try {
      final libri = await repository.getLibriLetti();
      state = AsyncValue.data(libri);
    } catch (e, stackTrace) {
      print('Errore reload: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}

final bibliotecaProvider =
    AsyncNotifierProvider<BibliotecaNotifier, List<Libro>>(() {
      return BibliotecaNotifier();
    });

final bibliotecaExportProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(bibliotecaRepositoryProvider);
  return repository.exportToJson();
});