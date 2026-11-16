import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus60/app.dart';
import 'package:focus60/data/db/app_database.dart';
import 'package:focus60/providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const FocusApp(),
    );
  }

  testWidgets('affiche le minuteur au démarrage et bascule les contrôles', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Bloc 1 sur 5'), findsOneWidget);
    expect(find.text('50:00'), findsOneWidget);
    expect(find.text('Démarrer'), findsOneWidget);

    // Faire défiler jusqu'au bouton Démarrer si nécessaire et cliquer
    final demarrerBtn = find.text('Démarrer');
    await tester.ensureVisible(demarrerBtn);
    await tester.pumpAndSettle();
    await tester.tap(demarrerBtn);
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);

    // Clic sur Pause
    final pauseBtn = find.text('Pause');
    await tester.tap(pauseBtn);
    await tester.pump();
    expect(find.text('Démarrer'), findsOneWidget);

    // Clic sur Arrêter
    final arreterBtn = find.text('Arrêter');
    await tester.ensureVisible(arreterBtn);
    await tester.pumpAndSettle();
    await tester.tap(arreterBtn);
    await tester.pump();
    expect(find.text('50:00'), findsOneWidget);

    // Nettoyage de l'arbre
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('navigation entre les onglets Minuteur, Plan et Stats', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Onglet Plan
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Mon plan'), findsOneWidget);
    expect(find.text('+ Nouvel objectif'), findsOneWidget);

    // Onglet Stats
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Temps de focus'), findsOneWidget);
    expect(find.text('Série en cours'), findsOneWidget);

    // Retour Minuteur
    await tester.tap(find.text('Minuteur'));
    await tester.pumpAndSettle();
    expect(find.text('Bloc 1 sur 5'), findsOneWidget);

    // Nettoyage de l'arbre
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('création d\'un objectif depuis la page Plan', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Aller sur Plan
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    // Ouvrir le dialogue de création
    await tester.tap(find.text('+ Nouvel objectif'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvel objectif'), findsOneWidget);

    // Saisir un titre
    await tester.enterText(find.byType(TextField).first, 'Objectif Flutter');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Vérifier que l'objectif apparaît
    expect(find.text('Objectif Flutter'), findsOneWidget);
    expect(find.text('0/0 tâches'), findsOneWidget);

    // Nettoyage de l'arbre
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
