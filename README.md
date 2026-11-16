# Focus60

Application de Deep Work et de productivité basée sur des cycles d'attention dégressifs (50 → 10 minutes) pour optimiser la concentration et éliminer les distractions.

---

## ⏱️ Le Concept (50 → 10)

Une session de travail complète s'organise en 5 blocs dégressifs intercalés de pauses de récupération :

- **Bloc 1** : 50 min *(Focus maximal)* + 10 min de pause
- **Bloc 2** : 40 min *(Focus soutenu)* + 10 min de pause
- **Bloc 3** : 30 min *(Rythme de croisière)* + 10 min de pause
- **Bloc 4** : 20 min *(Accélération)* + 10 min de pause
- **Bloc 5** : 10 min *(Sprint final)*

---

## ✨ Fonctionnalités Principales

- **Minuteur Séquentiel** : Compte à rebours circulaire avec distinction visuelle Travail / Pause et indicateur de progression en escalier.
- **Gestion des Objectifs & Tâches** : Planification par objectif, sous-tâches avec durées estimées et association directe au minuteur.
- **Statistiques & Tableau de Bord** : Suivi du temps de concentration hebdomadaire, histogramme journalier et séries de régularité (*streaks*).
- **Anti-Distraction** : Contrôles d'isolation (Ne Pas Déranger et verrouillage d'écran) pendant les blocs de focus.
- **Architecture Local-First** : Stockage local SQLite réactif et découplé via Riverpod et le Repository Pattern.

---

## 🤖 Agent IA

<!-- Section réservée pour l'intégration prochaine de l'agent IA -->

---

## 🛠️ Stack Technique

- **Framework** : [Flutter](https://flutter.dev/)
- **State Management & DI** : [Riverpod](https://riverpod.dev/)
- **Base de Données** : [Drift](https://drift.simonbinder.eu/) (SQLite)
- **CI/CD** : GitHub Actions (Qualité de code, tests automatisés, audit de sécurité)

---

## 🚀 Démarrage Rapide

```bash
# Télécharger les dépendances
flutter pub get

# Générer les fichiers de code (Drift)
dart run build_runner build --delete-conflicting-outputs

# Lancer les tests
flutter test

# Démarrer l'application
flutter run
```
