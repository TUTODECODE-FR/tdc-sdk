# TDC Studio

Application Flutter unifiée pour éditer les contenus TUTODECODE au format `.tdc`.

## Modes

| Mode | Fichier | Public | Usage |
|------|---------|--------|-------|
| **Éditeur de Cours** | `lib/editorial_screen.dart` | Rédacteurs pédagogiques | Créer/modifier les cours, chapitres et QCM |
| **Dev & Traduction** | `lib/app_studio_screen.dart` | Traducteurs / développeurs | Modifier les cheat sheets, traduire l’interface UI et exporter vers `assets/` |

Le point d’entrée unique est `lib/main.dart`. Il affiche un lanceur permettant de choisir le mode.

## Lancer

```bash
cd TDC-Studio-IDE-App
flutter pub get
flutter run -d macos -t lib/main.dart
```

> Le projet est configuré pour macOS. Le code signing local est désactivé (`CODE_SIGNING_ALLOWED = NO`) pour permettre les builds de développement sans certificat Apple.

## Architecture

- `lib/main.dart` — Lanceur `TdcStudioApp` / `TdcStudioLauncherScreen`.
- `lib/editorial_screen.dart` — `TdcEditorialScreen` (formulaire, éditeur .tdc, aperçu Markdown).
- `lib/app_studio_screen.dart` — `TdcAppStudioScreen` (cheat sheets, locales UI, export assets).
- `lib/onboarding_dialog.dart` — Dialogue d’accueil pour les nouveaux traducteurs.
- `lib/tdc_import_parser.dart` — Parseur d’import `.tdc` (cours, cheat sheets, locales).
- `lib/screens/volunteer_hub_screen.dart` — Hub Communauté : lecture du tableau d’idées, proposer une idée, signaler un bug (pas de réservation de tâche).
- `lib/screens/community_settings_screen.dart` — Liens GitLab + jeton optionnel pour idée/bug.

## Hub Communauté

Depuis le lanceur : **Hub Communauté** pour parcourir [VOLUNTEER_BOARD.md](../VOLUNTEER_BOARD.md), proposer une idée ou signaler un bug. Le jeton GitLab (scope `api`) n’est requis que pour ces envois. Pour contribuer du code : MR classique avec DCO (voir [CONTRIBUTING.md](../CONTRIBUTING.md)).

### Communauté / contributeurs

Le projet accueille des bénévoles (dev, UX, doc). Voir [CONTRIBUTORS.md](../CONTRIBUTORS.md) — notamment **Cristina Cavaleri** (@CavaleriCristina) sur l’empty state quiz (TDC-009).
