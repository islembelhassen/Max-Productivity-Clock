import 'config/agent_config.dart';
import 'models/ai_plan_request.dart';
import 'models/ai_plan_result.dart';
import 'services/groq_service.dart';

const _systemPrompt = '''
Tu es un assistant expert en productivité et en gestion du temps.
Ton rôle est de décomposer un objectif en tâches concrètes et actionnables.

Règles importantes:
- Chaque tâche doit avoir une durée estimée entre 10 et 90 minutes.
- Propose entre 3 et 8 tâches selon la complexité du sujet.
- Les durées sont libres, l'utilisateur pourra les ajuster.
- Réponds UNIQUEMENT en JSON valide avec ce format exact:
{
  "goal_title": "string",
  "goal_description": "string (1-2 phrases)",
  "tasks": [
    {"title": "string", "estimated_minutes": number},
    ...
  ]
}
''';

/// Orchestre la génération d'un plan IA pour un objectif donné.
class AgentPlanner {
  AgentPlanner({GroqService? service}) : _service = service ?? GroqService();

  final GroqService _service;

  Future<AiPlanResult> plan(AiPlanRequest request, {String? apiKey}) async {
    final effectiveKey = (apiKey?.isNotEmpty ?? false)
        ? apiKey!
        : await getEffectiveApiKey();

    final userMessage = StringBuffer('Crée un plan pour : ${request.subject}');
    if (request.deadline != null) {
      userMessage.write('\nÉchéance : ${request.deadline}');
    }

    return _service.generatePlan(
      _systemPrompt,
      userMessage.toString(),
      apiKeyOverride: effectiveKey,
    );
  }
}
