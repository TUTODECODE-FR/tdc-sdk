# Contribuer à TDC-SDK

TDC-SDK est la suite d’outils officielle du langage **TUTODECODE Script (`.tdc`)**.

## Tableau des bénévoles (source de vérité)

**Avant d’ouvrir une issue ou de coder au hasard**, consulte et mets à jour le cahier des charges vivant :

👉 **[VOLUNTEER_BOARD.md](./VOLUNTEER_BOARD.md)** — backlog des améliorations, statut, et colonne **Pris par** (ton pseudo GitLab/GitHub).

- Une tâche libre → tu l’inscris à ton nom (`En cours`) via une MR.
- Une tâche = une Merge Request, avec **DCO** (`Signed-off-by`).
- Tu abandonnes → tu retires ton pseudo pour libérer la ligne.
- Contact : [contact@tutodecode.org](mailto:contact@tutodecode.org)

Les issues GitLab restent utiles pour discuter un point précis, mais **le board est la référence** pour savoir qui fait quoi.

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
