import 'package:drift/drift.dart';

import '../../db/app_database.dart';
import '../goal_repository.dart';

class LocalGoalRepository implements GoalRepository {
  LocalGoalRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<GoalSummary>> watchSummaries() {
    final total = _db.tasks.id.count();
    final done = _db.tasks.id.count(filter: _db.tasks.isDone.equals(true));
    final query =
        _db.select(_db.goals).join([
            leftOuterJoin(_db.tasks, _db.tasks.goalId.equalsExp(_db.goals.id)),
          ])
          ..addColumns([total, done])
          ..groupBy([_db.goals.id])
          ..orderBy([OrderingTerm.desc(_db.goals.createdAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => GoalSummary(
              r.readTable(_db.goals),
              r.read(total) ?? 0,
              r.read(done) ?? 0,
            ),
          )
          .toList(),
    );
  }

  @override
  Stream<List<Task>> watchTasks(int goalId) =>
      (_db.select(_db.tasks)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  @override
  Future<int> addGoal({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 1,
  }) => _db
      .into(_db.goals)
      .insert(
        GoalsCompanion.insert(
          title: title,
          description: Value(description),
          dueDate: Value(dueDate),
          priority: Value(priority),
        ),
      );

  @override
  Future<int> addTask({
    required int goalId,
    required String title,
    int? estimatedMinutes,
  }) => _db
      .into(_db.tasks)
      .insert(
        TasksCompanion.insert(
          goalId: goalId,
          title: title,
          estimatedMinutes: Value(estimatedMinutes),
        ),
      );

  @override
  Future<void> setTaskDone(int taskId, {required bool done}) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(isDone: Value(done)),
    );
  }

  @override
  Future<void> deleteGoal(int goalId) async {
    await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();
  }

  @override
  Future<void> decrementTaskTime(int taskId, int secondsToDeduct) async {
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).get();
    if (rows.isEmpty) return;
    final task = rows.first;
    // Utilise remainingMinutes si défini, sinon estimatedMinutes
    final currentMinutes = task.remainingMinutes ?? task.estimatedMinutes;
    if (currentMinutes == null) return;
    final newSeconds = currentMinutes * 60 - secondsToDeduct;
    final newMinutes = (newSeconds / 60).ceil().clamp(0, 9999);
    if (newMinutes <= 0) {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(isDone: Value(true), remainingMinutes: Value(0)),
      );
    } else {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(remainingMinutes: Value(newMinutes)),
      );
    }
  }

  @override
  Future<Task?> getNextTask(int goalId, int afterTaskId) async {
    final tasks =
        await (_db.select(_db.tasks)
              ..where(
                (t) =>
                    t.goalId.equals(goalId) &
                    t.isDone.equals(false) &
                    t.id.isBiggerThanValue(afterTaskId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(1))
            .get();
    return tasks.isEmpty ? null : tasks.first;
  }

  @override
  Future<void> updateGoal({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
  }) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        priority: priority != null ? Value(priority) : const Value.absent(),
      ),
    );
  }
}
