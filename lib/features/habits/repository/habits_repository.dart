import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/habit.dart';

class HabitsRepository {
  static const String _storageKey = 'habits_list';
  List<Habit> _habits = [];

  // Dati iniziali di esempio
  static const String _datiIniziali = '''
[
  {
    "id": "1",
    "nome": "Bere acqua",
    "descrizione": "Bere 2 litri di acqua al giorno",
    "icona": "💧",
    "colore": "#2196F3",
    "dataCreazione": "2026-01-01",
    "completamenti": [],
    "obiettivoMensile": 30
  },
  {
    "id": "2",
    "nome": "Leggere",
    "descrizione": "Leggere 30 minuti al giorno",
    "icona": "📚",
    "colore": "#9C27B0",
    "dataCreazione": "2026-01-01",
    "completamenti": [],
    "obiettivoMensile": 20
  },
  {
    "id": "3",
    "nome": "Esercizio fisico",
    "descrizione": "30 minuti di attività fisica",
    "icona": "🏃",
    "colore": "#FF5722",
    "dataCreazione": "2026-01-01",
    "completamenti": [],
    "obiettivoMensile": 15
  }
]
''';

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _habits = jsonList
          .map((json) => Habit.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      // Prima volta: carica i dati iniziali
      final List<dynamic> jsonList = json.decode(_datiIniziali);
      _habits = jsonList
          .map((json) => Habit.fromJson(json as Map<String, dynamic>))
          .toList();
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      _habits.map((h) => h.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  Future<List<Habit>> getHabits() async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }
    return List.unmodifiable(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }
    _habits.add(habit);
    await _saveToStorage();
  }

  Future<void> updateHabit(Habit habit) async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      await _saveToStorage();
    }
  }

  Future<void> deleteHabit(String id) async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }
    _habits.removeWhere((h) => h.id == id);
    await _saveToStorage();
  }

  // Toggle completamento per oggi
  Future<void> toggleCompletamento(String id, DateTime data) async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      if (habit.isCompletata(data)) {
        _habits[index] = habit.rimuoviCompletamento(data);
      } else {
        _habits[index] = habit.aggiungiCompletamento(data);
      }
      await _saveToStorage();
    }
  }

  // Aggiungi questi metodi alla classe HabitsRepository

  // Importa habits (unisce)
  Future<int> importHabits(List<Habit> nuoviHabits) async {
    if (_habits.isEmpty) {
      await _loadFromStorage();
    }

    int aggiunti = 0;
    for (final nuovo in nuoviHabits) {
      final esiste = _habits.any(
        (h) => h.nome.toLowerCase() == nuovo.nome.toLowerCase(),
      );

      if (!esiste) {
        _habits.add(nuovo);
        aggiunti++;
      }
    }

    if (aggiunti > 0) {
      await _saveToStorage();
    }

    return aggiunti;
  }

  // Sostituisci tutti gli habits
  Future<void> replaceAllHabits(List<Habit> nuoviHabits) async {
    _habits = List.from(nuoviHabits);
    await _saveToStorage();
  }
}
