import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/rifornimento.dart';
import '../../../core/models/veicolo.dart';
import '../repository/rifornimenti_repository.dart';
import '../../veicoli/repository/veicoli_repository.dart';
import '../../../core/providers/supabase_provider.dart';

final rifornimentiRepositoryProvider = Provider<RifornimentiRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return RifornimentiRepository(supabase);
});

// Provider per il repository dei veicoli
final veicoliRepositoryProvider = Provider<VeicoliRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VeicoliRepository(supabase);
});

// Provider per la lista dei veicoli
final veicoliProvider = FutureProvider<List<Veicolo>>((ref) async {
  final repository = ref.watch(veicoliRepositoryProvider);
  return repository.getVeicoli();
});

// Provider per il veicolo selezionato
final veicoloSelezionatoProvider = StateProvider<String?>((ref) {
  return null; // null = tutti i veicoli
});

// NUOVO: Notifier per gestire i rifornimenti
class RifornimentiNotifier extends AsyncNotifier<List<Rifornimento>> {
  @override
  Future<List<Rifornimento>> build() async {
    final repository = ref.watch(rifornimentiRepositoryProvider);
    final veicoloSelezionato = ref.watch(veicoloSelezionatoProvider);

    // Se è selezionato un veicolo specifico
    if (veicoloSelezionato != null) {
      return repository.getRifornimentiPerVeicolo(veicoloSelezionato);
    }

    // Altrimenti tutti i rifornimenti
    return repository.getRifornimenti();
  }

  // Aggiunge un rifornimento
  Future<void> addRifornimento(Rifornimento rifornimento) async {
    final repository = ref.read(rifornimentiRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.addRifornimento(rifornimento);
      // Ricarica i dati
      final veicoloSelezionato = ref.read(veicoloSelezionatoProvider);
      if (veicoloSelezionato != null) {
        final rifornimenti = await repository.getRifornimentiPerVeicolo(
          veicoloSelezionato,
        );
        state = AsyncValue.data(rifornimenti);
      } else {
        final rifornimenti = await repository.getRifornimenti();
        state = AsyncValue.data(rifornimenti);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // NUOVO: Metodo per aggiornare un rifornimento
  Future<void> updateRifornimento(Rifornimento rifornimento) async {
    final repository = ref.read(rifornimentiRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.updateRifornimento(rifornimento);
      await _reload();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Elimina un rifornimento
  Future<void> deleteRifornimento(String id) async {
    final repository = ref.read(rifornimentiRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.deleteRifornimento(id);
      // Ricarica i dati
      final veicoloSelezionato = ref.read(veicoloSelezionatoProvider);
      if (veicoloSelezionato != null) {
        final rifornimenti = await repository.getRifornimentiPerVeicolo(
          veicoloSelezionato,
        );
        state = AsyncValue.data(rifornimenti);
      } else {
        final rifornimenti = await repository.getRifornimenti();
        state = AsyncValue.data(rifornimenti);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // NUOVO: Metodo per importare rifornimenti da JSON
  Future<int> importRifornimenti(String jsonString, {bool merge = true}) async {
    final repository = ref.read(rifornimentiRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      final count = await repository.importFromJson(jsonString, merge: merge);
      await _reload();
      return count;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Metodo helper per ricaricare
  Future<void> _reload() async {
    final repository = ref.read(rifornimentiRepositoryProvider);
    final veicoloSelezionato = ref.read(veicoloSelezionatoProvider);

    final rifornimenti = veicoloSelezionato != null
        ? await repository.getRifornimentiPerVeicolo(veicoloSelezionato)
        : await repository.getRifornimenti();

    state = AsyncValue.data(rifornimenti);
  }
}

// CAMBIA: Da FutureProvider a AsyncNotifierProvider
final rifornimentiProvider =
    AsyncNotifierProvider<RifornimentiNotifier, List<Rifornimento>>(() {
      return RifornimentiNotifier();
    });

// Provider per le statistiche
final rifornimentiStatsProvider = Provider<RifornimentiStats>((ref) {
  final rifornimentiAsync = ref.watch(rifornimentiProvider);

  return rifornimentiAsync.when(
    data: (rifornimenti) {
      final totaleSpeso = rifornimenti.fold<double>(
        0,
        (sum, r) => sum + r.costo,
      );
      final totaleLitri = rifornimenti.fold<double>(
        0,
        (sum, r) => sum + r.litri,
      );
      final prezzoMedio = totaleLitri > 0 ? (totaleSpeso / totaleLitri) : 0.0;
      final consumoMedio = _calcolaConsumoMedio(rifornimenti);

      return RifornimentiStats(
        totaleSpeso: totaleSpeso,
        totaleLitri: totaleLitri,
        prezzoMedio: prezzoMedio,
        consumoMedio: consumoMedio,
      );
    },
    loading: () => const RifornimentiStats(
      totaleSpeso: 0,
      totaleLitri: 0,
      prezzoMedio: 0,
      consumoMedio: 0,
    ),
    error: (_, __) => const RifornimentiStats(
      totaleSpeso: 0,
      totaleLitri: 0,
      prezzoMedio: 0,
      consumoMedio: 0,
    ),
  );
});

// Calcola il consumo medio (km/L) confrontando rifornimenti consecutivi
// dello STESSO veicolo, basandosi sul chilometraggio registrato.
double _calcolaConsumoMedio(List<Rifornimento> rifornimenti) {
  // Raggruppa per veicolo: il confronto tra chilometraggi ha senso
  // solo all'interno dello stesso veicolo
  final Map<String?, List<Rifornimento>> perVeicolo = {};
  for (final r in rifornimenti) {
    if (r.chilometraggio == null) continue; // serve il km per calcolare
    perVeicolo.putIfAbsent(r.veicoloId, () => []).add(r);
  }

  final List<double> consumiSingoli = [];

  for (final lista in perVeicolo.values) {
    if (lista.length < 2) continue; // servono almeno 2 rifornimenti con km

    final ordinata = List<Rifornimento>.from(lista)
      ..sort((a, b) => a.chilometraggio!.compareTo(b.chilometraggio!));

    for (var i = 1; i < ordinata.length; i++) {
      final kmPercorsi =
          ordinata[i].chilometraggio! - ordinata[i - 1].chilometraggio!;
      final litriUsati = ordinata[i].litri;

      if (kmPercorsi > 0 && litriUsati > 0) {
        consumiSingoli.add(kmPercorsi / litriUsati);
      }
    }
  }

  if (consumiSingoli.isEmpty) return 0.0;
  return consumiSingoli.reduce((a, b) => a + b) / consumiSingoli.length;
}

class RifornimentiStats {
  final double totaleSpeso;
  final double totaleLitri;
  final double prezzoMedio;
  final double consumoMedio; // km/L

  const RifornimentiStats({
    required this.totaleSpeso,
    required this.totaleLitri,
    required this.prezzoMedio,
    required this.consumoMedio,
  });
}
