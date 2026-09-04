import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../habits/providers/habits_provider.dart';
import '../../../biblioteca/providers/biblioteca_provider.dart';
import '../../../rifornimenti/providers/rifornimenti_provider.dart';
import '../../../raccolta/providers/raccolta_provider.dart';
import '../../../note/providers/note_provider.dart';
import '../../../../core/models/nota.dart';

// --- Biblioteca ---
class BibliotecaSummary {
  final int totaleLibri;
  final String? ultimoLibroTitolo;
  final DateTime? ultimaLettura;

  const BibliotecaSummary({
    required this.totaleLibri,
    this.ultimoLibroTitolo,
    this.ultimaLettura,
  });
}

final bibliotecaSummaryProvider = Provider<BibliotecaSummary>((ref) {
  final libriAsync = ref.watch(bibliotecaProvider);

  return libriAsync.when(
    data: (libri) {
      if (libri.isEmpty) return const BibliotecaSummary(totaleLibri: 0);
      final ordinati = List.from(libri)
        ..sort((a, b) => b.dataLettura.compareTo(a.dataLettura));
      final ultimo = ordinati.first;
      return BibliotecaSummary(
        totaleLibri: libri.length,
        ultimoLibroTitolo: ultimo.titolo,
        ultimaLettura: ultimo.dataLettura,
      );
    },
    loading: () => const BibliotecaSummary(totaleLibri: 0),
    error: (_, __) => const BibliotecaSummary(totaleLibri: 0),
  );
});

// --- Rifornimenti ---
class RifornimentiSummary {
  final double totaleSpeso;
  final double prezzoMedio;
  final DateTime? ultimoRifornimento;

  const RifornimentiSummary({
    required this.totaleSpeso,
    required this.prezzoMedio,
    this.ultimoRifornimento,
  });
}

final rifornimentiSummaryProvider = Provider<RifornimentiSummary>((ref) {
  final stats = ref.watch(rifornimentiStatsProvider);
  final rifornimentiAsync = ref.watch(rifornimentiProvider);

  DateTime? ultimo;
  rifornimentiAsync.whenData((lista) {
    if (lista.isNotEmpty) {
      final ordinati = List.from(lista)..sort((a, b) => b.data.compareTo(a.data));
      ultimo = ordinati.first.data;
    }
  });

  return RifornimentiSummary(
    totaleSpeso: stats.totaleSpeso,
    prezzoMedio: stats.prezzoMedio,
    ultimoRifornimento: ultimo,
  );
});

// --- Raccolta differenziata ---
class RaccoltaSummary {
  final bool raccoltaOggi;
  final String? tipoOggi;
  final bool raccoltaDomani;          // NUOVO: c'è raccolta domani?
  final String? tipoDomani;           // NUOVO: cosa si raccoglie domani
  final String? prossimoGiornoNome;
  final int giorniAllaProssima;

  const RaccoltaSummary({
    required this.raccoltaOggi,
    this.tipoOggi,
    this.raccoltaDomani = false,      // NUOVO
    this.tipoDomani,                  // NUOVO
    this.prossimoGiornoNome,
    this.giorniAllaProssima = 0,
  });
}

