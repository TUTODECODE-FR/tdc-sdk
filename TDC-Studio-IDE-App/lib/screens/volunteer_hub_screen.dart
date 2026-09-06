// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';

import '../models/volunteer_task.dart';
import '../services/community_settings_service.dart';
import '../services/gitlab_volunteer_service.dart';
import '../services/open_url.dart';
import 'community_settings_screen.dart';

/// Hub d'entraide : tableau en lecture, propositions, bugs.
class VolunteerHubScreen extends StatefulWidget {
  const VolunteerHubScreen({super.key});

  @override
  State<VolunteerHubScreen> createState() => _VolunteerHubScreenState();
}

class _VolunteerHubScreenState extends State<VolunteerHubScreen> {
  List<VolunteerTask> _tasks = [];
  bool _loading = true;
  bool _fromNetwork = false;
  String? _banner;
  String? _filter; // null = tous
  bool _hasPat = false;

  static const _beige = Color(0xFFF5EBDA);
  static const _gold = Color(0xFFD4AF37);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final pat = await CommunitySettingsService.getPat();
    final result = await GitlabVolunteerService.loadBoard();
    if (!mounted) return;
    setState(() {
      _hasPat = pat != null;
      _tasks = result.tasks;
      _fromNetwork = result.fromNetwork;
      _banner = result.error;
      _loading = false;
    });
  }

  List<VolunteerTask> get _filtered {
    if (_filter == null) return _tasks;
    return _tasks.where((t) {
      switch (_filter) {
        case 'libre':
          return t.isLibre;
        case 'cours':
          return t.isEnCours;
        case 'fait':
          return t.isFait;
        case 'bug':
          return t.isBug;
        case 'idea':
          return t.isIdea && !t.isBug;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _openCommunitySettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunitySettingsScreen()),
    );
    if (mounted) await _reload();
  }

  Future<void> _needPatDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Jeton GitLab requis',
          style: TextStyle(color: _beige),
        ),
        content: const Text(
          'Pour proposer une idée ou signaler un bug, ajoute ton jeton '
          'GitLab (scope api) dans Paramètres → Communauté.\n\n'
          'La lecture du tableau reste possible sans jeton.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openCommunitySettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _beige,
              foregroundColor: Colors.black,
            ),
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm({
    required String title,
    required String submitLabel,
    required Future<GitlabVolunteerResult> Function(String t, String d) send,
  }) async {
    // Toujours relire le cache (évite un Hub stale après Enregistrer / Vérifier).
    final pat = await CommunitySettingsService.getPat();
    _hasPat = pat != null;
    if (!_hasPat) {
      await _needPatDialog();
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text(title, style: const TextStyle(color: _beige)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Dis-nous en plus',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _border),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _beige,
              foregroundColor: Colors.black,
            ),
            child: Text(submitLabel),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final t = titleCtrl.text.trim();
    final d = descCtrl.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un titre.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _beige),
      ),
    );
    final result = await send(t, d);
    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        action: result.webUrl != null
            ? SnackBarAction(
                label: 'Voir',
                onPressed: () => openExternalUrl(result.webUrl!),
              )
            : null,
      ),
    );
  }

  Future<void> _prepareClaim(VolunteerTask task) async {
    final iid = task.issueIid;
    if (iid == null) return;
    final username = await CommunitySettingsService.getUsername();
    final instructions = CommunitySettingsService.claimGitInstructions(
      issueIid: iid,
      username: username,
    );
    final mrUrl = await CommunitySettingsService.claimMergeRequestUrl(
      issueIid: iid,
      username: username,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          'Prendre ${task.id}',
          style: const TextStyle(color: _beige),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1. Crée la branche + le marqueur volunteer/claims '
                  '(commandes ci-dessous).\n'
                  '2. Ouvre la MR avec le titre exact « prendre #N ».\n'
                  '3. Après validation/merge, la CI t’assigne l’issue '
                  '(label en-cours). Collision = pipeline rouge.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                SelectableText(
                  instructions,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await openExternalUrl(mrUrl);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _beige,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.merge_type, size: 18),
            label: const Text('Ouvrir MR GitLab'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _beige,
        title: const Text('Hub Communauté'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Réglages',
            onPressed: _openCommunitySettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHero(),
          _buildActions(),
          _buildFilters(),
          if (_banner != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                _banner!,
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _beige))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Rien ici pour l\'instant — essaie un autre filtre.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _TaskCard(
                          task: _filtered[i],
                          onOpenLink: () async {
                            final link = _filtered[i].link;
                            if (link.isNotEmpty &&
                                link != '—' &&
                                link.startsWith('http')) {
                              await openExternalUrl(link);
                            } else {
                              await openExternalUrl(
                                await CommunitySettingsService.boardWebUrl(),
                              );
                            }
                          },
                          onPrepareClaim: _filtered[i].isLibre &&
                                  _filtered[i].issueIid != null
                              ? () => _prepareClaim(_filtered[i])
                              : null,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _beige.withValues(alpha: 0.12),
            _gold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _beige.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entraide TUTODECODE',
            style: TextStyle(
              color: _beige,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fromNetwork
                ? 'Liste live des issues GitLab (label benevolat). '
                    'Propose, prends une tâche (MR « prendre #N »), '
                    'puis code — voir CONTRIBUTING / VOLUNTEER_BOARD.'
                : 'Aperçu hors ligne. Les issues live apparaîtront dès que '
                    'GitLab est joignable.',
            style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _showForm(
              title: 'Proposer une idée',
              submitLabel: 'Envoyer',
              send: (t, d) => GitlabVolunteerService.proposeIdea(
                title: t,
                description: d,
              ),
            ),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Proposer une idée'),
            style: FilledButton.styleFrom(
              backgroundColor: _beige,
              foregroundColor: Colors.black,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showForm(
              title: 'Un problème ?',
              submitLabel: 'Signaler',
              send: (t, d) => GitlabVolunteerService.reportBug(
                title: t,
                description: d,
              ),
            ),
            icon: const Icon(Icons.report_problem_outlined, size: 18),
            label: const Text('Un problème ?'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
              side: const BorderSide(color: Color(0xFFF59E0B)),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await openExternalUrl(
                await CommunitySettingsService.boardWebUrl(),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white54),
            label: const Text(
              'Voir les issues sur GitLab',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, String? value, Color color) {
      final selected = _filter == value;
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: color.withValues(alpha: 0.25),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: selected ? color : Colors.white70,
          fontSize: 12,
        ),
        side: BorderSide(color: selected ? color : _border),
        backgroundColor: _surface,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(
        spacing: 8,
        children: [
          chip('Tout', null, _beige),
          chip('Ouvertes', 'libre', const Color(0xFF10B981)),
          chip('En cours', 'cours', _gold),
          chip('Idées', 'idea', _beige),
          chip('Bugs', 'bug', const Color(0xFFF59E0B)),
          chip('Fermées', 'fait', Colors.white54),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final VolunteerTask task;
  final VoidCallback onOpenLink;
  final VoidCallback? onPrepareClaim;

  const _TaskCard({
    required this.task,
    required this.onOpenLink,
    this.onPrepareClaim,
  });

  static const _beige = Color(0xFFF5EBDA);
  static const _gold = Color(0xFFD4AF37);

  Color get _statusColor {
    if (task.isLibre) return const Color(0xFF10B981);
    if (task.isEnCours) return _gold;
    if (task.isFait) return Colors.white54;
    if (task.isBloque) return const Color(0xFFEF4444);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isLibre
              ? _beige.withValues(alpha: 0.35)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                task.id,
                style: const TextStyle(
                  color: _beige,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(color: _statusColor, fontSize: 11),
                ),
              ),
              if (task.priority.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  task.priority,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
              const Spacer(),
              if (!task.isLibre &&
                  task.takenBy.isNotEmpty &&
                  task.takenBy != '—')
                Text(
                  task.takenBy,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
            ),
          ],
          if (task.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Compétences : ${task.skills}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onOpenLink,
                icon: const Icon(Icons.open_in_new, size: 16, color: _beige),
                label: const Text(
                  'Voir sur GitLab',
                  style: TextStyle(color: _beige),
                ),
              ),
              if (onPrepareClaim != null) ...[
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onPrepareClaim,
                  icon: const Icon(Icons.handshake_outlined, size: 16, color: _gold),
                  label: const Text(
                    'Préparer ma MR prendre',
                    style: TextStyle(color: _gold),
                  ),
                ),
              ],
              const Spacer(),
              if (task.link.isNotEmpty &&
                  task.link != '—' &&
                  task.link.startsWith('http'))
                IconButton(
                  tooltip: 'Ouvrir le lien',
                  onPressed: onOpenLink,
                  icon: const Icon(Icons.link, size: 18, color: Colors.white38),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
