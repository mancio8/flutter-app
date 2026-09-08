import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/nota.dart';

class NoteRepository {
  final SupabaseClient _client;

  NoteRepository(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<List<Nota>> getNote() async {
    if (_userId.isEmpty) {
      throw Exception('Utente non autenticato');
    }

    final response = await _client
        .from('note')
        .select()
        .eq('user_id', _userId)
        .order('data_creazione', ascending: false);

    return (response as List)
        .map((json) => Nota.fromJson(json))
        .toList();
  }

  Future<Nota> addNota(Nota nota) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Utente non autenticato');
    }

    final response = await _client
        .from('note')
        .insert({
          'user_id': user.id,
          'testo': nota.testo,
          'categoria': nota.categoria.name,
          'colore': nota.colore,
          'fissata': nota.fissata,
        })
        .select()
        .single();

    return Nota.fromJson(response);
  }

  Future<void> updateNota(Nota nota) async {
    await _client
        .from('note')
        .update({
          'testo': nota.testo,
          'categoria': nota.categoria.name,
          'colore': nota.colore,
          'fissata': nota.fissata,
        })
        .eq('id', nota.id)
        .eq('user_id', _userId);
  }

  Future<void> deleteNota(String id) async {
    await _client
        .from('note')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> togglePin(String id, bool nuovoValore) async {
    await _client
        .from('note')
        .update({
          'fissata': nuovoValore,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }
}