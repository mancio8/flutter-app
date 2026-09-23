import '../utils/testo_utils.dart';

class SquadraCalcio {
  final int posizione;
  final String nome;
  final String? logoUrl;
  final int punti;
  final int partiteGiocate;
  final int vinte;
  final int pareggiate;
  final int perse;
  final int golFatti;
  final int golSubiti;
  final bool nonCompeting;
  final List<String> forma; // ['W', 'D', 'L', 'W', 'W']

  const SquadraCalcio({
    required this.posizione,
    required this.nome,
    this.logoUrl,
    this.punti = 0,
    this.partiteGiocate = 0,
    this.vinte = 0,
    this.pareggiate = 0,
    this.perse = 0,
    this.golFatti = 0,
    this.golSubiti = 0,
    this.nonCompeting = false,
    this.forma = const [],
  });

  int get differenzaReti => golFatti - golSubiti;

  factory SquadraCalcio.fromJson(Map<String, dynamic> json) {
    return SquadraCalcio(
      posizione: (json['position'] ?? json['posizione'] ?? 0) as int,
      nome: capitalizzaNomeSquadra(
        (json['team'] ?? json['nome'] ?? '') as String,
      ),
      logoUrl: (json['logo'] ?? json['logoUrl']) as String?,
      punti: (json['points'] ?? json['punti'] ?? 0) as int,
      partiteGiocate:
          (json['played'] ?? json['partiteGiocate'] ?? 0) as int,
      vinte: (json['wins'] ?? json['vinte'] ?? 0) as int,
      pareggiate: (json['draws'] ?? json['pareggiate'] ?? 0) as int,
      perse: (json['losses'] ?? json['perse'] ?? 0) as int,
      golFatti: (json['goalsFor'] ?? json['golFatti'] ?? 0) as int,
      golSubiti:
          (json['goalsAgainst'] ?? json['golSubiti'] ?? 0) as int,
      nonCompeting:
          (json['nonCompeting'] ?? json['non_competing'] ?? false) as bool,
      forma: (json['forma'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const [],
    );
  }

  SquadraCalcio copyWith({List<String>? forma}) {
    return SquadraCalcio(
      posizione: posizione,
      nome: nome,
      logoUrl: logoUrl,
      punti: punti,
      partiteGiocate: partiteGiocate,
      vinte: vinte,
      pareggiate: pareggiate,
      perse: perse,
      golFatti: golFatti,
      golSubiti: golSubiti,
      nonCompeting: nonCompeting,
      forma: forma ?? this.forma,
    );
  }
}