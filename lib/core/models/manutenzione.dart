class Manutenzione {
  final String id;
  final String veicoloId;
  final String titolo;
  final DateTime data;
  final double? chilometraggio;
  final double costo;
  final String? note;

  const Manutenzione({
    required this.id,
    required this.veicoloId,
    required this.titolo,
    required this.data,
    this.chilometraggio,
    this.costo = 0,
    this.note,
  });

  factory Manutenzione.fromJson(Map<String, dynamic> json) {
    return Manutenzione(
      id: json['id'] as String,
      veicoloId: json['veicolo_id'] as String,
      titolo: json['titolo'] as String,
      data: DateTime.parse(json['data'] as String),
      chilometraggio: (json['chilometraggio'] as num?)?.toDouble(),
      costo: (json['costo'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
    );
  }

  /// Per INSERT su Supabase: niente id (lo genera il DB),
  /// niente user_id (lo mette auth.uid() di default).
  Map<String, dynamic> toJson() => {
        'veicolo_id': veicoloId,
        'titolo': titolo,
        'data': data.toIso8601String().split('T').first,
        if (chilometraggio != null) 'chilometraggio': chilometraggio,
        'costo': costo,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  Manutenzione copyWith({
    String? id,
    String? veicoloId,
    String? titolo,
    DateTime? data,
    double? chilometraggio,
    double? costo,
    String? note,
    bool clearChilometraggio = false,
    bool clearNote = false,
  }) {
    return Manutenzione(
      id: id ?? this.id,
      veicoloId: veicoloId ?? this.veicoloId,
      titolo: titolo ?? this.titolo,
      data: data ?? this.data,
      chilometraggio: clearChilometraggio
          ? null
          : (chilometraggio ?? this.chilometraggio),
      costo: costo ?? this.costo,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}