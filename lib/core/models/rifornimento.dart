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

  // Converte in JSON per salvarlo
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

  // Crea da JSON
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