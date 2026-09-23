import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/squadra_calcio.dart';
import '../../../core/models/partita_calcio.dart';

class GironeRepository {
  final http.Client _client;

  GironeRepository({http.Client? client})
      : _client = client ?? http.Client();

  Map<String, dynamic>? _cachedData;
  DateTime? _lastFetch;
  String? _cachedUrl;
  static const Duration _cacheDuration = Duration(minutes: 10);

  Future<Map<String, dynamic>> fetchJson(
    String url, {
    bool forceRefresh = false,
  }) async {
    // Cache valida solo se l'URL è lo stesso
    if (!forceRefresh &&
        _cachedData != null &&
        _cachedUrl == url &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedData!;
    }

    final response = await _client.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Errore download JSON: ${response.statusCode}');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    _cachedData = decoded;
    _cachedUrl = url;
    _lastFetch = DateTime.now();

    return decoded;
  }

  List<SquadraCalcio> parseClassifica(Map<String, dynamic> data) {
    final classifica = data['classifica'] as List<dynamic>? ?? [];
    return classifica
        .map((e) => SquadraCalcio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<PartitaCalcio> parseCalendario(Map<String, dynamic> data) {
    final calendario = data['calendario'] as List<dynamic>? ?? [];
    return calendario
        .map((e) => PartitaCalcio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void invalidateCache() {
    _cachedData = null;
    _lastFetch = null;
    _cachedUrl = null;
  }
}