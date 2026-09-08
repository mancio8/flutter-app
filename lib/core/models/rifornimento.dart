class Rifornimento {
  final String id;
  final String? veicoloId;
  final DateTime data;
  final double litri;
  final double costo;
  final double prezzoPerLitro;
  final String tipoCarburante;
  final double? chilometraggio;
  final String? note;
  final String? userId; // NUOVO: per associare il rifornimento all'utente

  const Rifornimento({
    required this.id,
    this.veicoloId,
    required this.data,
    required this.litri,
    required this.costo,
    required this.prezzoPerLitro,
    required this.tipoCarburante,
    this.chilometraggio,
    this.note,
    this.userId,
  });

  Rifornimento copyWith({
    String? id,
    String? veicoloId,
    DateTime? data,
    double? litri,
    double? costo,
    double? prezzoPerLitro,
    String? tipoCarburante,
    double? chilometraggio,
    String? note,
    String? userId,
    bool clearChilometraggio = false,
    bool clearNote = false,
    bool clearVeicoloId = false,
  }) {
    return Rifornimento(
      id: id ?? this.id,
      veicoloId: clearVeicoloId ? null : (veicoloId ?? this.veicoloId),
      data: data ?? this.data,
      litri: litri ?? this.litri,
      costo: costo ?? this.costo,
      prezzoPerLitro: prezzoPerLitro ?? this.prezzoPerLitro,
      tipoCarburante: tipoCarburante ?? this.tipoCarburante,
      chilometraggio: clearChilometraggio ? null : (chilometraggio ?? this.chilometraggio),
      note: clearNote ? null : (note ?? this.note),
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'veicolo_id': veicoloId, // NOTA: Supabase usa snake_case
      'data': data.toIso8601String(),
      'litri': litri,
      'costo': costo,
      'prezzo_per_litro': prezzoPerLitro, // NOTA: snake_case
      'tipo_carburante': tipoCarburante, // NOTA: snake_case
      'chilometraggio': chilometraggio,
      'note': note,
      'user_id': userId, // NOTA: snake_case
    };
  }

  factory Rifornimento.fromJson(Map<String, dynamic> json) {
    return Rifornimento(
      id: json['id'] ?? '',
      veicoloId: json['veicolo_id'] ?? json['veicoloId'], // Gestisce entrambi i formati
      data: DateTime.parse(json['data']),
      litri: (json['litri'] as num).toDouble(),
      costo: (json['costo'] as num).toDouble(),
      prezzoPerLitro: (json['prezzo_per_litro'] ?? json['prezzoPerLitro'] as num).toDouble(),
      tipoCarburante: json['tipo_carburante'] ?? json['tipoCarburante'],
      chilometraggio: (json['chilometraggio'] as num?)?.toDouble(),
      note: json['note'],
      userId: json['user_id'] ?? json['userId'],
    );
  }
}