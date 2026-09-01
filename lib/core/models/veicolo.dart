// Modello che rappresenta un veicolo
class Veicolo {
  final String id;          // ID univoco (es. "auto-001")
  final String nome;        // Nome del veicolo (es. "Fiat Panda")
  final String? targa;      // Targa (opzionale)
  final String? tipo;       // Tipo: Auto, Moto, Camion, ecc.

  const Veicolo({
    required this.id,
    required this.nome,
    this.targa,
    this.tipo,
  });

  // Per salvare su JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'targa': targa,
      'tipo': tipo,
    };
  }

  // Per leggere da JSON
  factory Veicolo.fromJson(Map<String, dynamic> json) {
    return Veicolo(
      id: json['id'],
      nome: json['nome'],
      targa: json['targa'],
      tipo: json['tipo'],
    );
  }

  // Per mostrare il nome nella UI
  @override
  String toString() => nome;
}