# Focus60 (Max-Productivity-Clock)

> **Application mobile de Deep Work et de productivité basée sur la méthode des cycles d'attention dégressifs (50 → 10 minutes).**

---

## 🎯 Vision et Objectifs du Projet

La plupart des méthodes de gestion du temps (comme la méthode Pomodoro classique 25 min / 5 min) reposent sur des intervalles fixes. Cependant, l'énergie cognitive et la capacité d'attention diminuent naturellement au fil d'une session de travail prolongée.

**Focus60** a été conçu pour répondre à cette réalité biologique grâce à une séquence de travail structurée, dégressive et rythmée, combinée à une protection stricte contre les distractions numériques.

### Objectifs Clés
1. **Optimiser la concentration par palier dégressif** : Accompagner la baisse progressive de la charge mentale grâce à la séquence « en escalier » ($50 \to 40 \to 30 \to 20 \to 10\text{ min}$).
2. **Éliminer radicalement les distractions** : Intégrer des fonctionnalités matérielles Android (mode *Ne pas déranger* et *verrouillage d'écran / screen pinning*) pour empêcher l'utilisateur de quitter son application ou d'être perturbé par des notifications.
3. **Lier le temps aux objectifs réels** : Associer chaque session de focus à un objectif précis et à des tâches concrètes, évitant ainsi le travail sans but (« busywork »).
4. **Suivre et valoriser l'effort** : Fournir des indicateurs clairs (temps total, régularité/streaks, répartition par projet) pour mesurer ses progrès semaine après semaine.
5. **Architecture robuste & Local-First** : Assurer une réactivité totale et une confidentialité maximale grâce à une base SQLite locale, tout en prévoyant une extension cloud transparente (Supabase).

---

## ⏱️ Le Concept : La Séquence 50 → 10 (« L'escalier »)

Une session complète de travail se compose de **5 blocs de travail** entrecoupés de **pauses de récupération de 10 minutes** :

| Bloc | Phase | Durée | Pause associée | Objectif mental |
| :---: | :--- | :---: | :---: | :--- |
| **1** | Focus maximal | **50 min** | 10 min | Tâche lourde, analyse, conception, rédaction |
| **2** | Focus soutenu | **40 min** | 10 min | Développement, approfondissement, structuration |
| **3** | Rythme de croisière | **30 min** | 10 min | Résolution de problèmes, tests, revues |
| **4** | Accélération | **20 min** | 10 min | Finalisation, refactoring, documentation |
| **5** | Sprint final | **10 min** | Fin de session | Tâches rapides, clôture, rangement |

* **Temps de travail total** : 150 minutes (2h30 de concentration intense).
* **Temps de pause total** : 40 à 50 minutes de récupération.

---

## 🚀 Fonctionnalités Principales

### 1. Minuteur Séquentiel & Signature Visuelle (`TimerPage`)
* **Compte à rebours circulaire** avec retour visuel du temps écoulé et distinction claire des états *Travail* (teinte accent turquoise) et *Pause* (teinte ambre).
* **Indicateur en escalier** illustrant la progression à travers les 5 blocs ($50, 40, 30, 20, 10\text{ min}$).
* Raccordement dynamique à l'objectif et à la tâche en cours d'exécution.
* Commandes de contrôle : Démarrer, Mettre en pause, Réinitialiser.

### 2. Isolation & Anti-Distraction Android Native
* **Mode Ne Pas Déranger (DND)** :
  * Contrôle direct via `NotificationManager` natif Android.
  * Active automatiquement le filtre `INTERRUPTION_FILTER_ALARMS` (seules les alarmes réveil/sécurité sonnent).
  * Mémorise et restaure automatiquement la configuration de notifications de l'utilisateur à la fin de la session.
* **Épinglage d'Écran (*Lock Task*)** :
  * Utilise l'API Android `startLockTask()` / `stopLockTask()`.
  * Empêche de quitter l'application ou d'ouvrir d'autres applications distrayantes (réseaux sociaux, messageries) pendant le bloc de concentration.

### 3. Gestion des Objectifs et Tâches (`GoalsPage`)
* **Objectifs (Goals)** : Définition d'un titre, d'une description facultative, d'une date d'échéance et d'une priorité.
* **Tâches (Tasks)** : Découpage granulaire d'un objectif en sous-tâches avec durée estimée en minutes.
* **Calcul automatique de progression** : Visualisation en pourcentage ($\% = \frac{\text{tâches faites}}{\text{total des tâches}}$) et barre de progression dynamique.
* Opérations CRUD complètes avec mise à jour réactive de l'interface en temps réel.

### 4. Tableau de Bord & Statistiques (`StatsPage`)
* **KPIs Clés** :
  * Temps cumulé de focus sur la semaine (ex. *12 h 40*).
  * Série de jours consécutifs d'utilisation (*Streaks*).
* **Histogramme hebdomadaire** : Visualisation du temps de concentration jour par jour (du Lundi au Dimanche).
* **Ventilation par objectif** : Suivi précis du temps consacré à chaque grand projet.

---

## 🏗️ Architecture & Choix Techniques

Le projet respecte une architecture modulaire, réactive et découplée (Local-First) :

```
lib/
├── core/                           # Éléments partagés et configuration globale
│   ├── constants/focus_sequence.dart  # Définition des blocs [50, 40, 30, 20, 10] et pauses
│   ├── platform/                   # Ponts natifs (Platform Channels)
│   │   ├── dnd_service.dart        # Service Ne Pas Déranger (MethodChannel focus60/dnd)
│   │   └── lock_service.dart       # Service d'épinglage d'écran (MethodChannel focus60/lock)
│   └── ui.dart                     # Thème Material 3 sombre, charte graphique (AppColors), composants de base
├── data/                           # Couche de données (Data Layer)
│   ├── db/
│   │   ├── tables.dart             # Définition Drift/SQLite : Goals, Tasks, FocusSessions
│   │   ├── app_database.dart       # Instance Drift avec support des clés étrangères PRAGMA
│   │   └── app_database.g.dart     # Fichiers générés par drift_dev
│   └── repositories/               # Repository Pattern
│       ├── goal_repository.dart    # Interface abstraite des objectifs & tâches
│       ├── session_repository.dart # Interface abstraite des sessions de focus
│       └── local/                  # Implémentations locales avec Drift / SQLite
│           ├── local_goal_repository.dart
│           └── local_session_repository.dart
├── features/                       # Présentation découpée par fonctionnalité
│   ├── home/home_shell.dart        # Coquille de navigation principale (IndexedStack)
│   ├── timer/timer_page.dart       # Minuteur et gestionnaire de session
│   ├── goals/goals_page.dart       # Liste des objectifs, tâches, dialogues d'édition
│   └── stats/stats_page.dart       # Dashboard, KPIs et graphiques d'activité
├── app.dart                        # Configuration MaterialApp
├── main.dart                       # Point d'entrée, initialisation DB et ProviderScope
└── providers.dart                  # Injection de dépendances et Streams Riverpod
```

### Stack Technique
* **Framework** : [Flutter](https://flutter.dev/) (SDK Dart `^3.13.5`)
* **State Management & DI** : [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
* **Base de données Locale** : [Drift](https://drift.simonbinder.eu/) (`drift`, `drift_flutter`, `path_provider`) pour un typage statique complet, migrations gérées et réactivité par Streams.
* **Tâches en arrière-plan & Notifications** : `flutter_local_notifications`, `flutter_foreground_task`
* **Intégration Native** : Kotlin sous Android (`MainActivity.kt`) pour les APIs DND (`NotificationManager`) et LockTask.
* **Tests** : `flutter_test`, `mocktail`, bases SQLite en mémoire (`NativeDatabase.memory`).

### Conception Évolutive (Cloud-Ready)
Grâce au découplage par le **Repository Pattern**, l'application peut passer d'un stockage purement local (Drift/SQLite) à une synchronisation Cloud (ex. Supabase / Firebase) simplement en modifiant les deux providers dans `lib/providers.dart`, sans toucher au code des interfaces utilisateurs ni à la logique métier.

---

## ⚙️ DevOps & Qualité de Code

Le projet intègre un pipeline CI/CD automatisé sous **GitHub Actions** :

1. **Intégration Continue (`.github/workflows/ci.yml`)** :
   * Génération de code (`build_runner build`).
   * Vérification du formatage du code (`dart format --set-exit-if-changed`).
   * Analyse statique stricte (`flutter analyze`).
   * Exécution des tests unitaires et widgets avec couverture (`flutter test --coverage`).
   * Détection de fuites de secrets (`gitleaks`).
   * Analyse de vulnérabilités des dépendances (`osv-scanner`).

2. **Livraison Continue & Release (`.github/workflows/release.yml`)** :
   * Déclenchement automatique sur tag Git (`v*`).
   * Signature de production de l'APK via Keystore chiffré en secrets GitHub.
   * Compilation de l'APK Android avec obfuscation et séparation des symboles de débogage (`--obfuscate --split-debug-info`).
   * Génération des sommes de contrôle SHA256.
   * Publication automatique des fichiers d'artefacts sur les GitHub Releases.

---

## 📋 Feuille de Route (Roadmap)

- [x] Modèle de données SQLite avec Drift (Objectifs, Tâches, Sessions).
- [x] Interface utilisateur sombre Material 3 adaptée au travail prolongé.
- [x] Minuteur avec séquence dégressive (50, 40, 30, 20, 10 min).
- [x] Canaux natifs Android pour *Ne pas déranger* et *Épinglage d'écran*.
- [x] Suivi et gestion complète des objectifs et sous-tâches associées.
- [x] Pipeline CI/CD automatisé (analyse, tests, sécurité, release).
- [ ] Branchement direct du service de foreground task et alarmes sonores de transition de pause.
- [ ] Exportation et sauvegarde des données en local (CSV / JSON via `file_picker` et `share_plus`).
- [ ] Synchronisation cloud multi-appareils (implémentation Supabase du `GoalRepository` et `SessionRepository`).
- [ ] Compatibilité multi-plateforme (iOS, Bureau).
