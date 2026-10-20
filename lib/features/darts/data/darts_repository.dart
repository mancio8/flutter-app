import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/darts_models.dart';
import '../domain/x01_game.dart';

class DartsRepository {
  DartsRepository(this._client);
  final SupabaseClient _client;

  // ---------------- giocatori ----------------

  Future<List<DartsPlayer>> getPlayers() async {
    final players = (await _client.from('darts_players').select().order('name'))
        as List;
    final stats = (await _client.from('darts_player_stats').select()) as List;

    final byId = <String, Map<String, dynamic>>{
      for (final s in stats.cast<Map<String, dynamic>>())
        s['player_id'] as String: s,
    };

    return players.cast<Map<String, dynamic>>().map((j) {
      final s = byId[j['id']];
      return DartsPlayer.fromJson({
        ...j,
        'games_played': s?['games_played'] ?? 0,
        'games_won': s?['games_won'] ?? 0,
        'avg_ppr': s?['avg_ppr'] ?? 0,
      });
    }).toList();
  }

  Future<void> createPlayer(String name, String avatar, String color) async {
    await _client.from('darts_players').insert({
      'name': name,
      'avatar': avatar,
      'color': color,
    });
  }

  Future<void> deletePlayer(String id) async {
    // partite e turni collegati si cancellano da soli (ON DELETE CASCADE)
    await _client.from('darts_players').delete().eq('id', id);
  }

  // ---------------- partite ----------------

  /// Salva solo i giocatori registrati. Se un passaggio fallisce
  /// la partita appena creata viene rimossa: niente dati a metà.
  Future<void> saveGame({
    required X01Game game,
    required List<DartsPlayer> players,
  }) async {
    final registered = <int>[
      for (var i = 0; i < players.length; i++)
        if (players[i].isRegistered) i,
    ];
    if (registered.isEmpty) return;

    final created = await _client
        .from('darts_games')
        .insert({
          'start_score': game.startScore,
          'out_rule': game.outRule.apiValue,
          'is_training': players.length == 1,
          'completed': game.isOver,
        })
        .select('id')
        .single();
    final gameId = created['id'] as String;

    try {
      await _client.from('darts_game_players').insert(
            registered
                .map((i) => {
                      'game_id': gameId,
                      'player_id': players[i].id,
                      'position': i,
                      'remaining': game.remaining[i],
                      'darts_thrown': game.dartsThrown[i],
                      'total_scored': game.scored[i],
                      'high_turn': game.highTurn[i],
                      'busts': game.busts[i],
                      'checkout_attempts': game.coAttempts[i],
                      'checkout_hits': game.coHits[i],
                      'is_winner': game.winner == i,
                    })
                .toList(),
          );

      final turns = <Map<String, dynamic>>[];
      for (var n = 0; n < game.turns.length; n++) {
        final t = game.turns[n];
        final id = players[t.player].id;
        if (id == null) continue;
        turns.add({
          'game_id': gameId,
          'player_id': id,
          'turn_no': n,
          'score': t.score,
          'bust': t.bust,
          'darts': t.darts.map((d) => {'v': d.value, 'm': d.mult}).toList(),
        });
      }
      if (turns.isNotEmpty) {
        await _client.from('darts_turns').insert(turns);
      }
    } catch (_) {
      await _client.from('darts_games').delete().eq('id', gameId);
      rethrow;
    }
  }

  /// Miglior media in allenamento concluso con chiusura, per la stessa configurazione
  Future<double?> bestTrainingAvg(
    String playerId,
    int startScore,
    OutRule rule,
  ) async {
    final res = await _client
        .from('darts_game_players')
        .select(
          'total_scored, darts_thrown, darts_games!inner(start_score, out_rule, is_training)',
        )
        .eq('player_id', playerId)
        .eq('is_winner', true)
        .eq('darts_games.is_training', true)
        .eq('darts_games.start_score', startScore)
        .eq('darts_games.out_rule', rule.apiValue);

    double? best;
    for (final r in (res as List).cast<Map<String, dynamic>>()) {
      final darts = (r['darts_thrown'] as num).toInt();
      if (darts == 0) continue;
      final avg = (r['total_scored'] as num) / darts * 3;
      if (best == null || avg > best) best = avg.toDouble();
    }
    return best;
  }
}