import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/raccolta.dart';
import '../repository/raccolta_repository.dart';

// Provider per il repository
final raccoltaRepositoryProvider = Provider<RaccoltaRepository>((ref) {
  return RaccoltaRepository();
});

// Provider per il giorno selezionato
final giornoSelezionatoProvider = StateProvider<int>((ref) {
  return DateTime.now().weekday % 7; // 1=Lunedì, ... 6=Sabato, 0=Domenica
});

// Provider per la raccolta del giorno selezionato
final raccoltaGiornoProvider = FutureProvider<GiornoRaccolta>((ref) async {
  final repository = ref.watch(raccoltaRepositoryProvider);
  final giorno = ref.watch(giornoSelezionatoProvider);
  return repository.getRaccoltaPerGiorno(giorno);
});

// Provider per tutti i giorni
final tuttiGiorniProvider = FutureProvider<List<GiornoRaccolta>>((ref) async {
  final repository = ref.watch(raccoltaRepositoryProvider);
  return repository.getAllGiorni();
});