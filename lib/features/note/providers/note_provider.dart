import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/nota.dart';
import '../repository/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// Filtro categoria (null = tutte)
final filtroCategoriaProvider = StateProvider<CategoriaNota?>((ref) => null);

class NoteNotifier extends AsyncNotifier<List<Nota>> {
  @override
  Future<List<Nota>> build() async {
    final repository = ref.watch(noteRepositoryProvider);
    final note = await repository.getNote();
    return _ordina(note);
  }

  // Fissate in cima, poi per data decrescente
  List<Nota> _ordina(List<Nota> note) {
    final sorted = List<Nota>.from(note);
    sorted.sort((a, b) {
      if (a.fissata != b.fissata) {
        return a.fissata ? -1 : 1;
      }
      return b.dataCreazione.compareTo(a.dataCreazione);
    });
    return sorted;
  }

  Future<void> addNota(Nota nota) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.addNota(nota);
    await _reload();
  }

  Future<void> updateNota(Nota nota) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNota(nota);
    await _reload();
  }

  Future<void> deleteNota(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNota(id);
    await _reload();
  }

  Future<void> togglePin(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.togglePin(id);
    await _reload();
  }

  Future<void> _reload() async {
    final repository = ref.read(noteRepositoryProvider);
    final note = await repository.getNote();
    state = AsyncValue.data(_ordina(note));
  }
}

final noteProvider = AsyncNotifierProvider<NoteNotifier, List<Nota>>(() {
  return NoteNotifier();
});

// Note filtrate per categoria
final noteFiltrateProvider = Provider<AsyncValue<List<Nota>>>((ref) {
  final noteAsync = ref.watch(noteProvider);
  final filtro = ref.watch(filtroCategoriaProvider);

  return noteAsync.whenData((note) {
    if (filtro == null) return note;
    return note.where((n) => n.categoria == filtro).toList();
  });
});