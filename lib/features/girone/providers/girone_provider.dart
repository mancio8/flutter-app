import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/squadra_calcio.dart';
import '../../../core/models/partita_calcio.dart';
import '../repository/girone_repository.dart';
import '../../../core/models/campionato_config.dart';
import '../../../core/providers/supabase_provider.dart';
import '../repository/campionato_config_repository.dart';

// ============================================================
// REPOSITORY
// ============================================================

final gironeRepositoryProvider = Provider<GironeRepository>((ref) {
  return GironeRepository();
});

final campionatoConfigRepositoryProvider =
    Provider<CampionatoConfigRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return CampionatoConfigRepository(supabase);
});

// ============================================================
// CONFIG (URL + squadra preferita)
// ============================================================

final campionatoConfigProvider =
    FutureProvider<CampionatoConfig>((ref) async {
  final repo = ref.watch(campionatoConfigRepositoryProvider);
  final config = await repo.getConfig();

  // Se non esiste, ritorna la config di default
  return config ??
      CampionatoConfig(
        id: '',
        jsonUrl: CampionatoConfig.defaultJsonUrl,
      );
});

// ============================================================
// DATI GREZZI DAL JSON
// ============================================================

final campionatoDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final config = await ref.watch(campionatoConfigProvider.future);
  final repo = ref.watch(gironeRepositoryProvider);
  return repo.fetchJson(config.jsonUrl);
});

// ============================================================
// CLASSIFICA + CALENDARIO
// ============================================================

final calendarioProvider = FutureProvider<List<PartitaCalcio>>((ref) async {
  final data = await ref.watch(campionatoDataProvider.future);
  final repo = ref.watch(gironeRepositoryProvider);
  return repo.parseCalendario(data);
});

final classificaProvider = FutureProvider<List<SquadraCalcio>>((ref) async {
  final data = await ref.watch(campionatoDataProvider.future);
  final repo = ref.watch(gironeRepositoryProvider);
  final classifica = repo.parseClassifica(data);
  final calendario = repo.parseCalendario(data);

  return classifica.map((squadra) {
    final partiteSquadra = calendario
        .where((p) =>
            p.giocata &&
            (p.squadraCasa == squadra.nome ||
                p.squadraTrasferta == squadra.nome))
        .toList()
      ..sort((a, b) {
        final da = a.data ?? DateTime(0);
        final db = b.data ?? DateTime(0);
        return db.compareTo(da);
      });

    final forma = partiteSquadra.take(5).map((p) {
      final isCasa = p.squadraCasa == squadra.nome;
      final golFatti = isCasa ? (p.golCasa ?? 0) : (p.golTrasferta ?? 0);
      final golSubiti = isCasa ? (p.golTrasferta ?? 0) : (p.golCasa ?? 0);
      if (golFatti > golSubiti) return 'W';
      if (golFatti < golSubiti) return 'L';
      return 'D';
    }).toList().reversed.toList();

    return squadra.copyWith(forma: forma);
  }).toList();
});

// ============================================================
// PROSSIMA PARTITA
// ============================================================

final prossimaPartitaProvider =
    Provider<AsyncValue<PartitaCalcio?>>((ref) {
  final calendarioAsync = ref.watch(calendarioProvider);

  return calendarioAsync.whenData((partite) {
    final prossime = partite
        .where((p) => !p.giocata && p.data != null)
        .toList()
      ..sort((a, b) => a.data!.compareTo(b.data!));

    return prossime.isNotEmpty ? prossime.first : null;
  });
});

// ============================================================
// SQUADRA PREFERITA + SUA POSIZIONE
// ============================================================

final squadraPreferitaProvider =
    Provider<AsyncValue<SquadraCalcio?>>((ref) {
  final configAsync = ref.watch(campionatoConfigProvider);
  final classificaAsync = ref.watch(classificaProvider);

  return configAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (config) {
      if (config.squadraPreferita == null) {
        return const AsyncValue.data(null);
      }

      return classificaAsync.whenData((classifica) {
        try {
          return classifica.firstWhere(
            (s) => s.nome.toLowerCase() ==
                config.squadraPreferita!.toLowerCase(),
          );
        } catch (_) {
          return null;
        }
      });
    },
  );
});

// ============================================================
// FILTRI (invariati)
// ============================================================

final faseSelezionataProvider =
    StateProvider<FasePartita>((ref) => FasePartita.andata);

final giornataSelezionataProvider =
    StateProvider<int?>((ref) => null);

final giornataCorrenteProvider = Provider<int?>((ref) {
  final calendarioAsync = ref.watch(calendarioProvider);
  final fase = ref.watch(faseSelezionataProvider);
  final calendario = calendarioAsync.value ?? [];

  final partiteFase = calendario.where((p) => p.fase == fase).toList();
  if (partiteFase.isEmpty) return null;

  // 1. Prossime con data
  final prossimeConData = partiteFase
      .where((p) => !p.giocata && p.data != null)
      .toList()
    ..sort((a, b) => a.data!.compareTo(b.data!));

  if (prossimeConData.isNotEmpty) return prossimeConData.first.giornata;

  // 2. Fallback: prima non giocata
  final nonGiocate = partiteFase
      .where((p) => !p.giocata)
      .map((p) => p.giornata)
      .where((g) => g > 0)
      .toSet()
      .toList()
    ..sort();

  if (nonGiocate.isNotEmpty) return nonGiocate.first;

  // 3. Fallback finale: ultima giornata
  final tutte = partiteFase
      .map((p) => p.giornata)
      .where((g) => g > 0)
      .toSet()
      .toList()
    ..sort();

  return tutte.isNotEmpty ? tutte.last : null;
});

final giornataEffettivaProvider = Provider<int?>((ref) {
  final selezionata = ref.watch(giornataSelezionataProvider);
  if (selezionata != null) return selezionata;
  return ref.watch(giornataCorrenteProvider);
});

final calendarioFiltratoProvider =
    Provider<AsyncValue<List<PartitaCalcio>>>((ref) {
  final calendarioAsync = ref.watch(calendarioProvider);
  final fase = ref.watch(faseSelezionataProvider);
  final giornata = ref.watch(giornataEffettivaProvider);

  return calendarioAsync.whenData((partite) {
    var filtrate = partite.where((p) => p.fase == fase).toList();
    if (giornata != null) {
      filtrate = filtrate.where((p) => p.giornata == giornata).toList();
    }
    return filtrate;
  });
});

final giornateDisponibiliProvider = Provider<List<int>>((ref) {
  final calendarioAsync = ref.watch(calendarioProvider);
  final fase = ref.watch(faseSelezionataProvider);
  final calendario = calendarioAsync.value ?? [];

  return (calendario
          .where((p) => p.fase == fase)
          .map((p) => p.giornata)
          .where((g) => g > 0)
          .toSet()
          .toList()
        ..sort());
});