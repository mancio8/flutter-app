import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/esercizio.dart';
import '../../../../core/models/serie_esercizio.dart';

class AllenamentiRepository {
  static const String _eserciziKey = 'allenamenti_esercizi';
  static const String _serieKey = 'allenamenti_serie';

  List<Esercizio> _esercizi = [];
  List<SerieEsercizio> _serie = [];

  bool _eserciziLoaded = false;
  bool _serieLoaded = false;

  // ==================================================================
  // LOAD ESERCIZI
  // ==================================================================

  Future<void> _loadEsercizi() async {
    if (_eserciziLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_eserciziKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> jsonList = json.decode(jsonString);

      _esercizi = jsonList
          .map(
            (j) => Esercizio.fromJson(
              Map<String, dynamic>.from(j as Map),
            ),
          )
          .toList();
    } else {
      // Copia modificabile degli esercizi predefiniti
      _esercizi = List<Esercizio>.from(
        eserciziPredefiniti,
      );

      await _saveEsercizi();
    }

    _eserciziLoaded = true;
  }

  // ==================================================================
  // SAVE ESERCIZI
  // ==================================================================

  Future<void> _saveEsercizi() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = json.encode(
      _esercizi
          .map((e) => e.toJson())
          .toList(),
    );

    await prefs.setString(
      _eserciziKey,
      jsonString,
    );
  }

  // ==================================================================
  // LOAD SERIE
  // ==================================================================

  Future<void> _loadSerie() async {
    if (_serieLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_serieKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> jsonList = json.decode(jsonString);

      _serie = jsonList
          .map(
            (j) => SerieEsercizio.fromJson(
              Map<String, dynamic>.from(j as Map),
            ),
          )
          .toList();
    } else {
      _serie = [];
    }

    _serieLoaded = true;
  }

  // ==================================================================
  // SAVE SERIE
  // ==================================================================

  Future<void> _saveSerie() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = json.encode(
      _serie
          .map((s) => s.toJson())
          .toList(),
    );

    await prefs.setString(
      _serieKey,
      jsonString,
    );
  }

  // ==================================================================
  // ESERCIZI
  // ==================================================================

  Future<List<Esercizio>> getEsercizi() async {
    await _loadEsercizi();

    // Restituiamo una COPIA modificabile.
    //
    // In questo modo il provider può fare:
    //
    // esercizi.sort(...)
    //
    // senza generare:
    //
    // Unsupported operation
    //
    return List<Esercizio>.from(
      _esercizi,
    );
  }

  // ------------------------------------------------------------------
  // ADD ESERCIZIO
  // ------------------------------------------------------------------

  Future<void> addEsercizio(
    Esercizio esercizio,
  ) async {
    await _loadEsercizi();

    _esercizi.add(esercizio);

    await _saveEsercizi();
  }

  // ------------------------------------------------------------------
  // DELETE ESERCIZIO
  // ------------------------------------------------------------------

  Future<void> deleteEsercizio(
    String id,
  ) async {
    await _loadEsercizi();
    await _loadSerie();

    _esercizi.removeWhere(
      (e) => e.id == id,
    );

    // Elimina anche tutte le serie
    // associate all'esercizio.
    _serie.removeWhere(
      (s) => s.esercizioId == id,
    );

    await _saveEsercizi();
    await _saveSerie();
  }

  // ==================================================================
  // SERIE
  // ==================================================================

  Future<List<SerieEsercizio>> getSerie() async {
    await _loadSerie();

    // Anche qui restituiamo una copia modificabile.
    return List<SerieEsercizio>.from(
      _serie,
    );
  }

  // ------------------------------------------------------------------
  // SERIE PER ESERCIZIO
  // ------------------------------------------------------------------

  Future<List<SerieEsercizio>> getSeriePerEsercizio(
    String esercizioId,
  ) async {
    final tutte = await getSerie();

    return tutte
        .where(
          (s) => s.esercizioId == esercizioId,
        )
        .toList();
  }

  // ------------------------------------------------------------------
  // ADD SERIE
  // ------------------------------------------------------------------

  Future<void> addSerie(
    SerieEsercizio serie,
  ) async {
    await _loadSerie();

    _serie.add(serie);

    await _saveSerie();
  }

  // ------------------------------------------------------------------
  // UPDATE SERIE
  // ------------------------------------------------------------------

  Future<void> updateSerie(
    SerieEsercizio serie,
  ) async {
    await _loadSerie();

    final index = _serie.indexWhere(
      (s) => s.id == serie.id,
    );

    if (index == -1) {
      return;
    }

    _serie[index] = serie;

    await _saveSerie();
  }

  // ------------------------------------------------------------------
  // DELETE SERIE
  // ------------------------------------------------------------------

  Future<void> deleteSerie(
    String id,
  ) async {
    await _loadSerie();

    _serie.removeWhere(
      (s) => s.id == id,
    );

    await _saveSerie();
  }
}