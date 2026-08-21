// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio App — Onboarding pour traducteurs / développeurs
// ============================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String body;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _pages = [
  OnboardingPage(
    icon: Icons.handshake,
    title: 'Bienvenue dans TDC Studio App',
    body: 'Cet outil est conçu pour les bénévoles qui traduisent ou enrichissent l\'application T2DECODE.\n\n'
        'Vous n\'avez pas besoin de coder : tout se fait en éditant des fichiers au format .tdc, le langage pédagogique de TUTODECODE.',
  ),
  OnboardingPage(
    icon: Icons.terminal,
    title: 'Onglet Cheat Sheets',
    body: 'Ajoutez et modifiez les commandes techniques.\n\n'
        'Chaque entrée contient : la commande, sa description, une explication pédagogique et le niveau de danger.\n\n'
        'Cliquez sur « + Ajouter une commande » pour commencer.',
  ),
  OnboardingPage(
    icon: Icons.language,
    title: 'Onglet Locales UI',
    body: 'Traduisez l\'interface utilisateur de l\'app.\n\n'
        'Sélectionnez la langue cible (en, es, de, ar, zh…) et remplissez les champs à droite.\n\n'
        'Les clés (menu.home, home.banner.title, etc.) ne doivent pas être modifiées : seule la valeur est traduite.',
  ),
  OnboardingPage(
    icon: Icons.folder_open,
    title: 'Exporter vers T2DECODE',
    body: 'Une fois vos modifications terminées, allez dans l\'onglet Export.\n\n'
        'Cliquez sur « Exporter dans le dossier T2DECODE/assets » et choisissez le dossier assets du projet T2DECODE.\n\n'
        'Les fichiers cheat_sheets.tdc et locale_<langue>.tdc seront écrits directement.',
  ),
  OnboardingPage(
    icon: Icons.merge_type,
    title: 'Proposer vos modifications',
    body: 'Après export, créez une branche Git et ouvrez une Merge Request sur GitLab.\n\n'
        'La CI valide automatiquement la syntaxe .tdc.\n\n'
        'Un seul fichier par langue = une MR plus facile à relire.',
  ),
];

class TdcOnboardingDialog extends StatefulWidget {
  const TdcOnboardingDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool('onboarding_hidden') ?? false;
    if (hidden) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TdcOnboardingDialog(),
    );
  }

  @override
  State<TdcOnboardingDialog> createState() => _TdcOnboardingDialogState();
}

class _TdcOnboardingDialogState extends State<TdcOnboardingDialog> {
  int _index = 0;
  bool _dontShowAgain = false;

  void _next() {
    if (_index < _pages.length - 1) {
      setState(() => _index++);
    } else {
      _close();
    }
  }

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  Future<void> _close() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_hidden', true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(page.icon, color: const Color(0xFFF5EBDA), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    page.title,
                    style: const TextStyle(
                      color: Color(0xFFF5EBDA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              page.body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? const Color(0xFFF5EBDA)
                        : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                  activeColor: const Color(0xFFF5EBDA),
                  checkColor: Colors.black,
                ),
                const Text(
                  'Ne plus me montrer',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                if (_index > 0)
                  TextButton(
                    onPressed: _previous,
                    child: const Text(
                      'Précédent',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EBDA),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(_index == _pages.length - 1 ? 'Terminer' : 'Suivant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
