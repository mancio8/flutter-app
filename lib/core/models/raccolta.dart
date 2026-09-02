// Modello per un tipo di rifiuto
class TipoRifiuto {
  final String icona;
  final String titolo;
  final String? nota;

  const TipoRifiuto({
    required this.icona,
    required this.titolo,
    this.nota,
  });

  Map<String, dynamic> toJson() {
    return {
      'icona': icona,
      'titolo': titolo,
      'nota': nota,
    };
  }

  factory TipoRifiuto.fromJson(Map<String, dynamic> json) {
    return TipoRifiuto(
      icona: json['icona'],
      titolo: json['titolo'],
      nota: json['nota'],
    );
  }
}

// Modello per un giorno della settimana
class GiornoRaccolta {
  final int giorno; // 1=Lunedì, 2=Martedì, ... 0=Domenica
  final String nome;
  final List<TipoRifiuto> rifiuti;

  const GiornoRaccolta({
    required this.giorno,
    required this.nome,
    required this.rifiuti,
  });
}