import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/viaggio.dart';

class ViaggiRepository {
  final SupabaseClient _client;

  ViaggiRepository(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  // Viaggi già fatti
  Future<List<Viaggio>> getViaggiFatti() async {
    if (_userId.isEmpty) return [];

    final response = await _client
        .from('viaggi')
        .select()
        .eq('user_id', _userId)
        .not('data_visita', 'is', null)
        .order('data_visita', ascending: false);

    return (response as List).map<Viaggio>((j) => Viaggio.fromJson(j)).toList();
  }

  // Wishlist (destinazioni desiderate, non ancora visitate)
  Future<List<Viaggio>> getWishlist() async {
    if (_userId.isEmpty) return [];

    final response = await _client
        .from('viaggi')
        .select()
        .eq('user_id', _userId)
        .eq('in_wishlist', true)
        .filter('data_visita', 'is', null)
        .order('wishlist_date', ascending: false);

    return (response as List).map<Viaggio>((j) => Viaggio.fromJson(j)).toList();
  }

  // Aggiunge una destinazione alla wishlist
  Future<void> addToWishlist(Viaggio viaggio) async {
    await _client.from('viaggi').insert({
      'destinazione': viaggio.destinazione,
      'paese': viaggio.paese,
      'cover_url': viaggio.copertinaUrl,
      'note': viaggio.note,
      'budget_stimato': viaggio.budgetStimato,
      'in_wishlist': true,
      'user_id': _userId,
    });
  }

  // Segna una destinazione come visitata
  Future<void> moveToVisitato(Viaggio viaggio, DateTime dataVisita, {int? rating}) async {
    await _client.from('viaggi').update({
      'data_visita': dataVisita.toIso8601String().split('T')[0],
      'in_wishlist': false,
      'rating': rating,
    }).eq('id', viaggio.id);
  }

  // Rimuove dalla wishlist (elimina se mai visitato, altrimenti solo flag)
  Future<void> removeFromWishlist(String id) async {
    await _client.from('viaggi').delete().eq('id', id);
  }

  // Aggiunge direttamente un viaggio già fatto (senza passare dalla wishlist)
  Future<void> addViaggioFatto(Viaggio viaggio) async {
    await _client.from('viaggi').insert({
      'destinazione': viaggio.destinazione,
      'paese': viaggio.paese,
      'cover_url': viaggio.copertinaUrl,
      'note': viaggio.note,
      'budget_stimato': viaggio.budgetStimato,
      'data_visita': viaggio.dataVisita?.toIso8601String().split('T')[0],
      'rating': viaggio.rating,
      'in_wishlist': false,
      'user_id': _userId,
    });
  }

  Future<void> updateViaggio(Viaggio viaggio) async {
    await _client.from('viaggi').update({
      'destinazione': viaggio.destinazione,
      'paese': viaggio.paese,
      'cover_url': viaggio.copertinaUrl,
      'note': viaggio.note,
      'budget_stimato': viaggio.budgetStimato,
      'data_visita': viaggio.dataVisita?.toIso8601String().split('T')[0],
      'rating': viaggio.rating,
    }).eq('id', viaggio.id);
  }

  Future<void> deleteViaggio(String id) async {
    await _client.from('viaggi').delete().eq('id', id);
  }
}