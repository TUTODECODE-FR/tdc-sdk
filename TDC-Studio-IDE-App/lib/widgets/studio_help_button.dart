// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Toolbar action button with tooltip + optional help modal.
library;

import 'package:flutter/material.dart';

class StudioAction {
  final IconData icon;
  final String label;
  final String help;
  final VoidCallback? onPressed;
  final bool primary;

  const StudioAction({
    required this.icon,
    required this.label,
    required this.help,
    this.onPressed,
    this.primary = false,
  });
}

/// Beige/dark action button with long tooltip explaining what it does.
class StudioHelpButton extends StatelessWidget {
  const StudioHelpButton({super.key, required this.action});

  final StudioAction action;

  @override
  Widget build(BuildContext context) {
    final style = action.primary
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5EBDA),
            foregroundColor: Colors.black,
          )
        : ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            foregroundColor: const Color(0xFFF5EBDA),
            side: const BorderSide(color: Color(0xFFF5EBDA)),
          );

    return Tooltip(
      message: action.help,
      waitDuration: const Duration(milliseconds: 400),
      child: ElevatedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 16),
        label: Text(action.label),
        style: style,
      ),
    );
  }
}

/// Opens a visual legend of all toolbar actions.
Future<void> showStudioHelpDialog(
  BuildContext context, {
  required String title,
  required List<StudioAction> actions,
  String? intro,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline, color: Color(0xFFF5EBDA)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFF5EBDA),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                if (intro != null) ...[
                  const SizedBox(height: 8),
                  Text(intro, style: const TextStyle(color: Colors.white70, height: 1.4)),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: actions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = actions[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: a.primary
                                    ? const Color(0xFFF5EBDA)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                a.icon,
                                color: a.primary ? Colors.black : const Color(0xFFF5EBDA),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.label,
                                    style: const TextStyle(
                                      color: Color(0xFFF5EBDA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.help,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5EBDA),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Compris'),
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
