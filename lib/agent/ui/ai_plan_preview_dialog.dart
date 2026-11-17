import 'package:flutter/material.dart';

import '../../core/ui.dart';
import '../../data/repositories/goal_repository.dart';
import '../models/ai_plan_result.dart';

/// Dialog de prévisualisation et d'édition du plan IA avant sauvegarde.
Future<void> showAiPlanPreviewDialog(
  BuildContext context, {
  required AiPlanResult plan,
  required GoalRepository repo,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AiPlanPreviewDialog(plan: plan, repo: repo),
  );
}

class _AiPlanPreviewDialog extends StatefulWidget {
  const _AiPlanPreviewDialog({required this.plan, required this.repo});
  final AiPlanResult plan;
  final GoalRepository repo;

  @override
  State<_AiPlanPreviewDialog> createState() => _AiPlanPreviewDialogState();
}

class _AiPlanPreviewDialogState extends State<_AiPlanPreviewDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late List<_EditableTask> _tasks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.plan.goalTitle);
    _descCtrl = TextEditingController(text: widget.plan.goalDescription);
    _tasks = widget.plan.tasks
        .map(
          (t) => _EditableTask(
            titleCtrl: TextEditingController(text: t.title),
            minutesCtrl:
                TextEditingController(text: t.estimatedMinutes.toString()),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final t in _tasks) {
      t.titleCtrl.dispose();
      t.minutesCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final goalId = await widget.repo.addGoal(
        title: title,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      for (final t in _tasks) {
        final taskTitle = t.titleCtrl.text.trim();
        if (taskTitle.isEmpty) continue;
        final minutes = int.tryParse(t.minutesCtrl.text.trim());
        await widget.repo.addTask(
          goalId: goalId,
          title: taskTitle,
          estimatedMinutes: minutes,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _addTask() {
    setState(() {
      _tasks.add(
        _EditableTask(
          titleCtrl: TextEditingController(),
          minutesCtrl: TextEditingController(text: '30'),
        ),
      );
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks[index].titleCtrl.dispose();
      _tasks[index].minutesCtrl.dispose();
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
            child: Row(
              children: [
                const Text(
                  '✨ Plan IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.line, height: 1),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Titre de l\'objectif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tâches',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _tasks.length; i++) ...[
                    _TaskRow(
                      task: _tasks[i],
                      onRemove: () => _removeTask(i),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter une tâche'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.line, height: 1),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTask {
  _EditableTask({required this.titleCtrl, required this.minutesCtrl});
  final TextEditingController titleCtrl;
  final TextEditingController minutesCtrl;
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onRemove});
  final _EditableTask task;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.drag_handle, color: AppColors.muted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: task.titleCtrl,
            decoration: const InputDecoration(
              hintText: 'Titre de la tâche',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: task.minutesCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'min',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              suffixText: 'min',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.remove_circle_outline,
            color: AppColors.muted,
            size: 18,
          ),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}
