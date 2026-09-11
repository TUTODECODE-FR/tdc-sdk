# Contribuer à TDC-SDK

TDC-SDK est la suite d’outils officielle du langage **TUTODECODE Script (`.tdc`)**.

## Wishlist / bénévolat (Issues GitLab)

**Source de vérité** : [issues label `benevolat`](https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/?label_name[]=benevolat)  
Index détaillé : [VOLUNTEER_BOARD.md](./VOLUNTEER_BOARD.md) (pas de tableau à éditer à la main).

**Via l’app TDC Studio** → lanceur → **Hub Communauté** :

- liste **live** des issues `benevolat` (API GitLab) ;
- **Proposer une idée** / **Signaler un bug** (jeton scope `api`) ;
- **Préparer ma MR prendre** (deep-link + marqueur `volunteer/claims/<iid>.md`).

**Via GitLab** (modèles d’issue — le menu Type Incident/Issue/Task n’est pas personnalisable sur GitLab.com) :

- **Proposition** → labels `benevolat` + `proposition` + `wishlist` ;
- **Bug_benevolat** → `benevolat` + `bug` ;
- **Prendre_une_tache** → rappel uniquement : le claim se fait par MR `prendre #N`, pas par une issue.

Type **Task** optionnel pour le suivi ; il ne remplace ni labels ni claim.

### Prendre une tâche (automatisé)

1. Issue libre → branche `volunteer/prendre-<iid>` + fichier `volunteer/claims/<iid>.md` (pseudo GitLab).
2. MR titrée **exactement** `prendre #<iid>` (ex. `prendre #42`) + DCO — modèle MR **Prendre** recommandé.
3. Après merge de **cette** MR : CI assigne l’issue, pose `en-cours`, bloque les doubles claims.  
   Merger une issue « Proposition » **n’assigne pas** ; la MR de code ferme l’issue une fois le travail livré.

Puis **coder** : branche feature + MR classique avec **DCO** (`Signed-off-by: Prénom NOM <email>`).

### DCO et trailers interdits

- Chaque commit de MR doit porter un `Signed-off-by:` (job CI `dco_check`).
- **Ne pas** ajouter `Co-authored-by: Cursor <…>` (ni équivalent) : le job CI `no_cursor_coauthor` et le script [`scripts/check_no_cursor_coauthor.sh`](./scripts/check_no_cursor_coauthor.sh) le refusent sur les nouveaux commits. L’historique déjà publié sur `main` n’est **pas** réécrit.
- Hook local optionnel : `cp scripts/hooks/commit-msg.sample .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg`.

### Contrôles CI obligatoires (chaque MR)

Toute MR vers `main` déclenche le stage **validate**. Les jobs suivants doivent passer (sauf mention contraire) :

| Job | Rôle |
|-----|------|
| `dco_check` | `Signed-off-by:` sur chaque commit de la MR |
| `no_cursor_coauthor` | Interdit `Co-authored-by: Cursor` |
| `volunteer_claim_validate` | Anti-collision claims bénévolat |
| `flutter_analyze` | `flutter analyze --fatal-infos --fatal-warnings` + lockfile HTTPS |
| `flutter_test` | Suite de tests Flutter (+ validation `.tdc` soft) |
| `studio_security_parity` | Tests de parité sécurité Studio |
| `airgap_leak_canary` | Détection fuites réseau / airgap |
| `binary_hardening_audit` | Durcissement binaires |
| `sbom_generator` | Génération SBOM |
| `dependency_confusion_shield` | Confusion de dépendances |
| `secrets_and_private_keys_scan` | Secrets / clés privées en dur |
| `backdoor_and_anti_malware_scan` | Motifs reverse-shell / exécution distante |
| `zero_trust_tamper_defense` | Caractères Bidi / Trojan Source |
| `military_hardening_audit` | APIs mémoire C non sûres / shell brut |
| `gitleaks` | Secrets dans l’historique Git (**bloquant**) |
| `trivy_scan` | Vulns / config / secrets HIGH+CRITICAL (**bloquant**) |
| `semgrep_sast` | SAST Semgrep (**bloquant**) |

