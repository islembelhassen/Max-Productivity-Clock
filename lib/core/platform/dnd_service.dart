import 'package:flutter/services.dart';

/// Ne pas déranger (Android). Les alarmes restent autorisées.
class DndService {
  static const _channel = MethodChannel('focus60/dnd');

  Future<bool> hasAccess() => _call('hasAccess');
  Future<bool> enable() => _call('enable');
  Future<bool> disable() => _call('disable');

  /// Ouvre l'écran Android « Accès Ne pas déranger ».
  Future<void> openSettings() => _call('openSettings');

  Future<bool> _call(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false; // tests ou plateforme sans implémentation
    }
  }
}
