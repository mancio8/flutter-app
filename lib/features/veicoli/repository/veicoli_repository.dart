import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/veicolo.dart';

class VeicoliRepository {
  final SupabaseClient _supabase;
  
  VeicoliRepository(this._supabase);

  // Ottiene tutti i veicoli dell'utente corrente
  Future<List<Veicolo>> getVeicoli() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('veicoli')
        .select()
        .eq('user_id', userId)
        .order('nome');

    return response
        .map<Veicolo>((json) => Veicolo.fromJson(json))
        .toList();
  }

  // Aggiunge un nuovo veicolo
  Future<void> addVeicolo(Veicolo veicolo) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = veicolo.toJson()
      ..['user_id'] = userId
      ..remove('id'); // Lascia che Supabase generi l'UUID

    await _supabase.from('veicoli').insert(data);
  }

  // Aggiorna un veicolo esistente
  Future<void> updateVeicolo(Veicolo veicolo) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = veicolo.toJson()
      ..['user_id'] = userId
      ..remove('id'); // Non aggiorniamo l'ID

    await _supabase
        .from('veicoli')
        .update(data)
        .eq('id', veicolo.id)
        .eq('user_id', userId); // Sicurezza extra
  }

  // Elimina un veicolo
  Future<void> deleteVeicolo(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('veicoli')
        .delete()
        .eq('id', id)
        .eq('user_id', userId); // Sicurezza extra
  }
}