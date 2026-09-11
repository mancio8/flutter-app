class SerieEsercizio {
  final String id;
  final String esercizioId;
  final double peso; // in kg
  final int ripetizioni;
  final DateTime data;
  final String? note;

  const SerieEsercizio({
    required this.id,
    required this.esercizioId,
    required this.peso,
    required this.ripetizioni,
    required this.data,
    this.note,
  });

  // Volume di questa serie (peso totale sollevato)
  double get volume => peso * ripetizioni;

  SerieEsercizio copyWith({
    String? id,
    String? esercizioId,
    double? peso,
    int? ripetizioni,
    DateTime? data,
    String? note,
  }) {
    return SerieEsercizio(
      id: id ?? this.id,
      esercizioId: esercizioId ?? this.esercizioId,
      peso: peso ?? this.peso,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      data: data ?? this.data,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'esercizioId': esercizioId,
    'peso': peso,
    'ripetizioni': ripetizioni,
    'data': data.toIso8601String(),
    'note': note,
  };

  factory SerieEsercizio.fromJson(Map<String, dynamic> json) {
    return SerieEsercizio(
      id: json['id'],
      esercizioId: json['esercizio_id'], // era 'esercizioId'
      peso: (json['peso'] as num).toDouble(),
      ripetizioni: json['ripetizioni'],
      data: DateTime.parse(json['data']),
      note: json['note'],
    );
  }
}
