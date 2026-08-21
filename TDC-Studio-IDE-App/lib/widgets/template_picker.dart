// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Grid template picker for course templates.
library;

import 'package:flutter/material.dart';
import '../data/templates/course_templates.dart';
import '../tdc_parser_v2.dart';

Future<TdcResource?> showTemplatePicker(BuildContext context) {
  return showDialog<TdcResource>(
    context: context,
    builder: (context) => const _TemplatePickerDialog(),
  );
}

class _TemplatePickerDialog extends StatelessWidget {
  const _TemplatePickerDialog();

  @override
  Widget build(BuildContext context) {
    final templates = CourseTemplates.all;
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Bibliothèque de templates',
                    style: TextStyle(
                      color: Color(0xFFF5EBDA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Choisissez un modèle pour pré-remplir le cours.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, i) {
                    final t = templates[i];
                    final course = t.asCourse;
                    final quizCount = course.modules.fold<int>(0, (s, m) => s + m.questions.length);
                    return _TemplateCard(
                      title: course.title,
                      category: course.category,
                      level: course.level,
                      duration: course.duration,
                      modules: course.modules.length,
                      quizzes: quizCount,
                      onTap: () => Navigator.pop(context, t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  const _TemplateCard({
    required this.title,
    required this.category,
    required this.level,
    required this.duration,
    required this.modules,
    required this.quizzes,
    required this.onTap,
  });

  final String title;
  final String category;
  final String level;
  final String duration;
  final int modules;
  final int quizzes;
  final VoidCallback onTap;

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _hover = false;

  IconData get _icon {
    switch (widget.category) {
      case 'linux':
      case 'system':
        return Icons.terminal;
      case 'network':
        return Icons.lan;
      default:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? const Color(0xFFF5EBDA) : const Color(0xFF2A2A2A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBDA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: const Color(0xFFF5EBDA), size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.modules} chapitres · ${widget.quizzes} questions',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Spacer(),
              Row(
                children: [
                  _badge(widget.level),
                  const SizedBox(width: 6),
                  _badge(widget.duration),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EBDA),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Utiliser', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }
}
