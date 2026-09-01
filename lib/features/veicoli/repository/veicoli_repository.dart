import '../../../core/models/veicolo.dart';

class VeicoliRepository {
  // Lista di veicoli di esempio
  final List<Veicolo> _veicoli = [
    Veicolo(id: 'auto-001', nome: 'Fiat Grande Punto', targa: 'DR594WM', tipo: 'Auto'),
    Veicolo(id: 'auto-002', nome: 'Suzuki Vitara', targa: 'BJ918GX', tipo: 'Auto'),
  ];

  Future<List<Veicolo>> getVeicoli() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_veicoli);
  }

  Future<void> addVeicolo(Veicolo veicolo) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _veicoli.add(veicolo);
  }

  Future<Veicolo?> getVeicoloById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (var veicolo in _veicoli) {
      if (veicolo.id == id) return veicolo;
    }
    return null;
  }
}