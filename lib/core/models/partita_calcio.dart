import '../utils/testo_utils.dart';

enum FasePartita { andata, ritorno }

class PartitaCalcio {
  final FasePartita fase;
  final int giornata;
  final int? id;
  final DateTime? data;
  final String? ora;
  final String squadraCasa;
  final String squadraTrasferta;
  final int? golCasa;
  final int? golTrasferta;
  final String? campo;
  final String? indirizzo;
  final String? logoCasa;
  final String? logoTrasferta;
  final bool giocata;
  final bool rinviata;
  final String? esito;
  final String? winner;
  final String? liveUrl;
  final bool isLive;

  const PartitaCalcio({
    required this.fase,
    required this.giornata,
    this.id,
    this.data,
    this.ora,
    required this.squadraCasa,
    required this.squadraTrasferta,
    this.golCasa,
    this.golTrasferta,
    this.campo,
    this.indirizzo,
    this.logoCasa,
    this.logoTrasferta,
    this.giocata = false,
    this.rinviata = false,
    this.esito,
    this.winner,
    this.liveUrl,
    this.isLive = false,
  });

  factory PartitaCalcio.fromJson(Map<String, dynamic> json) {
    return PartitaCalcio(
      fase: (json['fase'] == 'ritorno')
          ? FasePartita.ritorno
          : FasePartita.andata,
      giornata: (json['giornata'] ?? 0) as int,
      id: json['id'] as int?,
      data: json['data'] != null
          ? DateTime.tryParse(json['data'] as String)
          : null,
      ora: json['ora'] as String?,
      squadraCasa: capitalizzaNomeSquadra(
        (json['casa'] ?? '') as String,
      ),
      squadraTrasferta: capitalizzaNomeSquadra(
        (json['trasferta'] ?? '') as String,
      ),
      golCasa: json['gol_casa'] as int?,
      golTrasferta: json['gol_trasferta'] as int?,
      campo: json['campo'] as String?,
      indirizzo: json['indirizzo'] as String?,
      logoCasa: json['logo_casa'] as String?,
      logoTrasferta: json['logo_trasferta'] as String?,
      giocata: (json['giocata'] ?? false) as bool,
      rinviata: (json['rinviata'] ?? false) as bool,
      esito: (json['esito'] as String?)?.isEmpty ?? true
          ? null
          : json['esito'] as String?,
      winner: json['winner'] as String?,
      liveUrl: json['live_url'] as String?,
      isLive: (json['is_live'] ?? false) as bool,
    );
  }
}