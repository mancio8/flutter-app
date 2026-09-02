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
  });

  // NUOVO: Metodo copyWith per creare una copia con modifiche
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
    bool clearChilometraggio = false,
    bool clearNote = false,
  }) {
    return Rifornimento(
      id: id ?? this.id,
      veicoloId: veicoloId ?? this.veicoloId,
      data: data ?? this.data,
      litri: litri ?? this.litri,
      costo: costo ?? this.costo,
      prezzoPerLitro: prezzoPerLitro ?? this.prezzoPerLitro,
      tipoCarburante: tipoCarburante ?? this.tipoCarburante,
      chilometraggio: clearChilometraggio ? null : (chilometraggio ?? this.chilometraggio),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'veicoloId': veicoloId,
      'data': data.toIso8601String(),
      'litri': litri,
      'costo': costo,
      'prezzoPerLitro': prezzoPerLitro,
      'tipoCarburante': tipoCarburante,
      'chilometraggio': chilometraggio,
      'note': note,
    };
  }

  factory Rifornimento.fromJson(Map<String, dynamic> json) {
    return Rifornimento(
      id: json['id'],
      veicoloId: json['veicoloId'],
      data: DateTime.parse(json['data']),
      litri: json['litri'].toDouble(),
      costo: json['costo'].toDouble(),
      prezzoPerLitro: json['prezzoPerLitro'].toDouble(),
      tipoCarburante: json['tipoCarburante'],
      chilometraggio: json['chilometraggio']?.toDouble(),
      note: json['note'],
    );
  }
}