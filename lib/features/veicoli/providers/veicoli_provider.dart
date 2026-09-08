// File: lib/features/veicoli/providers/veicoli_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/veicolo.dart';
import '../repository/veicoli_repository.dart';
import '../../../core/providers/supabase_provider.dart';

// Provider per il repository
final veicoliRepositoryProvider = Provider<VeicoliRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VeicoliRepository(supabase);
});

// Notifier per gestire i veicoli
class VeicoliNotifier extends AsyncNotifier<List<Veicolo>> {
  @override
  Future<List<Veicolo>> build() async {
    final repository = ref.watch(veicoliRepositoryProvider);
    return repository.getVeicoli();
  }

  Future<void> addVeicolo(Veicolo veicolo) async {
    final repository = ref.read(veicoliRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.addVeicolo(veicolo);
      await _reload();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateVeicolo(Veicolo veicolo) async {
    final repository = ref.read(veicoliRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.updateVeicolo(veicolo);
      await _reload();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteVeicolo(String id) async {
    final repository = ref.read(veicoliRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.deleteVeicolo(id);
      await _reload();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _reload() async {
    final repository = ref.read(veicoliRepositoryProvider);
    final veicoli = await repository.getVeicoli();
    state = AsyncValue.data(veicoli);
  }
}

// Provider per la lista dei veicoli
final veicoliProvider = AsyncNotifierProvider<VeicoliNotifier, List<Veicolo>>(() {
  return VeicoliNotifier();
});