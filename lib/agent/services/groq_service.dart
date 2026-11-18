import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/agent_config.dart';
import '../models/ai_plan_result.dart';

/// Service d'appel à l'API Groq.
class GroqService {
  GroqService({String? apiKey}) : _apiKey = apiKey ?? '';

  final String _apiKey;

  Future<AiPlanResult> generatePlan(
    String systemPrompt,
    String userMessage, {
    String? apiKeyOverride,
  }) async {
    final key = (apiKeyOverride?.isNotEmpty ?? false)
        ? apiKeyOverride!
        : _apiKey;
    if (key.isEmpty) {
      throw Exception('Clé API Groq manquante. Veuillez la configurer.');
    }
    final response = await http.post(
      Uri.parse(groqBaseUrl),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API Groq (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    return AiPlanResult.fromJson(jsonDecode(content) as Map<String, dynamic>);
  }
}
