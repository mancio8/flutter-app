import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/campionato_config.dart';

class CampionatoConfigRepository {
  final SupabaseClient _client;

  CampionatoConfigRepository(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<CampionatoConfig?> getConfig() async {
    if (_userId.isEmpty) return null;

    final response = await _client
        .from('campionato_config')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return CampionatoConfig.fromJson(response);
  }

  Future<CampionatoConfig> upsertConfig(CampionatoConfig config) async {
    if (_userId.isEmpty) throw Exception('Utente non autenticato');

    final data = await _client
        .from('campionato_config')
        .upsert(
          {
            'user_id': _userId,
            'json_url': config.jsonUrl,
            'squadra_preferita': config.squadraPreferita,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id',
        )
        .select()
        .single();

    return CampionatoConfig.fromJson(data);
  }
}