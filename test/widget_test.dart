//import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus60/app.dart';

void main() {
  testWidgets('L\'app démarre et affiche le titre', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FocusApp()));
    expect(find.text('Focus60'), findsOneWidget);
  });
}