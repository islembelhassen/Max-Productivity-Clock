import 'package:drift/drift.dart';

import '../../db/app_database.dart';
import '../session_repository.dart';

class LocalSessionRepository implements SessionRepository {
  LocalSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> start({required int plannedMinutes, int? taskId}) => _db
      .into(_db.focusSessions)
      .insert(
        FocusSessionsCompanion.insert(
          plannedMinutes: plannedMinutes,
          startedAt: DateTime.now(),
          taskId: Value(taskId),
        ),
      );

  @override
  Future<void> finish(
    int id, {
    required int actualSeconds,
    required bool completed,
  }) async {
    await (_db.update(_db.focusSessions)..where((s) => s.id.equals(id))).write(
      FocusSessionsCompanion(
        actualSeconds: Value(actualSeconds),
        completed: Value(completed),
        endedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<List<FocusSession>> watchSince(DateTime from) =>
      (_db.select(_db.focusSessions)
            ..where((s) => s.startedAt.isBiggerOrEqualValue(from))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .watch();

  @override
  Stream<int> watchTotalSecondsSince(DateTime from) {
    final sum = _db.focusSessions.actualSeconds.sum();
    final query = _db.selectOnly(_db.focusSessions)
      ..addColumns([sum])
      ..where(_db.focusSessions.startedAt.isBiggerOrEqualValue(from));
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  @override
  Stream<List<GoalTimeStat>> watchGoalTimeSince(DateTime from) {
    final totalSeconds = _db.focusSessions.actualSeconds.sum();
    final query =
        _db.select(_db.goals).join([
            innerJoin(_db.tasks, _db.tasks.goalId.equalsExp(_db.goals.id)),
            innerJoin(
              _db.focusSessions,
              _db.focusSessions.taskId.equalsExp(_db.tasks.id),
            ),
          ])
          ..addColumns([totalSeconds])
          ..where(_db.focusSessions.startedAt.isBiggerOrEqualValue(from))
          ..groupBy([_db.goals.id])
          ..orderBy([OrderingTerm.desc(totalSeconds)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (r) => GoalTimeStat(
              r.readTable(_db.goals).title,
              (r.read(totalSeconds) ?? 0) ~/ 60,
            ),
          )
          .toList(),
    );
  }
}
