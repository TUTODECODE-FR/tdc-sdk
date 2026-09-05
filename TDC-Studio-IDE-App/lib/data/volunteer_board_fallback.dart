// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

/// Contenu de secours si le réseau / GitLab est indisponible.
const volunteerBoardFallbackMarkdown = '''
# Tableau des contributions bénévoles — TDC-SDK

## Backlog

| ID | Statut | Priorité | Titre | Description courte | Compétences | Note | MR / Lien |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TDC-001 | Libre | P1 | Mettre à jour CONTRIBUTING (lanceur unifié) | Aligner CONTRIBUTING.md sur le lanceur TDC Studio v2. | Markdown, produit | — | — |
| TDC-002 | Libre | P1 | Guide pas-à-pas Studio → export → MR | Tutoriel court : créer/importer un `.tdc`, exporter, ouvrir une MR. | Rédaction, Git | — | — |
| TDC-003 | Libre | P2 | Relire l'onboarding Dev & Traduction | Vérifier les textes d'accueil / aide et proposer des corrections. | UX writing, FR | — | — |
| TDC-004 | Libre | P2 | Template cours Cryptographie | Template `.tdc` crypto / PKI pour « Partir d'un template ». | Pédagogie, `.tdc` | — | — |
| TDC-005 | Libre | P2 | Template cours Cloud | Parcours Cloud (IaaS / containers) pour le sélecteur de templates. | Pédagogie, `.tdc` | — | — |
| TDC-006 | Libre | P2 | Template cheat sheet Docker | Entrées Docker exportables via Studio App. | Pédagogie, `.tdc` | — | — |
| TDC-007 | Libre | P2 | Template cheat sheet iptables / réseau | Entrées iptables / filtrage réseau. | Pédagogie, réseau | — | — |
| TDC-008 | Libre | P2 | Franciser les messages de validation `.tdc` | Messages d'erreur parser & validation en FR cohérent. | Flutter/Dart, FR | — | — |
| TDC-009 | Libre | P2 | Empty state quiz guidé | Empty state avec CTA « Ajouter un quiz » si module sans quiz. | Flutter, UX | — | — |
| TDC-010 | Libre | P3 | Panneau d'aide mode Éditorial | Aide contextuelle dans l'éditeur de cours. | Flutter, UX writing | — | — |
| TDC-011 | Libre | P2 | Import cheat sheets : conserver les `warnings` | Ne pas perdre warnings / métadonnées à l'import. | Dart, parser | — | — |
| TDC-012 | Libre | P3 | Aperçu import cours plus riche | Enrichir l'aperçu avant export (modules, quiz, durée). | Flutter, UX | — | — |
''';
