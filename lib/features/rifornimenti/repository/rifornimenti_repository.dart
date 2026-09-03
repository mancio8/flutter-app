import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/rifornimento.dart';

class RifornimentiRepository {
  // Chiave per salvare i dati in SharedPreferences
  static const String _storageKey = 'rifornimenti_list';

  // Lista in memoria (cache)
  List<Rifornimento> _rifornimenti = [];

  // Carica i dati da SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _rifornimenti = jsonList
          .map((json) => Rifornimento.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  // Salva i dati su SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      _rifornimenti.map((r) => r.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  // Ottiene tutti i rifornimenti
  Future<List<Rifornimento>> getRifornimenti() async {
    // Carica dal storage se la lista è vuota
    if (_rifornimenti.isEmpty) {
      await _loadFromStorage();
    }
    return List.unmodifiable(_rifornimenti);
  }

  // Ottiene rifornimenti per un veicolo specifico
  Future<List<Rifornimento>> getRifornimentiPerVeicolo(String veicoloId) async {
    final all = await getRifornimenti();
    return all.where((r) => r.veicoloId == veicoloId).toList();
  }

  // Aggiunge un nuovo rifornimento
  Future<void> addRifornimento(Rifornimento rifornimento) async {
    if (_rifornimenti.isEmpty) {
      await _loadFromStorage();
    }
    _rifornimenti.add(rifornimento);
    await _saveToStorage(); // Salva subito!
  }

  // Elimina un rifornimento
  Future<void> deleteRifornimento(String id) async {
    if (_rifornimenti.isEmpty) {
      await _loadFromStorage();
    }
    _rifornimenti.removeWhere((r) => r.id == id);
    await _saveToStorage(); // Salva subito!
  }

  // Aggiorna un rifornimento esistente
  Future<void> updateRifornimento(Rifornimento rifornimento) async {
    if (_rifornimenti.isEmpty) {
      await _loadFromStorage();
    }
    final index = _rifornimenti.indexWhere((r) => r.id == rifornimento.id);
    if (index != -1) {
      _rifornimenti[index] = rifornimento;
      await _saveToStorage();
    }
  }

  // Elimina tutti i rifornimenti
  Future<void> clearAll() async {
    _rifornimenti.clear();
    await _saveToStorage();
  }

  // Importa da JSON (unisce o sostituisce la lista esistente)
  Future<int> importFromJson(String jsonString, {bool merge = true}) async {
    if (_rifornimenti.isEmpty) {
      await _loadFromStorage();
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Rifornimento> importati = [];
    for (var i = 0; i < jsonList.length; i++) {
      final map = jsonList[i] as Map<String, dynamic>;
      var rifornimento = Rifornimento.fromJson(map);
      if (map['id'] == null || (map['id'] as String).isEmpty) {
        rifornimento = rifornimento.copyWith(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        );
      }
      importati.add(rifornimento);
    }

    if (merge) {
      final idEsistenti = _rifornimenti.map((r) => r.id).toSet();
      final nuovi = importati
          .where((r) => !idEsistenti.contains(r.id))
          .toList();

      _rifornimenti.addAll(nuovi);
      await _saveToStorage();
      return nuovi.length;
    } else {
      _rifornimenti = importati;
      await _saveToStorage();
      return _rifornimenti.length;
    }
  }
}
