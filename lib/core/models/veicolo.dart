class Veicolo {
  final String id;
  final String nome;
  final String? targa;
  final String? tipo;
  final String? userId; // NUOVO: per associare il veicolo all'utente

  const Veicolo({
    required this.id,
    required this.nome,
    this.targa,
    this.tipo,
    this.userId,
  });

  Veicolo copyWith({
    String? id,
    String? nome,
    String? targa,
    String? tipo,
    String? userId,
    bool clearTarga = false,
    bool clearTipo = false,
  }) {
    return Veicolo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      targa: clearTarga ? null : (targa ?? this.targa),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'targa': targa,
      'tipo': tipo,
      'user_id': userId, // NOTA: snake_case per Supabase
    };
  }

  factory Veicolo.fromJson(Map<String, dynamic> json) {
    return Veicolo(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      targa: json['targa'],
      tipo: json['tipo'],
      userId: json['user_id'] ?? json['userId'],
    );
  }

  @override
  String toString() => nome;
}