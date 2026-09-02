import '../../../core/models/raccolta.dart';

class RaccoltaRepository {
  // Dati statici della raccolta differenziata
  static const Map<int, GiornoRaccolta> _raccolta = {
    1: GiornoRaccolta(
      giorno: 1,
      nome: 'Lunedì',
      rifiuti: [
        TipoRifiuto(icona: '🍃', titolo: 'Umido'),
        TipoRifiuto(icona: '🌿', titolo: 'Erba e Sfalcio', nota: 'max 3 buste da kg. 15'),
      ],
    ),
    2: GiornoRaccolta(
      giorno: 2,
      nome: 'Martedì',
      rifiuti: [
        TipoRifiuto(icona: '📦', titolo: 'Carta e Cartone', nota: 'Il cartone deve essere piegato'),
        TipoRifiuto(icona: '🛢️', titolo: 'Oli Esausti Vegetali'),
      ],
    ),
    3: GiornoRaccolta(
      giorno: 3,
      nome: 'Mercoledì',
      rifiuti: [
        TipoRifiuto(icona: '🧴', titolo: 'Plastica e Alluminio'),
      ],
    ),
    4: GiornoRaccolta(
      giorno: 4,
      nome: 'Giovedì',
      rifiuti: [
        TipoRifiuto(icona: '🍃', titolo: 'Umido'),
        TipoRifiuto(icona: '🍾', titolo: 'Vetro', nota: 'in buste separate'),
      ],
    ),
    5: GiornoRaccolta(
      giorno: 5,
      nome: 'Venerdì',
      rifiuti: [
        TipoRifiuto(icona: '🗑️', titolo: 'Indifferenziato'),
        TipoRifiuto(icona: '👶', titolo: 'Pannoloni'),
      ],
    ),
    6: GiornoRaccolta(
      giorno: 6,
      nome: 'Sabato',
      rifiuti: [
        TipoRifiuto(icona: '🍃', titolo: 'Umido'),
        TipoRifiuto(icona: '🌿', titolo: 'Erba e Sfalcio', nota: 'max 3 buste da kg. 15'),
      ],
    ),
    0: GiornoRaccolta(
      giorno: 0,
      nome: 'Domenica',
      rifiuti: [],
    ),
  };

  // Ottieni la raccolta per un giorno specifico
  Future<GiornoRaccolta> getRaccoltaPerGiorno(int giorno) async {
    // Simula un piccolo ritardo
    await Future.delayed(const Duration(milliseconds: 100));
    return _raccolta[giorno]!;
  }

  // Ottieni tutti i giorni
  Future<List<GiornoRaccolta>> getAllGiorni() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [1, 2, 3, 4, 5, 6, 0]
        .map((g) => _raccolta[g]!)
        .toList();
  }
}