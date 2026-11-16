import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/goal_repository.dart';
import '../../providers.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(goalRepositoryProvider);
    final summariesAsync = ref.watch(goalSummariesProvider);

    return summariesAsync.when(
      loading: () => const Center(child: SizedBox.shrink()),
      error: (err, _) => Center(child: Text('Erreur : $err')),
      data: (goals) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Mon plan',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            for (final s in goals) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.goal.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(s.progress * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.progress,
                        minHeight: 8,
                        backgroundColor: AppColors.track,
                        color: AppColors.accent,
                      ),
                    ),

                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(left: 8),
                      shape: const Border(), // enlève les bordures par défaut
                      collapsedShape: const Border(),
                      leading: const Icon(
                        Icons.checklist,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        '${s.doneTasks}/${s.totalTasks} tâches',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [_GoalTasksList(goalId: s.goal.id)],
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showAddTaskDialog(context, repo, s.goal.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter une tâche'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          tooltip: 'Modifier',
                          onPressed: () async {
                            final result = await showDialog<_GoalFormResult>(
                              context: context,
                              builder: (ctx) => _GoalFormDialog(
                                initial: _GoalFormResult(
                                  title: s.goal.title,
                                  description: s.goal.description,
                                  dueDate: s.goal.dueDate,
                                ),
                              ),
                            );
                            if (result != null) {
                              await repo.updateGoal(
                                id: s.goal.id,
                                title: result.title,
                                description: result.description,
                                dueDate: result.dueDate,
                              );
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'Supprimer',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer ?'),
                                content: Text('Supprimer "${s.goal.title}" ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await repo.deleteGoal(s.goal.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton(
              onPressed: () async {
                final result = await showDialog<_GoalFormResult>(
                  context: context,
                  builder: (ctx) => const _GoalFormDialog(),
                );
                if (result != null) {
                  await repo.addGoal(
                    title: result.title,
                    description: result.description,
                    dueDate: result.dueDate,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppColors.accent),
                foregroundColor: AppColors.accent,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('+ Nouvel objectif'),
            ),
          ],
        );
      },
    );
  }
}

class _GoalFormResult {
  const _GoalFormResult({required this.title, this.description, this.dueDate});
  final String title;
  final String? description;
  final DateTime? dueDate;
}

class _GoalFormDialog extends StatefulWidget {
  const _GoalFormDialog({this.initial});
  final _GoalFormResult? initial;

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial?.title ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _dueDate = widget.initial?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nouvel objectif' : 'Modifier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex : Apprendre Rust',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'Aucune échéance'
                        : 'Échéance : ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: const Text('Choisir'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              _GoalFormResult(
                title: title,
                description: _descCtrl.text.trim().isEmpty
                    ? null
                    : _descCtrl.text.trim(),
                dueDate: _dueDate,
              ),
            );
          },
          child: Text(widget.initial == null ? 'Créer' : 'Enregistrer'),
        ),
      ],
    );
  }
}

Future<void> _showAddTaskDialog(
  BuildContext context,
  GoalRepository repo,
  int goalId,
) async {
  final titleCtrl = TextEditingController();
  final minutesCtrl = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Titre de la tâche',
                hintText: 'Ex : Lire la doc des widgets',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée estimée (min, optionnel)',
                hintText: 'Ex : 30',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );

  // Nettoyage : libérer les contrôleurs
  final title = titleCtrl.text.trim();
  final minutes = int.tryParse(minutesCtrl.text.trim());

  if (result == true && title.isNotEmpty) {
    await repo.addTask(goalId: goalId, title: title, estimatedMinutes: minutes);
  }
}

class _GoalTasksList extends ConsumerWidget {
  const _GoalTasksList({required this.goalId});
  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(goalRepositoryProvider);
    final activeTask = ref.watch(activeTaskProvider);
    final tasksStream = repo.watchTasks(goalId);

    return StreamBuilder<List<Task>>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // rien tant qu'on n'a pas de data
        }

        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return const SizedBox.shrink(); // rien si aucune tâche
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            for (final t in tasks)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: t.isDone,
                onChanged: (v) async {
                  await repo.setTaskDone(t.id, done: v ?? false);
                },
                secondary: !t.isDone
                    ? IconButton(
                        icon: Icon(
                          activeTask?.id == t.id
                              ? Icons.timer
                              : Icons.timer_outlined,
                          color: activeTask?.id == t.id
                              ? AppColors.accent
                              : AppColors.muted,
                          size: 20,
                        ),
                        tooltip: activeTask?.id == t.id
                            ? 'Tâche active (cliquer pour retirer)'
                            : 'Définir pour le minuteur',
                        onPressed: () {
                          if (activeTask?.id == t.id) {
                            ref.read(activeTaskProvider.notifier).clear();
                          } else {
                            ref.read(activeTaskProvider.notifier).select(t);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tâche "${t.title}" définie pour le minuteur',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      )
                    : null,
                title: Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: t.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: t.isDone ? AppColors.muted : null,
                  ),
                ),
                subtitle: t.estimatedMinutes != null
                    ? Text(
                        '${t.estimatedMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      )
                    : null,
              ),
          ],
        );
      },
    );
  }
}
