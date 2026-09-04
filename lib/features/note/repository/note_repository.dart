import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/nota.dart';

class NoteRepository {
  static const String _storageKey = 'note_list';
  List<Nota> _note = [];

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _note = jsonList
          .map((json) => Nota.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      _note.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  Future<List<Nota>> getNote() async {
    if (_note.isEmpty) {
      await _loadFromStorage();
    }
    return List.unmodifiable(_note);
  }

  Future<void> addNota(Nota nota) async {
    if (_note.isEmpty) {
      await _loadFromStorage();
    }
    _note.add(nota);
    await _saveToStorage();
  }

  Future<void> updateNota(Nota nota) async {
    if (_note.isEmpty) {
      await _loadFromStorage();
    }
    final index = _note.indexWhere((n) => n.id == nota.id);
    if (index != -1) {
      _note[index] = nota;
      await _saveToStorage();
    }
  }

  Future<void> deleteNota(String id) async {
    if (_note.isEmpty) {
      await _loadFromStorage();
    }
    _note.removeWhere((n) => n.id == id);
    await _saveToStorage();
  }

  Future<void> togglePin(String id) async {
    if (_note.isEmpty) {
      await _loadFromStorage();
    }
    final index = _note.indexWhere((n) => n.id == id);
    if (index != -1) {
      _note[index] = _note[index].copyWith(fissata: !_note[index].fissata);
      await _saveToStorage();
    }
  }
}