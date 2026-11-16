import '../db/app_database.dart';

class GoalTimeStat {
  const GoalTimeStat(this.title, this.totalMinutes);

  final String title;
  final int totalMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTimeStat &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          totalMinutes == other.totalMinutes;

  @override
  int get hashCode => title.hashCode ^ totalMinutes.hashCode;
}

abstract class SessionRepository {
  Future<int> start({required int plannedMinutes, int? taskId});
  Future<void> finish(
    int id, {
    required int actualSeconds,
    required bool completed,
  });
  Stream<List<FocusSession>> watchSince(DateTime from);
  Stream<int> watchTotalSecondsSince(DateTime from);
  Stream<List<GoalTimeStat>> watchGoalTimeSince(DateTime from);
}
