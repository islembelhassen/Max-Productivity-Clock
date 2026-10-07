import '../db/app_database.dart';

abstract class SessionRepository {
  Future<int> start({required int plannedMinutes, int? taskId});
  Future<void> finish(int id, {required int actualSeconds, required bool completed});
  Stream<List<FocusSession>> watchSince(DateTime from);
  Stream<int> watchTotalSecondsSince(DateTime from);
}