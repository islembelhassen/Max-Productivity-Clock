import 'package:flutter/services.dart';

/// Épinglage d'écran (startLockTask) : empêche de quitter l'app.
class LockService {
  static const _channel = MethodChannel('focus60/lock');

  Future<bool> start() => _call('start');
  Future<bool> stop() => _call('stop');

  Future<bool> _call(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
