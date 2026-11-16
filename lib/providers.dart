import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/dnd_service.dart';
import 'core/platform/lock_service.dart';
import 'data/db/app_database.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/local/local_goal_repository.dart';
import 'data/repositories/local/local_session_repository.dart';
import 'data/repositories/session_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Plus tard : Supabase = remplacer ces deux lignes, et seulement elles.
final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => LocalGoalRepository(ref.watch(databaseProvider)),
);
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => LocalSessionRepository(ref.watch(databaseProvider)),
);

final dndServiceProvider = Provider<DndService>((ref) => DndService());
final lockServiceProvider = Provider<LockService>((ref) => LockService());

final goalSummariesProvider = StreamProvider<List<GoalSummary>>(
  (ref) => ref.watch(goalRepositoryProvider).watchSummaries(),
);

/// Minutes de focus du lundi au dimanche de la semaine en cours.
final weekMinutesProvider = StreamProvider<List<int>>((ref) {
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  return ref.watch(sessionRepositoryProvider).watchSince(monday).map((list) {
    final minutes = List<int>.filled(7, 0);
    for (final s in list) {
      minutes[s.startedAt.weekday - 1] += s.actualSeconds ~/ 60;
    }
    return minutes;
  });
});

/// Total des minutes de focus pour la semaine en cours.
final weekTotalMinutesProvider = Provider<int>((ref) {
  final weekAsync = ref.watch(weekMinutesProvider);
  return weekAsync.maybeWhen(
    data: (minutes) => minutes.fold(0, (a, b) => a + b),
    orElse: () => 0,
  );
});

/// Série de jours consécutifs avec au moins une session de focus.
final streakProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 60));
  return ref.watch(sessionRepositoryProvider).watchSince(start).map((sessions) {
    if (sessions.isEmpty) return 0;
    final daysWithSessions = <String>{};
    for (final s in sessions) {
      if (s.actualSeconds > 0) {
        final d = s.startedAt;
        daysWithSessions.add('${d.year}-${d.month}-${d.day}');
      }
    }
    var streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);
    final todayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
    if (!daysWithSessions.contains(todayKey)) {
      // Si aucune session aujourd'hui, vérifier si une session a eu lieu hier
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    while (daysWithSessions.contains(
      '${checkDate.year}-${checkDate.month}-${checkDate.day}',
    )) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  });
});

/// Temps de focus ventilé par objectif pour la semaine en cours.
final weekGoalTimeProvider = StreamProvider<List<GoalTimeStat>>((ref) {
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  return ref.watch(sessionRepositoryProvider).watchGoalTimeSince(monday);
});

/// Tâche actuellement sélectionnée pour le minuteur.
class ActiveTaskNotifier extends Notifier<Task?> {
  @override
  Task? build() => null;

  void select(Task? task) => state = task;
  void clear() => state = null;
}

final activeTaskProvider = NotifierProvider<ActiveTaskNotifier, Task?>(
  ActiveTaskNotifier.new,
);

/// Nom de l'objectif correspondant à la tâche active.
final activeGoalTitleProvider = Provider<String?>((ref) {
  final activeTask = ref.watch(activeTaskProvider);
  if (activeTask == null) return null;

  final summariesAsync = ref.watch(goalSummariesProvider);
  return summariesAsync.maybeWhen(
    data: (summaries) {
      for (final s in summaries) {
        if (s.goal.id == activeTask.goalId) {
          return s.goal.title;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});
