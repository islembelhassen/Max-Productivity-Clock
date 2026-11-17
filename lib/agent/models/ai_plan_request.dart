/// Requête envoyée à l'agent IA pour générer un plan.
class AiPlanRequest {
  const AiPlanRequest({required this.subject, this.deadline});

  /// Description de l'objectif par l'utilisateur.
  final String subject;

  /// Échéance optionnelle en langage naturel.
  final String? deadline;
}
