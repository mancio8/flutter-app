import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/rifornimento.dart';
import 'dart:convert';

class RifornimentiRepository {
  final SupabaseClient _supabase;
  
  RifornimentiRepository(this._supabase);

  // Ottiene tutti i rifornimenti dell'utente corrente
  Future<List<Rifornimento>> getRifornimenti() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('rifornimenti')
        .select()
        .eq('user_id', userId)
        .order('data', ascending: false);

    return response
        .map<Rifornimento>((json) => Rifornimento.fromJson(json))
        .toList();
  }

  // Ottiene rifornimenti per un veicolo specifico
  Future<List<Rifornimento>> getRifornimentiPerVeicolo(String veicoloId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('rifornimenti')
        .select()
        .eq('user_id', userId)
        .eq('veicolo_id', veicoloId)
        .order('data', ascending: false);

    return response
        .map<Rifornimento>((json) => Rifornimento.fromJson(json))
        .toList();
  }

  // Aggiunge un nuovo rifornimento
  Future<void> addRifornimento(Rifornimento rifornimento) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = rifornimento.toJson()
      ..['user_id'] = userId
      ..remove('id'); // Lascia che Supabase generi l'UUID

    await _supabase.from('rifornimenti').insert(data);
  }

  // Aggiorna un rifornimento esistente
  Future<void> updateRifornimento(Rifornimento rifornimento) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = rifornimento.toJson()
      ..['user_id'] = userId
      ..remove('id'); // Non aggiorniamo l'ID

    await _supabase
        .from('rifornimenti')
        .update(data)
        .eq('id', rifornimento.id)
        .eq('user_id', userId); // Sicurezza extra
  }

  // Elimina un rifornimento
  Future<void> deleteRifornimento(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('rifornimenti')
        .delete()
        .eq('id', id)
        .eq('user_id', userId); // Sicurezza extra
  }

  // Elimina tutti i rifornimenti dell'utente
  Future<void> clearAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('rifornimenti')
        .delete()
        .eq('user_id', userId);
  }

  // Importa rifornimenti da JSON
  Future<int> importFromJson(String jsonString, {bool merge = true}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Map<String, dynamic>> rifornimentiDaImportare = [];

    for (var i = 0; i < jsonList.length; i++) {
      final map = jsonList[i] as Map<String, dynamic>;
      final rifornimento = Rifornimento.fromJson(map);
      
      final data = rifornimento.toJson()
        ..['user_id'] = userId
        ..remove('id');

      rifornimentiDaImportare.add(data);
    }

    if (!merge) {
      // Se non vogliamo unire, prima eliminiamo tutti i rifornimenti esistenti
      await clearAll();
    }

    if (rifornimentiDaImportare.isNotEmpty) {
      await _supabase.from('rifornimenti').insert(rifornimentiDaImportare);
    }

    return rifornimentiDaImportare.length;
  }
}