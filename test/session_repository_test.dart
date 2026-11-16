import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus60/data/db/app_database.dart';
import 'package:focus60/data/repositories/local/local_goal_repository.dart';
import 'package:focus60/data/repositories/local/local_session_repository.dart';
import 'package:focus60/data/repositories/session_repository.dart';

void main() {
  late AppDatabase db;
  late LocalSessionRepository sessionRepo;
  late LocalGoalRepository goalRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sessionRepo = LocalSessionRepository(db);
    goalRepo = LocalGoalRepository(db);
  });

  tearDown(() => db.close());

  group('LocalSessionRepository', () {
    test('une session terminée est comptée dans le total', () async {
      final id = await sessionRepo.start(plannedMinutes: 50);
      await sessionRepo.finish(id, actualSeconds: 3000, completed: true);

      final total = await sessionRepo
          .watchTotalSecondsSince(DateTime(2000))
          .first;
      expect(total, 3000);
    });

    test('enregistre une session interrompue', () async {
      final id = await sessionRepo.start(plannedMinutes: 40);
      await sessionRepo.finish(id, actualSeconds: 600, completed: false);

      final sessions = await sessionRepo.watchSince(DateTime(2000)).first;
      expect(sessions.length, 1);
      expect(sessions.first.actualSeconds, 600);
      expect(sessions.first.completed, isFalse);
    });

    test('agrège le temps de concentration par objectif', () async {
      final goal1 = await goalRepo.addGoal(title: 'Projet A');
      final goal2 = await goalRepo.addGoal(title: 'Projet B');
      final task1 = await goalRepo.addTask(goalId: goal1, title: 'Tâche A1');
      final task2 = await goalRepo.addTask(goalId: goal2, title: 'Tâche B1');

      final s1 = await sessionRepo.start(plannedMinutes: 50, taskId: task1);
      await sessionRepo.finish(s1, actualSeconds: 3000, completed: true);

      final s2 = await sessionRepo.start(plannedMinutes: 30, taskId: task2);
      await sessionRepo.finish(s2, actualSeconds: 1200, completed: true);

      final stats = await sessionRepo
          .watchGoalTimeSince(DateTime.now().subtract(const Duration(days: 1)))
          .first;

      expect(stats.length, 2);
      expect(stats.first, const GoalTimeStat('Projet A', 50));
      expect(stats[1], const GoalTimeStat('Projet B', 20));
    });
  });

  group('LocalGoalRepository', () {
    test('la progression d\'un objectif suit les tâches terminées', () async {
      final goalId = await goalRepo.addGoal(title: 'Mémoire');
      final t1 = await goalRepo.addTask(goalId: goalId, title: 'Plan');
      await goalRepo.addTask(goalId: goalId, title: 'Chapitre 1');
      await goalRepo.setTaskDone(t1, done: true);

      final summaries = await goalRepo.watchSummaries().first;
      expect(summaries.single.totalTasks, 2);
      expect(summaries.single.doneTasks, 1);
      expect(summaries.single.progress, 0.5);
    });

    test(
      'met à jour et supprime un objectif avec suppression en cascade',
      () async {
        final goalId = await goalRepo.addGoal(
          title: 'Initial Title',
          description: 'Initial Desc',
        );
        await goalRepo.addTask(goalId: goalId, title: 'Task to cascade');

        await goalRepo.updateGoal(
          id: goalId,
          title: 'Updated Title',
          description: 'Updated Desc',
        );

        var summaries = await goalRepo.watchSummaries().first;
        expect(summaries.single.goal.title, 'Updated Title');
        expect(summaries.single.goal.description, 'Updated Desc');

        await goalRepo.deleteGoal(goalId);
        summaries = await goalRepo.watchSummaries().first;
        expect(summaries, isEmpty);

        final tasks = await goalRepo.watchTasks(goalId).first;
        expect(tasks, isEmpty);
      },
    );
  });
}
