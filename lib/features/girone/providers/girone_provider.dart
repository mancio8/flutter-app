import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/squadra_calcio.dart';
import '../../../core/models/partita_calcio.dart';
import '../repository/girone_repository.dart';

// ============================================================
// REPOSITORY
// ============================================================

final gironeRepositoryProvider = Provider<GironeRepository>((ref) {
  return GironeRepository();
});

// ============================================================
// CALENDARIO (raw)
// ============================================================

final calendarioProvider = FutureProvider<List<PartitaCalcio>>((ref) async {
  final repository = ref.watch(gironeRepositoryProvider);
  return repository.getCalendario();
});

// ============================================================
// CLASSIFICA (con forma calcolata dal calendario)
// ============================================================

final classificaProvider = FutureProvider<List<SquadraCalcio>>((ref) async {
  final repository = ref.watch(gironeRepositoryProvider);

  // Carico entrambi in parallelo
  final results = await Future.wait([
    repository.getClassifica(),
    repository.getCalendario(),
  ]);

  final classifica = results[0] as List<SquadraCalcio>;
  final calendario = results[1] as List<PartitaCalcio>;

  // Calcolo forma per ogni squadra
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
// FILTRI
// ============================================================

final faseSelezionataProvider =
    StateProvider<FasePartita>((ref) => FasePartita.andata);



// ============================================================
// CALENDARIO FILTRATO
// ============================================================

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

  final giornate = calendario
      .where((p) => p.fase == fase)
      .map((p) => p.giornata)
      .where((g) => g > 0)
      .toSet()
      .toList()
    ..sort();

  return giornate;
});

// ============================================================
// GIORNATA CORRENTE (prossima partita non giocata)
// ============================================================

final giornataCorrenteProvider = Provider<int?>((ref) {
  final calendarioAsync = ref.watch(calendarioProvider);
  final fase = ref.watch(faseSelezionataProvider);
  final calendario = calendarioAsync.value ?? [];

  // Filtra solo la fase corrente
  final partiteFase =
      calendario.where((p) => p.fase == fase).toList();

  if (partiteFase.isEmpty) return null;

  // Prossima partita non giocata con data valida
  final prossimePartite = partiteFase
      .where((p) => !p.giocata && p.data != null)
      .toList()
    ..sort((a, b) => a.data!.compareTo(b.data!));

  if (prossimePartite.isNotEmpty) {
    return prossimePartite.first.giornata;
  }

  // Se tutte giocate, mostra l'ultima giornata
  final tutteLeGiornate = partiteFase
      .map((p) => p.giornata)
      .where((g) => g > 0)
      .toSet()
      .toList()
    ..sort();

  return tutteLeGiornate.isNotEmpty ? tutteLeGiornate.last : null;
});

// ============================================================
// GIORNATA SELEZIONATA (dall'utente con frecce)
// ============================================================

final giornataSelezionataProvider = StateProvider<int?>((ref) => null);

// ============================================================
// GIORNATA EFFETTIVA (usa selezionata, o corrente come default)
// ============================================================

final giornataEffettivaProvider = Provider<int?>((ref) {
  final selezionata = ref.watch(giornataSelezionataProvider);
  if (selezionata != null) return selezionata;

  return ref.watch(giornataCorrenteProvider);
});