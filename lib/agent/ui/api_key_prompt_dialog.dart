import 'package:flutter/material.dart';

import '../config/agent_config.dart';
import '../../core/ui.dart';

/// Dialog demandant à l'utilisateur de saisir sa clé API Groq.
/// Retourne la clé saisie ou null si annulé.
Future<String?> showApiKeyPromptDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _ApiKeyDialog(),
  );
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog();

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Veuillez saisir votre clé API.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await saveApiKey(key);
    if (mounted) Navigator.pop(context, key);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('🔑 Clé API Groq'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pour utiliser l\'agent IA, vous avez besoin d\'une clé API Groq gratuite.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Obtenez-la sur : console.groq.com/keys',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accent,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Clé API (gsk_...)',
              errorText: _error,
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
