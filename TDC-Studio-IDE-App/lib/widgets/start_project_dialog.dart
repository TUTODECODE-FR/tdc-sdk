// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Start dialog: import / from scratch / template (course or cheat sheet).
library;

import 'package:flutter/material.dart';

enum StartProjectChoice { importFile, fromScratch, template }

/// Asks how to start when an editor opens empty.
Future<StartProjectChoice?> showStartProjectDialog(
  BuildContext context, {
  String title = 'Nouveau projet',
  String subtitle = 'Rien n\'est prérempli. Comment souhaitez-vous commencer ?',
  bool showTemplate = true,
  String importSubtitle = 'Ouvrir un fichier .tdc existant comme base',
  String scratchSubtitle = 'Formulaire vide — vous créez tout vous-même',
  String templateTitle = 'Partir d\'un template',
  String templateSubtitle = 'Choisir un modèle prêt à adapter',
}) {
  return showDialog<StartProjectChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF5EBDA),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                _ChoiceTile(
                  icon: Icons.upload_file,
                  title: 'Importer un fichier .tdc',
                  subtitle: importSubtitle,
                  onTap: () => Navigator.pop(context, StartProjectChoice.importFile),
                ),
                const SizedBox(height: 12),
                _ChoiceTile(
                  icon: Icons.edit_note,
                  title: 'Écrire de zéro',
                  subtitle: scratchSubtitle,
                  onTap: () => Navigator.pop(context, StartProjectChoice.fromScratch),
                ),
                if (showTemplate) ...[
                  const SizedBox(height: 12),
                  _ChoiceTile(
                    icon: Icons.dashboard_customize,
                    title: templateTitle,
                    subtitle: templateSubtitle,
                    onTap: () => Navigator.pop(context, StartProjectChoice.template),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFF5EBDA), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF5EBDA),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
