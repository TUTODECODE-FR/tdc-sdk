// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Visual quiz editor with reorderable questions and XP points.
library;

import 'package:flutter/material.dart';

class QuizQuestionData {
  String question;
  List<String> choices;
  int correctIndex;
  String explanation;
  int xp;

  QuizQuestionData({
    this.question = '',
    List<String>? choices,
    this.correctIndex = 0,
    this.explanation = '',
    this.xp = 10,
  }) : choices = choices ?? ['', '', ''];

  Map<String, dynamic> toMap() => {
        'question': question,
        'choices': List<String>.from(choices),
        'correctIndex': correctIndex,
        'explanation': explanation,
        'xp': xp,
      };

  factory QuizQuestionData.fromMap(Map<String, dynamic> map) {
    return QuizQuestionData(
      question: map['question'] as String? ?? '',
      choices: List<String>.from((map['choices'] as List?) ?? ['', '', '']),
      correctIndex: map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String? ?? '',
      xp: map['xp'] as int? ?? 10,
    );
  }
}

class QuizEditor extends StatelessWidget {
  const QuizEditor({
    super.key,
    required this.questions,
    required this.onChanged,
  });

  final List<QuizQuestionData> questions;
  final VoidCallback onChanged;

  int get totalXp => questions.fold(0, (sum, q) => sum + q.xp);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Quiz', style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBDA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${questions.length} Q · $totalXp XP',
                style: const TextStyle(color: Color(0xFFF5EBDA), fontSize: 11),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                questions.add(QuizQuestionData());
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16, color: Color(0xFFF5EBDA)),
              label: const Text('Question', style: TextStyle(color: Color(0xFFF5EBDA))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          onReorderItem: (oldIndex, newIndex) {
            final item = questions.removeAt(oldIndex);
            questions.insert(newIndex, item);
            onChanged();
          },
          itemBuilder: (context, index) {
            final q = questions[index];
            return _QuestionCard(
              key: ValueKey('quiz-$index-${identityHashCode(q)}'),
              index: index,
              data: q,
              onChanged: onChanged,
              onDelete: () {
                questions.removeAt(index);
                onChanged();
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.data,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final QuizQuestionData data;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text('Q${index + 1}', style: const TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '${data.xp}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      labelText: 'XP',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      data.xp = int.tryParse(v) ?? 10;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: data.question,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Question *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                data.question = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            ...List.generate(data.choices.length, (i) {
              final isCorrect = data.correctIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        data.correctIndex = i;
                        onChanged();
                      },
                      tooltip: 'Bonne réponse',
                      icon: Icon(
                        isCorrect ? Icons.check_circle : Icons.circle_outlined,
                        color: isCorrect ? const Color(0xFF10B981) : Colors.grey,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: data.choices[i],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          data.choices[i] = v;
                          onChanged();
                        },
                      ),
                    ),
                    if (data.choices.length > 2)
                      IconButton(
                        onPressed: () {
                          data.choices.removeAt(i);
                          if (data.correctIndex >= data.choices.length) {
                            data.correctIndex = data.choices.length - 1;
                          }
                          onChanged();
                        },
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                data.choices.add('');
                onChanged();
              },
              icon: const Icon(Icons.add, size: 14, color: Colors.grey),
              label: const Text('Option', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextFormField(
              initialValue: data.explanation,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Explication pédagogique',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                data.explanation = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive quiz preview for the learner preview tab.
class QuizPreview extends StatefulWidget {
  const QuizPreview({super.key, required this.questions});

  final List<QuizQuestionData> questions;

  @override
  State<QuizPreview> createState() => _QuizPreviewState();
}

class _QuizPreviewState extends State<QuizPreview> {
  final _answers = <int, int>{};
  bool _submitted = false;

  int get _score {
    var s = 0;
    for (var i = 0; i < widget.questions.length; i++) {
      if (_answers[i] == widget.questions[i].correctIndex) {
        s += widget.questions[i].xp;
      }
    }
    return s;
  }

  int get _maxXp => widget.questions.fold(0, (sum, q) => sum + q.xp);

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Text('Aucun quiz', style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Quiz — mode apprenant',
                style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_submitted)
              Text('Score : $_score / $_maxXp XP',
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.questions.length, (qi) {
          final q = widget.questions[qi];
          return Card(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...List.generate(q.choices.length, (ci) {
                    final selected = _answers[qi] == ci;
                    Color? border;
                    if (_submitted) {
                      if (ci == q.correctIndex) {
                        border = const Color(0xFF10B981);
                      } else if (selected) {
                        border = const Color(0xFFEF4444);
                      }
                    }
                    return InkWell(
                      onTap: _submitted
                          ? null
                          : () => setState(() => _answers[qi] = ci),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: border ?? (selected ? const Color(0xFFF5EBDA) : const Color(0xFF2A2A2A))),
                          color: selected ? const Color(0xFFF5EBDA).withValues(alpha: 0.08) : null,
                        ),
                        child: Text(q.choices[ci], style: const TextStyle(color: Colors.white70)),
                      ),
                    );
                  }),
                  if (_submitted && q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(q.explanation, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
            ),
          );
        }),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _submitted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5EBDA),
                foregroundColor: Colors.black,
              ),
              child: const Text('Valider'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _answers.clear();
                _submitted = false;
              }),
              child: const Text('Rejouer', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ],
    );
  }
}
