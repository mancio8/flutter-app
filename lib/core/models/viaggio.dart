class Viaggio {
  final String id;
  final String destinazione;
  final String? paese;
  final String? copertinaUrl;
  final String? note;
  final double? budgetStimato;
  final DateTime? dataVisita;
  final int? rating;
  final bool inWishlist;
  final DateTime? dataAggiuntaWishlist;

  const Viaggio({
    required this.id,
    required this.destinazione,
    this.paese,
    this.copertinaUrl,
    this.note,
    this.budgetStimato,
    this.dataVisita,
    this.rating,
    this.inWishlist = true,
    this.dataAggiuntaWishlist,
  });

  bool get isVisitato => dataVisita != null;
  bool get isInWishlist => inWishlist && !isVisitato;

  Viaggio copyWith({
    String? id,
    String? destinazione,
    String? paese,
    String? copertinaUrl,
    String? note,
    double? budgetStimato,
    DateTime? dataVisita,
    int? rating,
    bool? inWishlist,
    DateTime? dataAggiuntaWishlist,
    bool clearCopertina = false,
    bool clearNote = false,
    bool clearRating = false,
  }) {
    return Viaggio(
      id: id ?? this.id,
      destinazione: destinazione ?? this.destinazione,
      paese: paese ?? this.paese,
      copertinaUrl: clearCopertina ? null : (copertinaUrl ?? this.copertinaUrl),
      note: clearNote ? null : (note ?? this.note),
      budgetStimato: budgetStimato ?? this.budgetStimato,
      dataVisita: dataVisita ?? this.dataVisita,
      rating: clearRating ? null : (rating ?? this.rating),
      inWishlist: inWishlist ?? this.inWishlist,
      dataAggiuntaWishlist: dataAggiuntaWishlist ?? this.dataAggiuntaWishlist,
    );
  }

  factory Viaggio.fromJson(Map<String, dynamic> json) {
    return Viaggio(
      id: json['id'],
      destinazione: json['destinazione'] ?? '',
      paese: json['paese'],
      copertinaUrl: json['cover_url'],
      note: json['note'],
      budgetStimato: json['budget_stimato'] != null
          ? (json['budget_stimato'] as num).toDouble()
          : null,
      dataVisita: json['data_visita'] != null ? DateTime.parse(json['data_visita']) : null,
      rating: json['rating'],
      inWishlist: json['in_wishlist'] ?? true,
      dataAggiuntaWishlist: json['wishlist_date'] != null
          ? DateTime.parse(json['wishlist_date'])
          : null,
    );
  }
}