import 'package:flutter_test/flutter_test.dart';
import 'package:focus60/core/constants/focus_sequence.dart';

void main() {
  group('Focus Sequence', () {
    test('contient 5 blocs dégressifs de 50 à 10 minutes', () {
      expect(workBlocksMinutes, [50, 40, 30, 20, 10]);
      expect(workBlocksMinutes.length, 5);
      expect(workBlocksMinutes.reduce((a, b) => a + b), 150);
    });

    test('la durée de pause est de 10 minutes', () {
      expect(breakMinutes, 10);
    });
  });
}
