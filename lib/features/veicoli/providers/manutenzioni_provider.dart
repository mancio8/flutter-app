import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/manutenzione.dart';
import '../../../core/models/scadenza_veicolo.dart';
import '../../../core/providers/supabase_provider.dart';
import '../repository/manutenzioni_repository.dart';

// ============================================================
// REPOSITORY
// ============================================================

final manutenzioniRepositoryProvider =
    Provider<ManutenzioniRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ManutenzioniRepository(supabase);
});

// ============================================================
// MANUTENZIONI
// ============================================================

class ManutenzioniNotifier extends AsyncNotifier<List<Manutenzione>> {
  @override
  Future<List<Manutenzione>> build() async {
    final repository = ref.watch(manutenzioniRepositoryProvider);
    return repository.getManutenzioni();
  }

  Future<void> addManutenzione(Manutenzione item) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.addManutenzione(item);
      final list = await repository.getManutenzioni();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateManutenzione(Manutenzione item) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    try {
      await repository.updateManutenzione(item);
      final list = await repository.getManutenzioni();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteManutenzione(String id) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    try {
      await repository.deleteManutenzione(id);
      final list = await repository.getManutenzioni();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final manutenzioniProvider =
    AsyncNotifierProvider<ManutenzioniNotifier, List<Manutenzione>>(() {
  return ManutenzioniNotifier();
});

// ============================================================
// SCADENZE
// ============================================================

class ScadenzeNotifier extends AsyncNotifier<List<ScadenzaVeicolo>> {
  @override
  Future<List<ScadenzaVeicolo>> build() async {
    final repository = ref.watch(manutenzioniRepositoryProvider);
    return repository.getScadenze();
  }

  Future<void> addScadenza(ScadenzaVeicolo item) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.addScadenza(item);
      final list = await repository.getScadenze();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateScadenza(ScadenzaVeicolo item) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    try {
      await repository.updateScadenza(item);
      final list = await repository.getScadenze();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCompletato(String id, bool val) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    try {
      await repository.toggleCompletatoScadenza(id, val);
      final list = await repository.getScadenze();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteScadenza(String id) async {
    final repository = ref.read(manutenzioniRepositoryProvider);
    try {
      await repository.deleteScadenza(id);
      final list = await repository.getScadenze();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final scadenzeProvider =
    AsyncNotifierProvider<ScadenzeNotifier, List<ScadenzaVeicolo>>(() {
  return ScadenzeNotifier();
});