// Modello per un libro nella biblioteca
class Libro {
  final String id;
  final String titolo;
  final String autore;
  final DateTime dataLettura;
  final String? copertinaUrl;

  const Libro({
    required this.id,
    required this.titolo,
    required this.autore,
    required this.dataLettura,
    this.copertinaUrl,
  });

  // Copia con modifiche
  Libro copyWith({
    String? id,
    String? titolo,
    String? autore,
    DateTime? dataLettura,
    String? copertinaUrl,
    bool clearCopertina = false,
  }) {
    return Libro(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      autore: autore ?? this.autore,
      dataLettura: dataLettura ?? this.dataLettura,
      copertinaUrl: clearCopertina ? null : (copertinaUrl ?? this.copertinaUrl),
    );
  }

  // Converte in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': titolo,
      'author': autore,
      'read_date': dataLettura.toIso8601String().split('T')[0],
      'cover': copertinaUrl ?? '',
    };
  }

  // Crea da JSON (accetta sia 'title' che 'titolo')
  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: json['title'] ?? json['titolo'] ?? '',
      autore: json['author'] ?? json['autore'] ?? '',
      dataLettura: DateTime.parse(json['read_date'] ?? json['dataLettura']),
      copertinaUrl: json['cover'] ?? json['copertinaUrl'],
    );
  }
}