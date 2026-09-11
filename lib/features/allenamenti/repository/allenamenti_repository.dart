import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/esercizio.dart';
import '../../../../core/models/serie_esercizio.dart';

class AllenamentiRepository {
  final SupabaseClient _client;

  AllenamentiRepository(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  // ==================================================================
  // ESERCIZI
  // ==================================================================

  Future<List<Esercizio>> getEsercizi() async {
    if (_userId.isEmpty) return [];

    final response = await _client
        .from('esercizi')
        .select()
        .eq('user_id', _userId)
        .order('nome');

    final esercizi = (response as List)
        .map<Esercizio>((json) => Esercizio.fromJson(json))
        .toList();

    // Se l'utente non ha ancora nessun esercizio, precarica quelli predefiniti
    if (esercizi.isEmpty) {
      await _inserisciPredefiniti();
      return getEsercizi(); // richiama se stesso, ora troverà i dati appena inseriti
    }

    return esercizi;
  }

  Future<void> _inserisciPredefiniti() async {
    final batch = eserciziPredefiniti.map((e) => {
      'nome': e.nome,
      'categoria': e.categoria.name,
      'user_id': _userId,
    }).toList();

    await _client.from('esercizi').insert(batch);
  }

  Future<void> addEsercizio(Esercizio esercizio) async {
    await _client.from('esercizi').insert({
      'nome': esercizio.nome,
      'categoria': esercizio.categoria.name,
      'user_id': _userId,
    });
  }

  Future<void> deleteEsercizio(String id) async {
    // Le serie collegate vengono cancellate automaticamente
    // grazie a ON DELETE CASCADE nello schema SQL
    await _client.from('esercizi').delete().eq('id', id);
  }

  // ==================================================================
  // SERIE
  // ==================================================================

  Future<List<SerieEsercizio>> getSerie() async {
    if (_userId.isEmpty) return [];

    final response = await _client
        .from('serie_esercizio')
        .select()
        .eq('user_id', _userId)
        .order('data');

    return (response as List)
        .map<SerieEsercizio>((json) => SerieEsercizio.fromJson(json))
        .toList();
  }

  Future<List<SerieEsercizio>> getSeriePerEsercizio(String esercizioId) async {
    final tutte = await getSerie();
    return tutte.where((s) => s.esercizioId == esercizioId).toList();
  }

  Future<void> addSerie(SerieEsercizio serie) async {
    await _client.from('serie_esercizio').insert({
      'esercizio_id': serie.esercizioId,
      'peso': serie.peso,
      'ripetizioni': serie.ripetizioni,
      'data': serie.data.toIso8601String().split('T')[0],
      'note': serie.note,
      'user_id': _userId,
    });
  }

  Future<void> updateSerie(SerieEsercizio serie) async {
    await _client.from('serie_esercizio').update({
      'peso': serie.peso,
      'ripetizioni': serie.ripetizioni,
      'data': serie.data.toIso8601String().split('T')[0],
      'note': serie.note,
    }).eq('id', serie.id);
  }

  Future<void> deleteSerie(String id) async {
    await _client.from('serie_esercizio').delete().eq('id', id);
  }
}