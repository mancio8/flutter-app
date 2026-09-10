import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/manutenzione.dart';
import '../../../core/models/scadenza_veicolo.dart';

class ManutenzioniRepository {
  final SupabaseClient _supabase;

  ManutenzioniRepository(this._supabase);

  // ============================================================
  // MANUTENZIONI
  // ============================================================

  Future<List<Manutenzione>> getManutenzioni({String? veicoloId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query =
        _supabase.from('manutenzioni').select().eq('user_id', userId);

    if (veicoloId != null) {
      query = query.eq('veicolo_id', veicoloId);
    }

    final response = await query.order('data', ascending: false);
    return (response as List)
        .map((json) => Manutenzione.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addManutenzione(Manutenzione manutenzione) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase.from('manutenzioni').insert(manutenzione.toJson());
  }

  Future<void> updateManutenzione(Manutenzione manutenzione) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('manutenzioni')
        .update(manutenzione.toJson())
        .eq('id', manutenzione.id)
        .eq('user_id', userId);
  }

  Future<void> deleteManutenzione(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('manutenzioni')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ============================================================
  // SCADENZE
  // ============================================================

  Future<List<ScadenzaVeicolo>> getScadenze({String? veicoloId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query =
        _supabase.from('scadenze_veicolo').select().eq('user_id', userId);

    if (veicoloId != null) {
      query = query.eq('veicolo_id', veicoloId);
    }

    final response = await query.order('data_scadenza', ascending: true);
    return (response as List)
        .map((json) => ScadenzaVeicolo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addScadenza(ScadenzaVeicolo scadenza) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase.from('scadenze_veicolo').insert(scadenza.toJson());
  }

  Future<void> updateScadenza(ScadenzaVeicolo scadenza) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('scadenze_veicolo')
        .update(scadenza.toJson())
        .eq('id', scadenza.id)
        .eq('user_id', userId);
  }

  Future<void> toggleCompletatoScadenza(String id, bool completato) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('scadenze_veicolo')
        .update({'completato': completato})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> deleteScadenza(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('scadenze_veicolo')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}