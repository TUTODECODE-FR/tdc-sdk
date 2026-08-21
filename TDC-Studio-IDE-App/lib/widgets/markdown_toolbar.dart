// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Markdown toolbar with snippets for course content editing.
library;

import 'package:flutter/material.dart';

typedef MarkdownInsertCallback = void Function(String before, String after, {String? placeholder});
typedef MarkdownSnippetCallback = void Function(String snippet);

class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({
    super.key,
    required this.onWrap,
    required this.onSnippet,
  });

  final MarkdownInsertCallback onWrap;
  final MarkdownSnippetCallback onSnippet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _btn('H1', () => onWrap('# ', '', placeholder: 'Titre')),
          _btn('H2', () => onWrap('## ', '', placeholder: 'Sous-titre')),
          _btn('H3', () => onWrap('### ', '', placeholder: 'Section')),
          _sep(),
          _iconBtn(Icons.format_bold, 'Gras', () => onWrap('**', '**', placeholder: 'texte')),
          _iconBtn(Icons.format_italic, 'Italique', () => onWrap('*', '*', placeholder: 'texte')),
          _sep(),
          _iconBtn(Icons.format_list_bulleted, 'Liste', () => onWrap('- ', '', placeholder: 'élément')),
          _iconBtn(Icons.format_list_numbered, 'Liste num.', () => onWrap('1. ', '', placeholder: 'élément')),
          _iconBtn(Icons.code, 'Code inline', () => onWrap('`', '`', placeholder: 'code')),
          _iconBtn(Icons.data_object, 'Bloc code', () => onSnippet('```bash\n# commande\n```\n')),
          _iconBtn(Icons.link, 'Lien', () => onWrap('[', '](https://)', placeholder: 'libellé')),
          _sep(),
          _chip('code', () => onSnippet(
                '```bash\nuptime\nfree -h\n```\n',
              )),
          _chip('quiz', () => onSnippet(
                '### Quiz\n\n**Question :** …\n\n- [ ] Option A\n- [x] Option B\n\n> Explication : …\n',
              )),
          _chip('incident', () => onSnippet(
                '# 🚨 Incident de Production\n\n'
                'Vous êtes connecté en SSH sur un serveur distant.\n\n'
                '## Symptômes\n- …\n\n## Diagnostic\n```bash\nuptime\n```\n\n## Solution\n…\n',
              )),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF5EBDA),
        minimumSize: const Size(36, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: const Color(0xFFF5EBDA)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFF5EBDA))),
      backgroundColor: const Color(0xFF2A2A2A),
      side: const BorderSide(color: Color(0xFF3A3A3A)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _sep() => Container(width: 1, height: 20, color: const Color(0xFF2A2A2A), margin: const EdgeInsets.symmetric(horizontal: 4));
}

/// Helper to insert wrap/snippet into a TextEditingController.
void applyMarkdownWrap(
  TextEditingController controller,
  String before,
  String after, {
  String? placeholder,
}) {
  final text = controller.text;
  final sel = controller.selection;
  final start = sel.start.clamp(0, text.length);
  final end = sel.end.clamp(0, text.length);
  final selected = start < end ? text.substring(start, end) : (placeholder ?? '');
  final insertion = '$before$selected$after';
  controller.value = TextEditingValue(
    text: text.replaceRange(start, end, insertion),
    selection: TextSelection.collapsed(offset: start + insertion.length - after.length),
  );
}

void applyMarkdownSnippet(TextEditingController controller, String snippet) {
  final text = controller.text;
  final sel = controller.selection;
  final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
  controller.value = TextEditingValue(
    text: text.replaceRange(start, start, snippet),
    selection: TextSelection.collapsed(offset: start + snippet.length),
  );
}
