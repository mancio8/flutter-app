import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/viaggio.dart';
import '../../../core/providers/supabase_provider.dart';
import '../repository/viaggi_repository.dart';

final viaggiRepositoryProvider = Provider<ViaggiRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ViaggiRepository(supabase);
});

final wishlistViaggiProvider = FutureProvider<List<Viaggio>>((ref) async {
  final repository = ref.watch(viaggiRepositoryProvider);
  return repository.getWishlist();
});

class ViaggiNotifier extends AsyncNotifier<List<Viaggio>> {
  @override
  Future<List<Viaggio>> build() async {
    final repository = ref.watch(viaggiRepositoryProvider);
    return repository.getViaggiFatti();
  }

  Future<void> addViaggioFatto(Viaggio viaggio) async {
    final repository = ref.read(viaggiRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.addViaggioFatto(viaggio);
      await _reload();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateViaggio(Viaggio viaggio) async {
    final repository = ref.read(viaggiRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.updateViaggio(viaggio);
      await _reload();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteViaggio(String id) async {
    final repository = ref.read(viaggiRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.deleteViaggio(id);
      await _reload();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToWishlist(Viaggio viaggio) async {
    final repository = ref.read(viaggiRepositoryProvider);
    await repository.addToWishlist(viaggio);
    ref.invalidate(wishlistViaggiProvider);
  }

  Future<void> moveToVisitato(Viaggio viaggio, DateTime dataVisita, {int? rating}) async {
    final repository = ref.read(viaggiRepositoryProvider);
    await repository.moveToVisitato(viaggio, dataVisita, rating: rating);
    await _reload();
    ref.invalidate(wishlistViaggiProvider);
  }

  Future<void> removeFromWishlist(String id) async {
    final repository = ref.read(viaggiRepositoryProvider);
    await repository.removeFromWishlist(id);
    ref.invalidate(wishlistViaggiProvider);
  }

  Future<void> refreshViaggi() async {
    await _reload();
  }

  Future<void> _reload() async {
    final repository = ref.read(viaggiRepositoryProvider);
    state = AsyncValue.data(await repository.getViaggiFatti());
  }
}

final viaggiProvider = AsyncNotifierProvider<ViaggiNotifier, List<Viaggio>>(() {
  return ViaggiNotifier();
});