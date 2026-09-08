enum CategoriaEsercizio {
  petto,
  schiena,
  gambe,
  spalle,
  braccia,
  addominali,
  cardio,
  altro,
}

extension CategoriaEsercizioExtension on CategoriaEsercizio {
  String get label {
    switch (this) {
      case CategoriaEsercizio.petto:
        return 'Petto';
      case CategoriaEsercizio.schiena:
        return 'Schiena';
      case CategoriaEsercizio.gambe:
        return 'Gambe';
      case CategoriaEsercizio.spalle:
        return 'Spalle';
      case CategoriaEsercizio.braccia:
        return 'Braccia';
      case CategoriaEsercizio.addominali:
        return 'Addominali';
      case CategoriaEsercizio.cardio:
        return 'Cardio';
      case CategoriaEsercizio.altro:
        return 'Altro';
    }
  }
}

class Esercizio {
  final String id;
  final String nome;
  final CategoriaEsercizio categoria;

  const Esercizio({
    required this.id,
    required this.nome,
    required this.categoria,
  });

  Esercizio copyWith({String? id, String? nome, CategoriaEsercizio? categoria}) {
    return Esercizio(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'categoria': categoria.name,
      };

  factory Esercizio.fromJson(Map<String, dynamic> json) {
    return Esercizio(
      id: json['id'],
      nome: json['nome'] ?? '',
      categoria: CategoriaEsercizio.values.firstWhere(
        (c) => c.name == json['categoria'],
        orElse: () => CategoriaEsercizio.altro,
      ),
    );
  }
}

// Elenco base precaricato al primo avvio
const List<Esercizio> eserciziPredefiniti = [
  Esercizio(id: 'panca-piana', nome: 'Panca piana', categoria: CategoriaEsercizio.petto),
  Esercizio(id: 'squat', nome: 'Squat', categoria: CategoriaEsercizio.gambe),
  Esercizio(id: 'stacco', nome: 'Stacco da terra', categoria: CategoriaEsercizio.schiena),
  Esercizio(id: 'trazioni', nome: 'Trazioni', categoria: CategoriaEsercizio.schiena),
  Esercizio(id: 'military-press', nome: 'Military press', categoria: CategoriaEsercizio.spalle),
  Esercizio(id: 'curl-bicipiti', nome: 'Curl bicipiti', categoria: CategoriaEsercizio.braccia),
];