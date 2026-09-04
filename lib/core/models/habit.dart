// Modello per un'abitudine
class Habit {
  final String id;
  final String nome;
  final String? descrizione;
  final String icona;          // Emoji o icona
  final String colore;         // Colore in esadecimale
  final DateTime dataCreazione;
  final List<DateTime> completamenti;  // Date in cui è stata completata
  final int obiettivoMensile;  // Quante volte al mese

  const Habit({
    required this.id,
    required this.nome,
    this.descrizione,
    required this.icona,
    required this.colore,
    required this.dataCreazione,
    this.completamenti = const [],
    this.obiettivoMensile = 30,
  });

  // Copia con modifiche
  Habit copyWith({
    String? id,
    String? nome,
    String? descrizione,
    String? icona,
    String? colore,
    DateTime? dataCreazione,
    List<DateTime>? completamenti,
    int? obiettivoMensile,
  }) {
    return Habit(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      icona: icona ?? this.icona,
      colore: colore ?? this.colore,
      dataCreazione: dataCreazione ?? this.dataCreazione,
      completamenti: completamenti ?? this.completamenti,
      obiettivoMensile: obiettivoMensile ?? this.obiettivoMensile,
    );
  }

  // Verifica se completata in una data
  bool isCompletata(DateTime data) {
    return completamenti.any((d) => 
      d.year == data.year && 
      d.month == data.month && 
      d.day == data.day
    );
  }

  // Aggiungi completamento
  Habit aggiungiCompletamento(DateTime data) {
    if (isCompletata(data)) return this;
    final nuovi = List<DateTime>.from(completamenti)..add(data);
    return copyWith(completamenti: nuovi);
  }

  // Rimuovi completamento
  Habit rimuoviCompletamento(DateTime data) {
    final nuovi = completamenti.where((d) => 
      !(d.year == data.year && 
        d.month == data.month && 
        d.day == data.day)
    ).toList();
    return copyWith(completamenti: nuovi);
  }

  // Completamenti nel mese corrente
  int completamentiMese(DateTime mese) {
    return completamenti.where((d) => 
      d.year == mese.year && d.month == mese.month
    ).length;
  }

  // Streak attuale (giorni consecutivi)
  int streakAttuale() {
    if (completamenti.isEmpty) return 0;
    
    final ordinati = List<DateTime>.from(completamenti)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime? ultimaData;
    
    for (final data in ordinati) {
      if (ultimaData == null) {
        // Primo giorno
        final oggi = DateTime.now();
        final ieri = DateTime(oggi.year, oggi.month, oggi.day - 1);
        final dataNormalizzata = DateTime(data.year, data.month, data.day);
        
        if (dataNormalizzata == DateTime(oggi.year, oggi.month, oggi.day) ||
            dataNormalizzata == ieri) {
          streak = 1;
          ultimaData = dataNormalizzata;
        } else {
          break;
        }
      } else {
        final differenza = ultimaData!.difference(data).inDays;
        if (differenza == 1) {
          streak++;
          ultimaData = data;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  // Converte in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descrizione': descrizione,
      'icona': icona,
      'colore': colore,
      'dataCreazione': dataCreazione.toIso8601String(),
      'completamenti': completamenti.map((d) => d.toIso8601String()).toList(),
      'obiettivoMensile': obiettivoMensile,
    };
  }

  // Crea da JSON
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      nome: json['nome'],
      descrizione: json['descrizione'],
      icona: json['icona'],
      colore: json['colore'],
      dataCreazione: DateTime.parse(json['dataCreazione']),
      completamenti: (json['completamenti'] as List<dynamic>? ?? [])
          .map((d) => DateTime.parse(d as String))
          .toList(),
      obiettivoMensile: json['obiettivoMensile'] ?? 30,
    );
  }
}