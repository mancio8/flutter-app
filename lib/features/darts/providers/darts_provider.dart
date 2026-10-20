import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/darts_repository.dart';
import '../domain/darts_models.dart';

final dartsRepositoryProvider = Provider<DartsRepository>((ref) {
  return DartsRepository(ref.watch(supabaseProvider));
});

class DartsPlayersNotifier extends AsyncNotifier<List<DartsPlayer>> {
  @override
  Future<List<DartsPlayer>> build() {
    return ref.watch(dartsRepositoryProvider).getPlayers();
  }

  Future<void> add(String name, String avatar, String color) async {
    final repo = ref.read(dartsRepositoryProvider);
    await repo.createPlayer(name, avatar, color);
    state = AsyncData(await repo.getPlayers());
  }

  Future<void> remove(String id) async {
    final repo = ref.read(dartsRepositoryProvider);
    await repo.deletePlayer(id);
    state = AsyncData(await repo.getPlayers());
  }
}

final dartsPlayersProvider =
    AsyncNotifierProvider<DartsPlayersNotifier, List<DartsPlayer>>(
  DartsPlayersNotifier.new,
);