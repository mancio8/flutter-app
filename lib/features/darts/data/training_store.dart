import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/x01_game.dart';

class TrainingStore {
  static String _key(String name, int start, OutRule rule) =>
      'darts_training_${name}_${start}_${rule.name}';

  static Future<List<Map<String, dynamic>>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw) as List);
  }

  /// Miglior media tra le sessioni concluse con una chiusura
  static Future<double?> bestAvg(String name, int start, OutRule rule) async {
    final list = await _load(_key(name, start, rule));
    final avgs = list
        .where((s) => s['completed'] == true)
        .map((s) => (s['avg'] as num).toDouble());
    return avgs.isEmpty ? null : avgs.reduce(max);
  }

  /// Ritorna true se la sessione batte il record precedente
  static Future<bool> save(
    String name,
    int start,
    OutRule rule, {
    required double avg,
    required int darts,
    required int highTurn,
    required bool completed,
  }) async {
    final key = _key(name, start, rule);
    final previous = await bestAvg(name, start, rule);
    final list = await _load(key);

    list.add({
      'avg': avg,
      'darts': darts,
      'highTurn': highTurn,
      'completed': completed,
      'date': DateTime.now().toIso8601String(),
    });
    if (list.length > 50) list.removeRange(0, list.length - 50);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(list));
    return completed && previous != null && avg > previous;
  }
}