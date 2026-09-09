// File: lib/core/models/libro.dart
class Libro {
  final String id;
  final String titolo;
  final String autore;
  final DateTime? dataLettura;
  final String? copertinaUrl;
  final String? userId;
  final String? genere;
  final String? descrizione;
  final int? valutazione;
  final String? recensione;
  final bool inWishlist;
  final DateTime? dataAggiuntaWishlist;

  const Libro({
    required this.id,
    required this.titolo,
    required this.autore,
    this.dataLettura,
    this.copertinaUrl,
    this.userId,
    this.genere,
    this.descrizione,
    this.valutazione,
    this.recensione,
    this.inWishlist = false,
    this.dataAggiuntaWishlist,
  });

  bool get isLetto => dataLettura != null;
  bool get isInWishlist => inWishlist && !isLetto;

  Libro copyWith({
    String? id,
    String? titolo,
    String? autore,
    DateTime? dataLettura,
    String? copertinaUrl,
    String? userId,
    String? genere,
    String? descrizione,
    int? valutazione,
    String? recensione,
    bool? inWishlist,
    DateTime? dataAggiuntaWishlist,
    bool clearDataLettura = false,
    bool clearCopertina = false,
    bool clearGenere = false,
    bool clearDescrizione = false,
    bool clearValutazione = false,
    bool clearRecensione = false,
    bool clearDataAggiuntaWishlist = false,
  }) {
    return Libro(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      autore: autore ?? this.autore,
      dataLettura: clearDataLettura ? null : (dataLettura ?? this.dataLettura),
      copertinaUrl: clearCopertina ? null : (copertinaUrl ?? this.copertinaUrl),
      userId: userId ?? this.userId,
      genere: clearGenere ? null : (genere ?? this.genere),
      descrizione: clearDescrizione ? null : (descrizione ?? this.descrizione),
      valutazione: clearValutazione ? null : (valutazione ?? this.valutazione),
      recensione: clearRecensione ? null : (recensione ?? this.recensione),
      inWishlist: inWishlist ?? this.inWishlist,
      dataAggiuntaWishlist: clearDataAggiuntaWishlist 
          ? null 
          : (dataAggiuntaWishlist ?? this.dataAggiuntaWishlist),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': titolo,
      'author': autore,
      'read_date': dataLettura?.toIso8601String().split('T')[0],
      'cover_url': copertinaUrl ?? '',
      'user_id': userId,
      'genre': genere,
      'description': descrizione,
      'rating': valutazione,
      'review': recensione,
      'in_wishlist': inWishlist,
      'wishlist_date': dataAggiuntaWishlist?.toIso8601String(),
    };
  }

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      id: json['id'] ?? '',
      titolo: json['title'] ?? json['titolo'] ?? '',
      autore: json['author'] ?? json['autore'] ?? '',
      dataLettura: json['read_date'] != null 
          ? DateTime.parse(json['read_date']) 
          : null,
      copertinaUrl: json['cover_url'] ?? json['cover'] ?? json['copertinaUrl'],
      userId: json['user_id'] ?? json['userId'],
      genere: json['genre'] ?? json['genere'],
      descrizione: json['description'] ?? json['descrizione'],
      valutazione: json['rating'] ?? json['valutazione'],
      recensione: json['review'] ?? json['recensione'],
      inWishlist: json['in_wishlist'] ?? json['inWishlist'] ?? false,
      dataAggiuntaWishlist: json['wishlist_date'] != null
          ? DateTime.parse(json['wishlist_date'])
          : null,
    );
  }
}