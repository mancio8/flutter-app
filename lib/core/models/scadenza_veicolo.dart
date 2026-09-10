class ScadenzaVeicolo {
  final String id;
  final String veicoloId;
  final String tipo; // 'assicurazione' | 'bollo' | 'revisione' | 'altro'
  final DateTime dataScadenza;
  final double? importoStimato;
  final bool completato;

  const ScadenzaVeicolo({
    required this.id,
    required this.veicoloId,
    required this.tipo,
    required this.dataScadenza,
    this.importoStimato,
    this.completato = false,
  });

  /// Giorni mancanti alla scadenza (negativi se già scaduta)
  int get giorniRimanenti {
    final oggi = DateTime.now();
    final oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaSoloData =
        DateTime(dataScadenza.year, dataScadenza.month, dataScadenza.day);
    return scadenzaSoloData.difference(oggiSoloData).inDays;
  }

  bool get isScaduto => giorniRimanenti < 0;

  bool get isInScadenza => giorniRimanenti >= 0 && giorniRimanenti <= 30;

  /// Label leggibile del tipo ('Assicurazione', 'Bollo', ...)
  String get tipoLabel {
    if (tipo.isEmpty) return '';
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  factory ScadenzaVeicolo.fromJson(Map<String, dynamic> json) {
    return ScadenzaVeicolo(
      id: json['id'] as String,
      veicoloId: json['veicolo_id'] as String,
      tipo: json['tipo'] as String,
      dataScadenza: DateTime.parse(json['data_scadenza'] as String),
      importoStimato: (json['importo_stimato'] as num?)?.toDouble(),
      completato: json['completato'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'veicolo_id': veicoloId,
        'tipo': tipo,
        'data_scadenza': dataScadenza.toIso8601String().split('T').first,
        if (importoStimato != null) 'importo_stimato': importoStimato,
        'completato': completato,
      };

  ScadenzaVeicolo copyWith({
    String? id,
    String? veicoloId,
    String? tipo,
    DateTime? dataScadenza,
    double? importoStimato,
    bool? completato,
    bool clearImporto = false,
  }) {
    return ScadenzaVeicolo(
      id: id ?? this.id,
      veicoloId: veicoloId ?? this.veicoloId,
      tipo: tipo ?? this.tipo,
      dataScadenza: dataScadenza ?? this.dataScadenza,
      importoStimato:
          clearImporto ? null : (importoStimato ?? this.importoStimato),
      completato: completato ?? this.completato,
    );
  }
}