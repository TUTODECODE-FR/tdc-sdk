// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Built-in cheat sheet templates for Dev & Traduction.
library;

import 'package:flutter/material.dart';

import '../../tdc_parser_v2.dart';

class CheatSheetTemplates {
  CheatSheetTemplates._();

  static List<TdcResource> get all => [
        sshBasics(),
        nmapScan(),
        gitEssentials(),
      ];

  static TdcResource sshBasics() {
    return TdcResource(
      tdcVersion: '2',
      type: 'cheat_sheet',
      id: 'ssh-basics',
      concrete: TdcCheatSheet(
        id: 'ssh-basics',
        title: 'SSH — Bases',
        category: 'admin_sys',
        dangerLevel: 1,
        entries: [
          TdcCheatEntry(
            id: 'ssh-connect',
            command: 'ssh user@host',
            description: 'Connexion SSH classique',
            explanation: 'Ouvre une session shell distante chiffrée.',
            options: const ['-p PORT : port personnalisé', '-i KEY : clé privée'],
            examples: const ['ssh admin@10.0.0.5', 'ssh -p 2222 user@host'],
            warnings: const ['Vérifiez l\'empreinte du serveur au premier contact'],
          ),
          TdcCheatEntry(
            id: 'scp-copy',
            command: 'scp fichier user@host:/chemin/',
            description: 'Copier un fichier via SSH',
            explanation: 'Transfert sécurisé basé sur SSH.',
            examples: const ['scp backup.tar.gz admin@10.0.0.5:/tmp/'],
          ),
        ],
      ),
    );
  }

  static TdcResource nmapScan() {
    return TdcResource(
      tdcVersion: '2',
      type: 'cheat_sheet',
      id: 'nmap-scan',
      concrete: TdcCheatSheet(
        id: 'nmap-scan',
        title: 'Nmap — Découverte',
        category: 'network',
        dangerLevel: 2,
        entries: [
          TdcCheatEntry(
            id: 'nmap-quick',
            command: 'nmap -sV -T4 target',
            description: 'Scan rapide avec détection de services',
            explanation: '-sV tente d\'identifier versions ; -T4 accélère le scan.',
            options: const ['-p- : tous les ports', '-A : détection agressive'],
            examples: const ['nmap -sV -T4 192.168.1.0/24'],
            warnings: const ['Uniquement sur des réseaux autorisés'],
          ),
        ],
      ),
    );
  }

  static TdcResource gitEssentials() {
    return TdcResource(
      tdcVersion: '2',
      type: 'cheat_sheet',
      id: 'git-essentials',
      concrete: TdcCheatSheet(
        id: 'git-essentials',
        title: 'Git — Essentiel',
        category: 'git',
        dangerLevel: 1,
        entries: [
          TdcCheatEntry(
            id: 'git-status',
            command: 'git status',
            description: 'État du dépôt',
            explanation: 'Montre les fichiers modifiés, indexés ou non suivis.',
          ),
          TdcCheatEntry(
            id: 'git-commit',
            command: 'git commit -m "message"',
            description: 'Créer un commit',
            explanation: 'Enregistre un snapshot des fichiers indexés.',
            examples: const ['git commit -m "fix: alignement numéros de ligne"'],
          ),
        ],
      ),
    );
  }
}

/// Visual picker for cheat sheet templates.
Future<TdcResource?> showCheatSheetTemplatePicker(BuildContext context) {
  final templates = CheatSheetTemplates.all;
  return showDialog<TdcResource>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Templates Cheat Sheet',
                  style: TextStyle(
                    color: Color(0xFFF5EBDA),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisissez un modèle à adapter — rien n\'est définitif.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, i) {
                      final t = templates[i];
                      final sheet = t.asCheatSheet;
                      return Material(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, t),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sheet.title,
                                  style: const TextStyle(
                                    color: Color(0xFFF5EBDA),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sheet.category,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  '${sheet.entries.length} entrée(s)',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
