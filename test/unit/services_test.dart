import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus60/core/platform/dnd_service.dart';
import 'package:focus60/core/platform/lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DndService', () {
    const channel = MethodChannel('focus60/dnd');
    final service = DndService();

    test('appelle les méthodes MethodChannel correspondantes', () async {
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            calls.add(methodCall.method);
            switch (methodCall.method) {
              case 'hasAccess':
                return true;
              case 'enable':
                return true;
              case 'disable':
                return true;
              case 'openSettings':
                return true;
              default:
                return false;
            }
          });

      expect(await service.hasAccess(), isTrue);
      expect(await service.enable(), isTrue);
      expect(await service.disable(), isTrue);
      await service.openSettings();

      expect(calls, ['hasAccess', 'enable', 'disable', 'openSettings']);
    });

    test('gère les erreurs et retours null en toute sécurité', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Failed');
          });

      expect(await service.hasAccess(), isFalse);
      expect(await service.enable(), isFalse);
      expect(await service.disable(), isFalse);
    });
  });

  group('LockService', () {
    const channel = MethodChannel('focus60/lock');
    final service = LockService();

    test('appelle start et stop sur le canal', () async {
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            calls.add(methodCall.method);
            return true;
          });

      expect(await service.start(), isTrue);
      expect(await service.stop(), isTrue);
      expect(calls, ['start', 'stop']);
    });

    test('gère les PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERR', message: 'Not supported');
          });

      expect(await service.start(), isFalse);
      expect(await service.stop(), isFalse);
    });
  });
}
