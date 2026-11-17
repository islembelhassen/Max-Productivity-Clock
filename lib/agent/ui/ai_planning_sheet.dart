import 'package:flutter/material.dart';

import '../../core/ui.dart';
import '../agent_planner.dart';
import '../models/ai_plan_request.dart';
import '../models/ai_plan_result.dart';

/// Bottom sheet permettant à l'utilisateur de décrire son objectif
/// et de lancer la génération du plan IA.
///
/// Retourne un [AiPlanResult] ou null si annulé.
Future<AiPlanResult?> showAiPlanningSheet(
  BuildContext context, {
  required String apiKey,
}) {
  return showModalBottomSheet<AiPlanResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AiPlanningSheet(apiKey: apiKey),
  );
}

class _AiPlanningSheet extends StatefulWidget {
  const _AiPlanningSheet({required this.apiKey});
  final String apiKey;

  @override
  State<_AiPlanningSheet> createState() => _AiPlanningSheetState();
}

class _AiPlanningSheetState extends State<_AiPlanningSheet> {
  final _subjectCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = 'Décrivez votre objectif.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final planner = AgentPlanner();
      final result = await planner.plan(
        AiPlanRequest(
          subject: subject,
          deadline: _deadlineCtrl.text.trim().isEmpty
              ? null
              : _deadlineCtrl.text.trim(),
        ),
        apiKey: widget.apiKey,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Planifier avec l\'IA',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Décrivez votre objectif, l\'IA créera un plan de tâches.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectCtrl,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Mon objectif *',
              hintText:
                  'Ex : Apprendre les bases de Flutter en 1 semaine',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deadlineCtrl,
            decoration: const InputDecoration(
              labelText: 'Échéance (optionnel)',
              hintText: 'Ex : dans 2 semaines, avant vendredi',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Génération en cours...' : 'Générer le plan'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
