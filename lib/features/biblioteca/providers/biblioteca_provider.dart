import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/libro.dart';
import '../repository/biblioteca_repository.dart';

// Provider per il repository
final bibliotecaRepositoryProvider = Provider<BibliotecaRepository>((ref) {
  return BibliotecaRepository();
});

// Provider per l'ordinamento
final ordinamentoProvider = StateProvider<String>((ref) {
  return 'title'; // 'title', 'author', 'read_date'
});

// Notifier per gestire i libri
class BibliotecaNotifier extends AsyncNotifier<List<Libro>> {
  @override
  Future<List<Libro>> build() async {
    final repository = ref.watch(bibliotecaRepositoryProvider);
    final ordinamento = ref.watch(ordinamentoProvider);

    final libri = await repository.getLibri();
    return _ordina(libri, ordinamento);
  }

  List<Libro> _ordina(List<Libro> libri, String ordinamento) {
    final sorted = List<Libro>.from(libri);
    switch (ordinamento) {
      case 'title':
        sorted.sort((a, b) => a.titolo.compareTo(b.titolo));
        break;
      case 'author':
        sorted.sort((a, b) => a.autore.compareTo(b.autore));
        break;
      case 'read_date':
        sorted.sort((a, b) => b.dataLettura.compareTo(a.dataLettura));
        break;
    }
    return sorted;
  }

  Future<void> addLibro(Libro libro) async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    await repository.addLibro(libro);
    await _reload();
  }

  Future<void> updateLibro(Libro libro) async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    await repository.updateLibro(libro);
    await _reload();
  }

  Future<void> deleteLibro(String id) async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    await repository.deleteLibro(id);
    await _reload();
  }

  Future<int> importJson(String jsonString, {bool merge = true}) async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    final count = await repository.importFromJson(jsonString, merge: merge);
    await _reload();
    return count;
  }

  Future<void> _reload() async {
    final repository = ref.read(bibliotecaRepositoryProvider);
    final ordinamento = ref.read(ordinamentoProvider);
    final libri = await repository.getLibri();
    state = AsyncValue.data(_ordina(libri, ordinamento));
  }
}

// Provider principale
final bibliotecaProvider =
    AsyncNotifierProvider<BibliotecaNotifier, List<Libro>>(() {
      return BibliotecaNotifier();
    });

// Provider per l'export JSON
final bibliotecaExportProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(bibliotecaRepositoryProvider);
  return repository.exportToJson();
});
