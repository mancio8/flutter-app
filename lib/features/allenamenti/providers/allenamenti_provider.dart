import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/esercizio.dart';
import '../../../core/models/serie_esercizio.dart';
import '../repository/allenamenti_repository.dart';
import '../../../core/providers/supabase_provider.dart';

final allenamentiRepositoryProvider = Provider<AllenamentiRepository>((ref) {
  final supabase = ref.watch(supabaseProvider); // era: AllenamentiRepository()
  return AllenamentiRepository(supabase);
});

// ======================================================================
// ESERCIZI
// ======================================================================

class EserciziNotifier
    extends AsyncNotifier<List<Esercizio>> {

  @override
  Future<List<Esercizio>> build() async {
    final repository =
        ref.watch(allenamentiRepositoryProvider);

    // IMPORTANTE:
    // getEsercizi() potrebbe restituire una lista non modificabile.
    // Creiamo quindi una copia modificabile prima di fare sort().
    final esercizi = List<Esercizio>.from(
      await repository.getEsercizi(),
    );

    esercizi.sort(
      (a, b) => a.nome.compareTo(b.nome),
    );

    return esercizi;
  }

  // ------------------------------------------------------------------
  // AGGIUNGI
  // ------------------------------------------------------------------

  Future<void> addEsercizio(
    Esercizio esercizio,
  ) async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    await repository.addEsercizio(esercizio);

    await _reload();
  }

  // ------------------------------------------------------------------
  // ELIMINA
  // ------------------------------------------------------------------

  Future<void> deleteEsercizio(
    String id,
  ) async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    await repository.deleteEsercizio(id);

    await _reload();

    // Elimina/invalida eventuali serie collegate
    ref.invalidate(serieProvider);
  }

  // ------------------------------------------------------------------
  // RICARICA
  // ------------------------------------------------------------------

  Future<void> _reload() async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    final esercizi = List<Esercizio>.from(
      await repository.getEsercizi(),
    );

    esercizi.sort(
      (a, b) => a.nome.compareTo(b.nome),
    );

    state = AsyncValue.data(esercizi);
  }
}

final eserciziProvider =
    AsyncNotifierProvider<
      EserciziNotifier,
      List<Esercizio>
    >(
      EserciziNotifier.new,
    );

// ======================================================================
// SERIE
// ======================================================================

class SerieNotifier
    extends AsyncNotifier<List<SerieEsercizio>> {

  @override
  Future<List<SerieEsercizio>> build() async {
    final repository =
        ref.watch(allenamentiRepositoryProvider);

    // Anche qui creiamo una lista modificabile.
    return List<SerieEsercizio>.from(
      await repository.getSerie(),
    );
  }

  // ------------------------------------------------------------------
  // AGGIUNGI SERIE
  // ------------------------------------------------------------------

  Future<void> addSerie(
    SerieEsercizio serie,
  ) async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    await repository.addSerie(serie);

    await _reload();
  }

  // ------------------------------------------------------------------
  // MODIFICA SERIE
  // ------------------------------------------------------------------

  Future<void> updateSerie(
    SerieEsercizio serie,
  ) async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    await repository.updateSerie(serie);

    await _reload();
  }

  // ------------------------------------------------------------------
  // ELIMINA SERIE
  // ------------------------------------------------------------------

  Future<void> deleteSerie(
    String id,
  ) async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    await repository.deleteSerie(id);

    await _reload();
  }

  // ------------------------------------------------------------------
  // RICARICA
  // ------------------------------------------------------------------

  Future<void> _reload() async {
    final repository =
        ref.read(allenamentiRepositoryProvider);

    final serie = List<SerieEsercizio>.from(
      await repository.getSerie(),
    );

    state = AsyncValue.data(serie);
  }
}

final serieProvider =
    AsyncNotifierProvider<
      SerieNotifier,
      List<SerieEsercizio>
    >(
      SerieNotifier.new,
    );

// ======================================================================
// SERIE PER ESERCIZIO
// ======================================================================

final seriePerEsercizioProvider =
    Provider.family<
      AsyncValue<List<SerieEsercizio>>,
      String
    >(
      (ref, esercizioId) {
        final serieAsync =
            ref.watch(serieProvider);

        return serieAsync.whenData(
          (serie) {
            final filtrate = serie
                .where(
                  (s) =>
                      s.esercizioId ==
                      esercizioId,
                )
                .toList();

            filtrate.sort(
              (a, b) =>
                  a.data.compareTo(b.data),
            );

            return filtrate;
          },
        );
      },
    );

// ======================================================================
// PROGRESSO
// ======================================================================

class PuntoProgresso {
  final DateTime data;
  final double pesoMassimo;
  final double volumeTotale;

  const PuntoProgresso({
    required this.data,
    required this.pesoMassimo,
    required this.volumeTotale,
  });
}

final progressoEsercizioProvider =
    Provider.family<
      AsyncValue<List<PuntoProgresso>>,
      String
    >(
      (ref, esercizioId) {
        final serieAsync =
            ref.watch(
              seriePerEsercizioProvider(
                esercizioId,
              ),
            );

        return serieAsync.whenData(
          (serie) {
            // --------------------------------------------------------
            // Raggruppamento per giorno
            // --------------------------------------------------------

            final Map<
              DateTime,
              List<SerieEsercizio>
            > perGiorno = {};

            for (final s in serie) {
              final giorno = DateTime(
                s.data.year,
                s.data.month,
                s.data.day,
              );

              perGiorno
                  .putIfAbsent(
                    giorno,
                    () => <SerieEsercizio>[],
                  )
                  .add(s);
            }

            // --------------------------------------------------------
            // Creazione punti grafico
            // --------------------------------------------------------

            final punti =
                perGiorno.entries.map(
              (entry) {
                final pesoMassimo =
                    entry.value
                        .map(
                          (s) => s.peso,
                        )
                        .reduce(
                          (a, b) =>
                              a > b ? a : b,
                        );

                final volumeTotale =
                    entry.value.fold<double>(
                  0,
                  (sum, s) =>
                      sum + s.volume,
                );

                return PuntoProgresso(
                  data: entry.key,
                  pesoMassimo:
                      pesoMassimo,
                  volumeTotale:
                      volumeTotale,
                );
              },
            ).toList();

            punti.sort(
              (a, b) =>
                  a.data.compareTo(b.data),
            );

            return punti;
          },
        );
      },
    );

// ======================================================================
// ULTIMA SERIE
// ======================================================================

final ultimaSerieProvider =
    Provider.family<
      AsyncValue<SerieEsercizio?>,
      String
    >(
      (ref, esercizioId) {
        final serieAsync =
            ref.watch(
              seriePerEsercizioProvider(
                esercizioId,
              ),
            );

        return serieAsync.whenData(
          (serie) {
            if (serie.isEmpty) {
              return null;
            }

            return serie.last;
          },
        );
      },
    );