import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/focus_sequence.dart';
import '../../core/platform/dnd_service.dart';
import '../../core/platform/lock_service.dart';
import '../../core/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../providers.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  Timer? _ticker;
  int _block = 0;
  bool _onBreak = false;
  bool _running = false;
  bool _dnd = true;
  bool _lock = false;
  int _remaining = workBlocksMinutes[0] * 60;

  int? _currentSessionId;
  int _elapsedSecondsInBlock = 0;

  late DndService _dndService;
  late LockService _lockService;
  late SessionRepository _sessionRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dndService = ref.read(dndServiceProvider);
    _lockService = ref.read(lockServiceProvider);
    _sessionRepo = ref.read(sessionRepositoryProvider);
  }

  int get _total => (_onBreak ? breakMinutes : workBlocksMinutes[_block]) * 60;

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggle() async {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      if (!_onBreak) {
        if (_dnd) await _dndService.disable();
        if (_lock) await _lockService.stop();
        if (_currentSessionId != null) {
          await _sessionRepo.finish(
            _currentSessionId!,
            actualSeconds: _elapsedSecondsInBlock,
            completed: false,
          );
        }
      }
    } else {
      setState(() => _running = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      if (!_onBreak) {
        if (_dnd) await _dndService.enable();
        if (_lock) await _lockService.start();
        final activeTask = ref.read(activeTaskProvider);
        _currentSessionId = await _sessionRepo.start(
          plannedMinutes: workBlocksMinutes[_block],
          taskId: activeTask?.id,
        );
        _elapsedSecondsInBlock = 0;
      }
    }
  }

  Future<void> _tick() async {
    if (_remaining > 1) {
      if (!_onBreak) _elapsedSecondsInBlock++;
      setState(() => _remaining--);
      return;
    }

    if (!_onBreak) {
      _elapsedSecondsInBlock++;
      if (_currentSessionId != null) {
        await _sessionRepo.finish(
          _currentSessionId!,
          actualSeconds: _elapsedSecondsInBlock,
          completed: true,
        );
        _currentSessionId = null;
        _elapsedSecondsInBlock = 0;
      }
      if (_dnd) await _dndService.disable();
      if (_lock) await _lockService.stop();
    }

    setState(() {
      if (_onBreak) {
        _onBreak = false;
        _block = (_block + 1) % workBlocksMinutes.length;
        if (_running) {
          // Démarre le bloc suivant
          () async {
            if (_dnd) await _dndService.enable();
            if (_lock) await _lockService.start();
            final activeTask = ref.read(activeTaskProvider);
            _currentSessionId = await _sessionRepo.start(
              plannedMinutes: workBlocksMinutes[_block],
              taskId: activeTask?.id,
            );
            _elapsedSecondsInBlock = 0;
          }();
        }
      } else {
        _onBreak = true;
      }
      _remaining = _total;
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final sid = _currentSessionId;
    final elapsed = _elapsedSecondsInBlock;
    final wasBreak = _onBreak;
    _currentSessionId = null;
    _elapsedSecondsInBlock = 0;

    setState(() {
      _running = false;
      _onBreak = false;
      _block = 0;
      _remaining = workBlocksMinutes[0] * 60;
    });

    if (sid != null && !wasBreak) {
      await _sessionRepo.finish(sid, actualSeconds: elapsed, completed: false);
    }
    if (_dnd) await _dndService.disable();
    if (_lock) await _lockService.stop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_currentSessionId != null && !_onBreak) {
      _sessionRepo.finish(
        _currentSessionId!,
        actualSeconds: _elapsedSecondsInBlock,
        completed: false,
      );
    }
    if (_dnd) _dndService.disable();
    if (_lock) _lockService.stop();
    super.dispose();
  }

  Color _stepColor(int i) {
    if (i < _block) return AppColors.done;
    if (i == _block) return AppColors.accent;
    return AppColors.track;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _onBreak ? AppColors.amber : AppColors.accent;
    final activeTask = ref.watch(activeTaskProvider);
    final activeGoalTitle = ref.watch(activeGoalTitleProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bloc ${_block + 1} sur ${workBlocksMinutes.length}',
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              Text(
                _onBreak ? 'Pause en cours' : 'Pause de 10 min ensuite',
                style: const TextStyle(color: AppColors.amber, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTaskSelectionModal(context, ref),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeTask != null
                              ? 'Objectif · ${activeGoalTitle ?? 'Projet'}'
                              : 'Session libre',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeTask?.title ?? 'Aucune tâche sélectionnée (toucher pour choisir)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: activeTask != null
                                ? AppColors.text
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: _remaining / _total,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.track,
                    color: ringColor,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clock,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _onBreak
                            ? 'Pause de $breakMinutes min'
                            : 'Bloc de ${workBlocksMinutes[_block]} min',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // L'escalier 50 -> 10 : la signature visuelle de l'app.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < workBlocksMinutes.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          height: workBlocksMinutes[i] * 1.2,
                          decoration: BoxDecoration(
                            color: _stepColor(i),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${workBlocksMinutes[i]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: i == _block
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  label: 'Ne pas déranger',
                  on: _dnd,
                  onTap: () async {
                    final nextVal = !_dnd;
                    if (nextVal) {
                      final hasAccess = await ref
                          .read(dndServiceProvider)
                          .hasAccess();
                      if (!hasAccess && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Autorisation requise pour le mode Ne pas déranger',
                            ),
                            action: SnackBarAction(
                              label: 'Paramètres',
                              onPressed: () =>
                                  ref.read(dndServiceProvider).openSettings(),
                            ),
                          ),
                        );
                      }
                    }
                    setState(() => _dnd = nextVal);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleChip(
                  label: 'Verrouillage',
                  on: _lock,
                  onTap: () => setState(() => _lock = !_lock),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _toggle,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_running ? 'Pause' : 'Démarrer'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _stop,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.line),
                  foregroundColor: AppColors.text,
                ),
                child: const Text('Arrêter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showTaskSelectionModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final summaries = await ref
      .read(goalRepositoryProvider)
      .watchSummaries()
      .first;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Associer une tâche au focus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on, color: AppColors.accent),
                title: const Text('Session libre (aucun objectif)'),
                onTap: () {
                  ref.read(activeTaskProvider.notifier).clear();
                  Navigator.pop(ctx);
                },
              ),
              const Divider(color: AppColors.line),
              if (summaries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucun objectif pour le moment. Créez-en un dans l\'onglet "Plan".',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: summaries.length,
                    itemBuilder: (ctx, i) {
                      final summary = summaries[i];
                      return _GoalTaskPicker(
                        summary: summary,
                        onTaskSelected: (task) {
                          ref.read(activeTaskProvider.notifier).select(task);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _GoalTaskPicker extends ConsumerWidget {
  const _GoalTaskPicker({required this.summary, required this.onTaskSelected});

  final GoalSummary summary;
  final ValueChanged<Task> onTaskSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Task>>(
      stream: ref.watch(goalRepositoryProvider).watchTasks(summary.goal.id),
      builder: (context, snapshot) {
        final tasks = (snapshot.data ?? []).where((t) => !t.isDone).toList();
        if (tasks.isEmpty) return const SizedBox.shrink();

        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            summary.goal.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${tasks.length} tâche(s) restante(s)',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          children: [
            for (final t in tasks)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(
                  Icons.circle_outlined,
                  size: 14,
                  color: AppColors.accent,
                ),
                title: Text(t.title),
                trailing: t.estimatedMinutes != null
                    ? Text(
                        '${t.estimatedMinutes} min',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () => onTaskSelected(t),
              ),
          ],
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: on ? AppColors.accent : AppColors.text,
          side: BorderSide(color: on ? AppColors.accent : AppColors.line),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          '$label · ${on ? 'actif' : 'inactif'}',
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
