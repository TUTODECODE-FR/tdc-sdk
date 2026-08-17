# 🎨 Extension VS Code : TUTODECODE Script (`.tdc`)

[![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)]()
[![DSL Version](https://img.shields.io/badge/TDC--DSL-v2.0-emerald.svg)](https://gitlab.com/tutodecode-org/tdc-sdk)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Extension officielle pour la création et l'édition de cours au format souverain **`.tdc` (TUTODECODE Course DSL v2)**.

Elle active automatiquement la coloration syntaxique, l'autocomplétion intelligente des blocs et des snippets de productivité pour concevoir des cours, des labs et des QCM interactifs.

---

## 🚀 Démarrage Rapide (En 3 étapes)

### 1. Créez un fichier `.tdc`
- Dans VS Code, faites **Fichier $\rightarrow$ Nouveau fichier...** (`Ctrl + N` ou `Cmd + N`).
- Enregistrez-le sous le nom **`mon_premier_cours.tdc`**.

### 2. Utilisez les Snippets magiques
- Dans votre fichier vide, tapez simplement :
  ```
  tdc-course
  ```
- Appuyez sur **`Tab`** ou **`Entrée`** : le squelette complet d'un cours avec métadonnées, chapitre et QCM s'insère automatiquement avec la coloration syntaxique !

### 3. Rédigez vos chapitres et QCM
- Déplacez-vous avec la touche `Tab` pour remplir le titre, la catégorie, le contenu Markdown et vos questions.

---

## ⚡ Liste des Snippets Disponibles

Tapez le préfixe puis appuyez sur `Tab` :

| Préfixe | Description |
| :--- | :--- |
| **`tdc-course`** | Génère la structure complète d'un cours `.tdc` avec métadonnées et un premier module. |
| **`tdc-module`** | Insère un nouveau chapitre / module avec durée et bloc Markdown `""" ... """`. |
| **`tdc-quiz`** | Insère un bloc d'évaluation interactif `quiz { ... }`. |
| **`tdc-question`** | Insère une question QCM avec options, bonne réponse (`correctAnswer`) et explication. |
| **`tdc-codeblock`** | Insère un bloc de code exécutable ou un lab interactif. |
| **`tdc-category-custom`** | Déclare une catégorie personnalisée (`category custom "id" { ... }`). |

---

## 📄 Exemple Complet de Fichier `.tdc`

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

## 🔍 Validation en Terminal (`tdc CLI`)

Une fois votre cours rédigé, validez sa conformité en ouvrant le terminal intégré de VS Code (`Ctrl + \``) :

```bash
# Vérifier la syntaxe et la conformité
./tdc check mon_premier_cours.tdc

# Extraire les métadonnées et la signature
./tdc info mon_premier_cours.tdc
```

---

## 🌐 Liens Utiles & Communauté

- 📖 **Documentation & Spécification complète** : [TDC_SPEC.md](https://gitlab.com/tutodecode-org/tdc-sdk/-/blob/main/TDC_SPEC.md)
- 🦊 **Dépôt GitLab TDC-SDK** : [https://gitlab.com/tutodecode-org/tdc-sdk](https://gitlab.com/tutodecode-org/tdc-sdk)
- 💖 **Soutenir le projet** : [https://liberapay.com/tutodecode/donate](https://liberapay.com/tutodecode/donate)
- 🏢 **Site Officiel** : [https://tutodecode.org](https://tutodecode.org)
