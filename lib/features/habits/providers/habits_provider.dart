import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/habit.dart';
import '../repository/habits_repository.dart';

// Provider per il repository
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepository();
});

// Provider per il mese selezionato
final meseSelezionatoProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Notifier per gestire le abitudini
class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    final repository = ref.watch(habitsRepositoryProvider);
    return repository.getHabits();
  }

  Future<void> addHabit(Habit habit) async {
    final repository = ref.read(habitsRepositoryProvider);
    await repository.addHabit(habit);
    await _reload();
  }

  Future<void> updateHabit(Habit habit) async {
    final repository = ref.read(habitsRepositoryProvider);
    await repository.updateHabit(habit);
    await _reload();
  }

  Future<void> deleteHabit(String id) async {
    final repository = ref.read(habitsRepositoryProvider);
    await repository.deleteHabit(id);
    await _reload();
  }

  Future<void> toggleCompletamento(String id, DateTime data) async {
    final repository = ref.read(habitsRepositoryProvider);
    await repository.toggleCompletamento(id, data);
    await _reload();
  }

  Future<void> _reload() async {
    final repository = ref.read(habitsRepositoryProvider);
    final habits = await repository.getHabits();
    state = AsyncValue.data(habits);
  }

  // Aggiungi questi metodi alla classe HabitsNotifier

  // Importa habits
  Future<int> importHabits(List<Habit> habits) async {
    final repository = ref.read(habitsRepositoryProvider);

    try {
      final aggiunti = await repository.importHabits(habits);
      await _reload();
      return aggiunti;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return 0;
    }
  }

  // Sostituisci tutti gli habits
  Future<void> replaceAllHabits(List<Habit> habits) async {
    final repository = ref.read(habitsRepositoryProvider);

    try {
      await repository.replaceAllHabits(habits);
      await _reload();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Provider principale
final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

// Provider per le statistiche
final habitsStatsProvider = Provider<HabitsStats>((ref) {
  final habitsAsync = ref.watch(habitsProvider);

  return habitsAsync.when(
    data: (habits) {
      final oggi = DateTime.now();
      final completatiOggi = habits.where((h) => h.isCompletata(oggi)).length;
      final totale = habits.length;
      final percentuale = totale > 0 ? (completatiOggi / totale * 100) : 0.0;

      // Miglior streak
      int migliorStreak = 0;
      String? habitMigliore;
      for (final habit in habits) {
        final streak = habit.streakAttuale();
        if (streak > migliorStreak) {
          migliorStreak = streak;
          habitMigliore = habit.nome;
        }
      }

      return HabitsStats(
        completatiOggi: completatiOggi,
        totale: totale,
        percentuale: percentuale,
        migliorStreak: migliorStreak,
        habitMigliore: habitMigliore,
      );
    },
    loading: () => const HabitsStats(
      completatiOggi: 0,
      totale: 0,
      percentuale: 0,
      migliorStreak: 0,
    ),
    error: (_, __) => const HabitsStats(
      completatiOggi: 0,
      totale: 0,
      percentuale: 0,
      migliorStreak: 0,
    ),
  );
});

class HabitsStats {
  final int completatiOggi;
  final int totale;
  final double percentuale;
  final int migliorStreak;
  final String? habitMigliore;

  const HabitsStats({
    required this.completatiOggi,
    required this.totale,
    required this.percentuale,
    required this.migliorStreak,
    this.habitMigliore,
  });
}