Jobs **soft** (ne bloquent pas la MR pour l’instant) :

- `megalinter` — lint multi-langues sur **tout** le dépôt (`VALIDATE_ALL_CODEBASE`) ; `allow_failure` tant que le bruit historique n’est pas résorbé
- `clamav_antivirus` — antivirus ; `allow_failure` (faux positifs / mirrors)
- `build_linux_check` — compile-check Linux desktop (deps apt) ; `allow_failure` transitoire

Les binaires release Win/macOS/Linux restent produits **uniquement** par GitHub Actions après merge + tag `v*` (voir `docs/ci-github-mirror.md`).

Contact : [contact@tutodecode.org](mailto:contact@tutodecode.org)

## Deux profils de contributeurs

### 1. Rédacteur pédagogique (cours, QCM)
- Utilise **TDC Studio Editorial** (`lib/main.dart`)
- Crée des fichiers `.tdc` avec la structure `course { module { quiz } }`
- Contribue dans le repo **T2DECODE** (`assets/courses.tdc`)

### 2. Développeur / Traducteur (cheat sheets, interface)
- Utilise **TDC Studio App** (`lib/tdc_app_studio_main.dart`)
- Édite les cheat sheets (`entry`) et les traductions UI (`locale`)
- Contribue dans le repo **T2DECODE** (`assets/cheat_sheets.tdc`, `assets/locales/`)

## Lancer les outils

```bash
cd TDC-Studio-IDE-App

# Studio Editorial (cours)
flutter run -d macos -t lib/main.dart

# Studio App (cheat sheets + locales)
flutter run -d macos -t lib/tdc_app_studio_main.dart
```

> Pour le web, remplacez `-d macos` par `-d chrome --web-port <port>`.

## Onboarding dans TDC Studio App

Au premier lancement, une fenêtre d’accueil présente :
1. La mission de l’outil (traduction / contenu pédagogique).
2. L’onglet **Cheat Sheets** : ajout/modification de commandes.
3. L’onglet **Locales UI** : traduction de l’interface.
4. L’onglet **Export** : écriture directe dans le dossier `assets/` de T2DECODE.
5. La méthode GitLab pour proposer une contribution.

L’utilisateur peut cocher **« Ne plus me montrer »** pour désactiver l’accueil.

## Import de fichiers .tdc existants

TDC Studio App peut charger des fichiers `.tdc` déjà existants pour éviter de tout retaper :
- **Cheat Sheets** : `Importer .tdc` dans l’onglet Cheat Sheets → parse les blocs `entry`.
- **Locales UI** : `Importer .tdc` dans l’onglet Locales UI → parse les blocs `locale`.
- **Cours** : `Importer un cours .tdc (aperçu)` dans l’onglet Export → affiche un aperçu des blocs `course`.

Cela permet à un traducteur de partir du fichier français, de le traduire ligne par ligne, puis de l’exporter dans `assets/`.

## Structure d’un fichier .tdc

```tdc
course "linux-basics" {
  title: "Linux : Le Pouvoir du Terminal"
  description: "Maîtrisez le système d'exploitation des serveurs."
  category: linux
  level: beginner
  duration: 2h

  module "terminal-intro" {
    title: "Premiers pas dans le terminal"
    duration: 15min
    content """
    # Le terminal
    Le terminal est l'interface texte de Linux.
    """
  }
}

entry "ip-link-show" {
  command: "ip link show"
  description: "Lister les interfaces réseau"
  category: Reseau
  dangerLevel: 1
  explanation: """
  Affiche toutes les interfaces réseau...
  """
}

locale "en" {
  menu.home: "Home"
  menu.tools: "Tools"
}
```

## Licence

Les outils TDC-SDK (Studio, CLI, extension VS Code, spécification) sont sous **GPLv3**.
Les contenus pédagogiques produits par l’association sont publiés sous licence libre (**CC BY-SA 4.0** ou **GPLv3**) afin de garantir la souveraineté pédagogique.
