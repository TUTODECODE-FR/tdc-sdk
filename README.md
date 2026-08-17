# 🚀 TUTODECODE — Suite Officielle TDC-SDK

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![DSL Version](https://img.shields.io/badge/TDC--DSL-v2.0-emerald.svg)](./TDC_SPEC.md)
[![VS Code Extension](https://img.shields.io/badge/VS%20Code-Extension%20Available-blue)](./vscode-tdc/)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)]()
[![Air-Gapped](https://img.shields.io/badge/Security-Air--Gapped%20%26%20Sovereign-gold.svg)]()

Bienvenue dans l'écosystème officiel **TDC-SDK** du projet **TUTODECODE** !

Le **TDC-SDK** est la suite d'outils et de spécifications formelles dédiée à la création, l'édition, la validation syntaxique, la signature cryptographique et la distribution de cours interactifs souverains au format **`.tdc` (TUTODECODE Course DSL v2)**.

---

## 📦 Contenu de la Suite TDC-SDK

```
~/Documents/TDC-SDK/
├── TDC-Studio-IDE-App/     # Code source Flutter de l'IDE TDC Studio
├── TDC-Studio.app/         # Application macOS Native (IDE Standalone)
├── tdc                     # Outil CLI terminal (Linter, validateur, convertisseur)
├── vscode-tdc/             # Extension officielle Visual Studio Code & fichier .vsix
├── TDC_SPEC.md             # Spécification formelle de la grammaire .tdc v2
├── logo.png                # Logo officiel TUTODECODE
└── README.md               # Documentation générale & guide d'installation
```

---

## 💻 Comment utiliser l'extension VS Code (Sans utiliser l'application Studio)

Si vous préférez rédiger vos cours directement dans **Visual Studio Code**, **Cursor** ou **VSCodium** sans ouvrir l'IDE visuel, l'extension officielle vous offre une coloration syntaxique complète, des snippets d'autocomplétion et le formatage de vos fichiers `.tdc`.

### Méthode 1 : Installation en 2 clics via l'interface graphique de VS Code (Recommandé)

1. Téléchargez le fichier [**`vscode-tdc-language-1.0.0.vsix`**](./vscode-tdc/vscode-tdc-language-1.0.0.vsix) situé dans le dossier `vscode-tdc/`.
2. Ouvrez **Visual Studio Code**.
3. Ouvrez le panneau des **Extensions** :
   - Raccourci clavier : `Ctrl + Maj + X` *(Windows/Linux)* ou `⌘ + Shift + X` *(macOS)*.
4. Cliquez sur le menu **`⋯`** *(trois petits points en haut à droite du panneau Extensions)*.
5. Sélectionnez **`Installer depuis un fichier VSIX...`** (*Install from VSIX...*).
6. Choisissez le fichier `vscode-tdc-language-1.0.0.vsix`.
7. **C'est prêt !** Dès que vous ouvrez ou créez un fichier se terminant par `.tdc`, il sera automatiquement reconnu avec sa coloration et ses fonctionnalités.

---

### Méthode 2 : Installation via la ligne de commande (Terminal)

Si la commande `code` est disponible dans votre terminal :
```bash
code --install-extension vscode-tdc/vscode-tdc-language-1.0.0.vsix
```

*Pour Cursor :*
```bash
cursor --install-extension vscode-tdc/vscode-tdc-language-1.0.0.vsix
```

---

### Méthode 3 : Copie manuelle directe dans le dossier d'extensions

Si vous êtes dans un environnement totalement hors-ligne (*air-gapped*) sans accès à la commande `code` :

- **Sur macOS / Linux** :
  ```bash
  mkdir -p ~/.vscode/extensions
  cp -R vscode-tdc ~/.vscode/extensions/tutodecode.vscode-tdc-language-1.0.0
  ```

- **Sur Windows (PowerShell)** :
  ```powershell
  New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.vscode\extensions"
  Copy-Item -Recurse vscode-tdc "$env:USERPROFILE\.vscode\extensions\tutodecode.vscode-tdc-language-1.0.0"
  ```

---

## ⚡ Snippets rapides dans VS Code

Dans tout fichier `.tdc`, tapez les préfixes suivants puis appuyez sur `Tab` ou `Entrée` pour générer automatiquement la structure :

| Préfixe | Description de la structure générée |
| :--- | :--- |
| **`tdc-course`** | Génère un squelette de cours complet avec métadonnées, module et QCM. |
| **`tdc-module`** | Génère un nouveau chapitre / module avec durée et bloc Markdown `""" ... """`. |
| **`tdc-quiz`** | Génère un bloc d'évaluation interactive `quiz { ... }`. |
| **`tdc-question`** | Génère une question avec options, bonne réponse (`correctAnswer`) et explication. |
| **`tdc-codeblock`** | Insère un bloc de code exécutable ou lab interactif. |
| **`tdc-category-custom`** | Déclare une catégorie personnalisée auto-contenue (`category custom "id" { ... }`). |

---

## 🔍 Validation en Terminal avec l'outil CLI `tdc`

Après avoir rédigé ou modifié votre fichier `.tdc` dans VS Code, vous pouvez valider sa syntaxe en une commande :

```bash
# Vérifier la conformité de votre cours (détecte les erreurs de syntaxe et les lignes précises)
./tdc check mon_cours.tdc

# Extraire les métadonnées et le statut de signature
./tdc info mon_cours.tdc

# Convertir un ancien fichier JSON en syntaxe .tdc DSL v2
./tdc convert-json ancien_cours.json -o mon_cours.tdc
```

---

## 🛠️ Utilisation de l'IDE visuel Standalone (`TDC-Studio.app`)

Pour les utilisateurs préférant une interface graphique complète :
- Double-cliquez sur `TDC-Studio.app` (sur macOS) ou lancez :
  ```bash
  open TDC-Studio.app
  ```
- **Fonctionnalités** : Formulaire interactif guidé, éditeur avec numérotation de ligne et diagnostic de syntaxe en temps réel, signature cryptographique Ed25519, sélecteur parmi 250+ icônes et aperçu apprenant immersif identique à l'application **T2DECODE**.

---

## 🖥️ Compilation Multi-OS Native (macOS, Windows, Linux)

L'IDE **TDC Studio** est bâti sur Flutter Desktop et se compile en application native autonome pour les trois systèmes d'exploitation :

### 🍏 Compiler pour macOS (.app)
```bash
# Compilation de la version Release
flutter build macos -t lib/tdc_studio_main.dart

# Lancement direct de l'exécutable
open build/macos/Build/Products/Release/TDC-Studio.app
```

### 🪟 Compiler pour Windows (.exe standalone)
```powershell
# Compilation de la version Release sous Windows
flutter build windows -t lib/tdc_studio_main.dart

# L'exécutable natif se trouve dans :
# build/windows/x64/runner/Release/TDC-Studio.exe
```

### 🐧 Compiler pour Linux (.bin / AppImage / Tarball)
```bash
# Dépendances requises sous Ubuntu / Debian :
# sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev

# Compilation de la version Release sous Linux
flutter build linux -t lib/tdc_studio_main.dart

# L'exécutable natif se trouve dans :
# build/linux/x64/release/bundle/tdc_studio
```

---

## 🛡️ Pipeline CI/CD & Conformité T2DECODE

Tout commit ou proposition de cours via Merge Request (MR) sur le projet T2DECODE / TDC-SDK est rigoureusement audité par le pipeline de validation de sécurité et de conformité :
- **`test_and_analyze`** : 0 avertissement bloquant (`dart analyze` propre) et 100% des tests unitaires au vert.
- **`strict_type_compilation_check`** : Typage statique strict et intégrité de compilation multi-plateforme.
- **`zero_trust_tamper_defense` & `gitleaks`** : Zéro secret ou fuite de clé privée dans le dépôt.
- **`airgap_leak_canary`** : Garantie de fonctionnement 100% autonome sans connexion Internet obligatoire (*air-gapped*).
- **`constant_time_crypto_test`** : Vérification cryptographique déterministe de la signature Ed25519.

## 📄 Exemple Complet de Fichier `.tdc` (DSL v2)

```tdc
category custom "devops" {
  label: "DevOps & CI/CD"
  color: mint
  icon: Rocket
}

course "ansible-automation" {
  title: "Ansible : Automatisation d'Infrastructure"
  description: "Déployez et configurez vos parcs de serveurs en quelques playbooks YAML souverains."
  category: devops
  accent: mint
  level: intermediate
  duration: 3h
  icon: Rocket
  author: "Marc DevOps"
  author-key: "FP-a89b2c41"
  keywords: ["ansible", "devops", "automation", "yaml", "ssh"]

  module "mod-1" {
    title: "1. Playbooks et Inventaires"
    duration: 30min
    content """
# Introduction à Ansible
Ansible permet l'automatisation sans agent (*agentless*) via OpenSSH.
    """

    quiz {
      question "Quel protocole utilise Ansible par défaut pour se connecter aux nœuds ?" {
        options: ["SSH", "Telnet", "RDP", "SNMP"]
        correctAnswer: 0
        explanation: "Ansible est agentless et s'appuie nativement sur OpenSSH."
      }
    }
  }
}
```

---

## 📜 Licence & Gouvernance

Le projet **TDC-SDK** est un logiciel libre sous licence **GNU General Public License v3.0 (GPL-3.0)**.  
Développé et maintenu par l'**Association TUTODECODE (Loi 1901)**.

- 🌐 Site officiel : [https://tutodecode.org](https://tutodecode.org)
- 🦊 Dépôt GitLab : [https://gitlab.com/tutodecode-org/tdc-sdk](https://gitlab.com/tutodecode-org/tdc-sdk)
- 📬 Contact : `contact@tutodecode.org`
