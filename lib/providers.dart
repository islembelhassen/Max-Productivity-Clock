import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/db/app_database.dart';
import 'data/repositories/local/local_session_repository.dart';
import 'data/repositories/session_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Plus tard : remplace par SupabaseSessionRepository ici, et seulement ici.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => LocalSessionRepository(ref.watch(databaseProvider)),
);