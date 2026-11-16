import '../db/app_database.dart';

class GoalSummary {
  const GoalSummary(this.goal, this.totalTasks, this.doneTasks);

  final Goal goal;
  final int totalTasks;
  final int doneTasks;

  double get progress => totalTasks == 0 ? 0 : doneTasks / totalTasks;
}

abstract class GoalRepository {
  Stream<List<GoalSummary>> watchSummaries();
  Stream<List<Task>> watchTasks(int goalId);
  Future<int> addGoal({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 1,
  });
  Future<int> addTask({
    required int goalId,
    required String title,
    int? estimatedMinutes,
  });
  Future<void> setTaskDone(int taskId, {required bool done});
  Future<void> deleteGoal(int goalId);

  Future<void> updateGoal({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
  });
}
