// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Export confirmation: validation checklist + suggested placement.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/export_paths.dart';

class ExportLocationResult {
  final bool confirmed;
  const ExportLocationResult({required this.confirmed});
}

/// Shows checklist + where to place the file, then asks to continue to save dialog.
Future<bool> showExportLocationDialog({
  required BuildContext context,
  required String resourceType,
  required String relativePath,
  required CourseExportCheck? check,
  String? fileName,
}) async {
  final folder = ExportPlacement.folderHint(relativePath);
  final hint = ExportPlacement.hintForType(resourceType);
  final name = fileName ?? relativePath.split('/').last;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final blocked = check != null && !check.ok;
      return Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      blocked ? Icons.error_outline : Icons.folder_special,
                      color: blocked
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF5EBDA),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        blocked ? 'Export bloqué' : 'Où placer le fichier ?',
                        style: const TextStyle(
                          color: Color(0xFFF5EBDA),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (check != null) ...[
                  ...check.errors.map(
                    (e) => _Line(
                      icon: Icons.cancel,
                      color: const Color(0xFFEF4444),
                      text: e,
                    ),
                  ),
                  ...check.warnings.map(
                    (w) => _Line(
                      icon: Icons.warning_amber,
                      color: const Color(0xFFF59E0B),
                      text: w,
                    ),
                  ),
                  if (check.ok)
                    const _Line(
                      icon: Icons.check_circle,
                      color: Color(0xFF10B981),
                      text: 'Checklist OK — prêt à exporter',
                    ),
                  const SizedBox(height: 16),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF5EBDA).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fichier : $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dossier suggéré :\n$folder/',
                        style: const TextStyle(
                          color: Color(0xFFF5EBDA),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chemin complet :\n$relativePath',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hint,
                        style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: relativePath));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chemin copié')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copier le chemin'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: blocked ? null : () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EBDA),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF2A2A2A),
                      ),
                      child: Text(blocked ? 'Corriger d\'abord' : 'Choisir l\'emplacement…'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
