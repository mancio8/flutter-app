import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/squadra_calcio.dart';
import '../../../core/models/partita_calcio.dart';

class GironeRepository {
  /// URL da cui scaricare il JSON.
  /// Puoi metterlo come costante o passarlo da fuori.
  static const String jsonUrl =
      'https://vincenzomancinelli.it/campionato_2026_EC_A.json';

  /// Cache in memoria per non riscaricare ad ogni chiamata
  Map<String, dynamic>? _cachedData;
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 10);

  Future<Map<String, dynamic>> _fetchJson({bool forceRefresh = false}) async {
    // Se ho cache valida, la uso
    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedData!;
    }

    final response = await http.get(
      Uri.parse(jsonUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Errore nel download del JSON: ${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    _cachedData = decoded;
    _lastFetch = DateTime.now();

    return decoded;
  }

  Future<List<SquadraCalcio>> getClassifica({bool forceRefresh = false}) async {
    final data = await _fetchJson(forceRefresh: forceRefresh);
    final classifica = data['classifica'] as List<dynamic>? ?? [];
    return classifica
        .map((e) => SquadraCalcio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PartitaCalcio>> getCalendario({bool forceRefresh = false}) async {
    final data = await _fetchJson(forceRefresh: forceRefresh);
    final calendario = data['calendario'] as List<dynamic>? ?? [];
    return calendario
        .map((e) => PartitaCalcio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Forza il refresh al prossimo accesso
  void invalidateCache() {
    _cachedData = null;
    _lastFetch = null;
  }
}