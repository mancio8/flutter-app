import 'package:flutter/material.dart';

enum CategoriaNota {
  generale,
  lavoro,
  personale,
  urgente,
  idea,
}

extension CategoriaNotaExtension on CategoriaNota {
  String get label {
    switch (this) {
      case CategoriaNota.generale:
        return 'Generale';
      case CategoriaNota.lavoro:
        return 'Lavoro';
      case CategoriaNota.personale:
        return 'Personale';
      case CategoriaNota.urgente:
        return 'Urgente';
      case CategoriaNota.idea:
        return 'Idea';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoriaNota.generale:
        return Icons.note;
      case CategoriaNota.lavoro:
        return Icons.work_outline;
      case CategoriaNota.personale:
        return Icons.person_outline;
      case CategoriaNota.urgente:
        return Icons.priority_high;
      case CategoriaNota.idea:
        return Icons.lightbulb_outline;
    }
  }
}

// Colori disponibili per le note (stile sticky notes)
class ColoreNota {
  static const List<Color> palette = [
    Color(0xFFFFF9C4), // giallo
    Color(0xFFFFCCBC), // arancio
    Color(0xFFC8E6C9), // verde
    Color(0xFFB3E5FC), // azzurro
    Color(0xFFE1BEE7), // viola
    Color(0xFFF8BBD0), // rosa
    Color(0xFFD7CCC8), // marrone chiaro
    Color(0xFFCFD8DC), // grigio
  ];

  static Color fromValue(int value) => Color(value);
}

class Nota {
  final String id;
  final String testo;
  final CategoriaNota categoria;
  final int colore; // valore ARGB del colore
  final DateTime dataCreazione;
  final bool fissata;

  const Nota({
    required this.id,
    required this.testo,
    required this.categoria,
    required this.colore,
    required this.dataCreazione,
    this.fissata = false,
  });

  Nota copyWith({
    String? id,
    String? testo,
    CategoriaNota? categoria,
    int? colore,
    DateTime? dataCreazione,
    bool? fissata,
  }) {
    return Nota(
      id: id ?? this.id,
      testo: testo ?? this.testo,
      categoria: categoria ?? this.categoria,
      colore: colore ?? this.colore,
      dataCreazione: dataCreazione ?? this.dataCreazione,
      fissata: fissata ?? this.fissata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testo': testo,
      'categoria': categoria.name,
      'colore': colore,
      'dataCreazione': dataCreazione.toIso8601String(),
      'fissata': fissata,
    };
  }

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'],
      testo: json['testo'] ?? '',
      categoria: CategoriaNota.values.firstWhere(
        (c) => c.name == json['categoria'],
        orElse: () => CategoriaNota.generale,
      ),
      colore: json['colore'] ?? ColoreNota.palette[0].value,
      dataCreazione: DateTime.parse(json['dataCreazione']),
      fissata: json['fissata'] ?? false,
    );
  }
}