final raccoltaSummaryProvider = Provider<RaccoltaSummary>((ref) {
  final raccoltaOggiAsync = ref.watch(raccoltaGiornoProvider);
  final tuttiGiorniAsync = ref.watch(tuttiGiorniProvider);
  final oggi = DateTime.now().weekday % 7;
  final domani = (oggi + 1) % 7;

  // Verifica se oggi c'è raccolta
  final oggiHaRaccolta = raccoltaOggiAsync.maybeWhen(
    data: (r) => r.rifiuti.isNotEmpty,
    orElse: () => false,
  );

  // Ottieni i tipi di rifiuti di oggi
  final tipoOggi = raccoltaOggiAsync.maybeWhen(
    data: (r) {
      if (r.rifiuti.isEmpty) return null;
      // Unisci i titoli dei rifiuti
      return r.rifiuti.map((r) => r.titolo).join(', ');
    },
    orElse: () => null,
  );

  // Trova la raccolta di domani
  final raccoltaDomani = tuttiGiorniAsync.maybeWhen(
    data: (giorni) {
      final match = giorni.where((g) => g.giorno == domani);
      if (match.isNotEmpty) {
        return match.first;
      }
      return null;
    },
    orElse: () => null,
  );

  // Verifica se domani c'è raccolta e cosa
  final domaniHaRaccolta = raccoltaDomani != null && raccoltaDomani.rifiuti.isNotEmpty;
  final tipoDomani = domaniHaRaccolta
      ? raccoltaDomani!.rifiuti.map((r) => r.titolo).join(', ')
      : null;

  // Se oggi c'è raccolta, mostra anche domani
  if (oggiHaRaccolta) {
    return RaccoltaSummary(
      raccoltaOggi: true,
      tipoOggi: tipoOggi,
      raccoltaDomani: domaniHaRaccolta,
      tipoDomani: tipoDomani,
    );
  }

  // Se oggi non c'è raccolta, cerca il prossimo giorno utile
  return tuttiGiorniAsync.maybeWhen(
    data: (giorni) {
      // Cerca il prossimo giorno con raccolta (partendo da domani)
      for (var offset = 1; offset <= 7; offset++) {
        final giornoCercato = (oggi + offset) % 7;
        final match = giorni.where((g) => g.giorno == giornoCercato);
        if (match.isNotEmpty && match.first.rifiuti.isNotEmpty) {
          return RaccoltaSummary(
            raccoltaOggi: false,
            raccoltaDomani: domaniHaRaccolta,
            tipoDomani: tipoDomani,
            prossimoGiornoNome: match.first.nome,
            giorniAllaProssima: offset,
          );
        }
      }
      return RaccoltaSummary(
        raccoltaOggi: false,
        raccoltaDomani: domaniHaRaccolta,
        tipoDomani: tipoDomani,
      );
    },
    orElse: () => RaccoltaSummary(
      raccoltaOggi: false,
      raccoltaDomani: domaniHaRaccolta,
      tipoDomani: tipoDomani,
    ),
  );
});

// --- Note ---
class NoteSummary {
  final int totaleNote;
  final int noteUrgenti;
  final int noteFissate;

  const NoteSummary({
    required this.totaleNote,
    required this.noteUrgenti,
    required this.noteFissate,
  });
}

final noteSummaryProvider = Provider<NoteSummary>((ref) {
  final noteAsync = ref.watch(noteProvider);

  return noteAsync.when(
    data: (note) {
      final urgenti = note.where((n) => n.categoria == CategoriaNota.urgente).length;
      final fissate = note.where((n) => n.fissata).length;
      return NoteSummary(
        totaleNote: note.length,
        noteUrgenti: urgenti,
        noteFissate: fissate,
      );
    },
    loading: () => const NoteSummary(totaleNote: 0, noteUrgenti: 0, noteFissate: 0),
    error: (_, __) => const NoteSummary(totaleNote: 0, noteUrgenti: 0, noteFissate: 0),
  );
});

// --- Habits ---
class HabitsSummary {
  final int completatiOggi;
  final int totale;
  final double percentuale;
  final int migliorStreak;

  const HabitsSummary({
    required this.completatiOggi,
    required this.totale,
    required this.percentuale,
    required this.migliorStreak,
  });
}

final habitsSummaryProvider = Provider<HabitsSummary>((ref) {
  final stats = ref.watch(habitsStatsProvider);
  
  return HabitsSummary(
    completatiOggi: stats.completatiOggi,
    totale: stats.totale,
    percentuale: stats.percentuale,
    migliorStreak: stats.migliorStreak,
  );
});