/// Une tâche proposée par l'agent IA.
class AiTaskItem {
  AiTaskItem({required this.title, required this.estimatedMinutes});

  final String title;
  final int estimatedMinutes;

  factory AiTaskItem.fromJson(Map<String, dynamic> json) => AiTaskItem(
    title: json['title'] as String,
    estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'estimated_minutes': estimatedMinutes,
  };
}

/// Plan complet généré par l'agent IA.
class AiPlanResult {
  AiPlanResult({
    required this.goalTitle,
    required this.goalDescription,
    required this.tasks,
  });

  final String goalTitle;
  final String goalDescription;
  final List<AiTaskItem> tasks;

  factory AiPlanResult.fromJson(Map<String, dynamic> json) => AiPlanResult(
    goalTitle: json['goal_title'] as String,
    goalDescription: json['goal_description'] as String,
    tasks: (json['tasks'] as List)
        .map((t) => AiTaskItem.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}
