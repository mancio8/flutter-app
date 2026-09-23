class CampionatoConfig {
  final String id;
  final String jsonUrl;
  final String? squadraPreferita;
  final DateTime? updatedAt;

  const CampionatoConfig({
    required this.id,
    required this.jsonUrl,
    this.squadraPreferita,
    this.updatedAt,
  });

  static const String defaultJsonUrl =
      'https://vincenzomancinelli.it/campionato_2026_EC_A.json';

  factory CampionatoConfig.fromJson(Map<String, dynamic> json) {
    return CampionatoConfig(
      id: json['id'] as String,
      jsonUrl: json['json_url'] as String? ?? defaultJsonUrl,
      squadraPreferita: json['squadra_preferita'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'json_url': jsonUrl,
        'squadra_preferita': squadraPreferita,
      };

  CampionatoConfig copyWith({
    String? id,
    String? jsonUrl,
    String? squadraPreferita,
    bool clearSquadra = false,
    DateTime? updatedAt,
  }) {
    return CampionatoConfig(
      id: id ?? this.id,
      jsonUrl: jsonUrl ?? this.jsonUrl,
      squadraPreferita:
          clearSquadra ? null : (squadraPreferita ?? this.squadraPreferita),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}