import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
/// Clé API Groq injectée via --dart-define=GROQ_API_KEY=...
/// ou lue depuis SharedPreferences (saisie par l'utilisateur).

final String _compiledGroqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';



const String groqModel = 'openai/gpt-oss-20b';
const String groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';

const String _prefKey = 'groq_api_key';

/// Retourne la clé API effective (compile-time > SharedPreferences).
Future<String> getEffectiveApiKey() async {

  if (_compiledGroqApiKey.isNotEmpty) return _compiledGroqApiKey;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_prefKey) ?? '';
}

/// Enregistre la clé API dans SharedPreferences.
Future<void> saveApiKey(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefKey, key);
}
