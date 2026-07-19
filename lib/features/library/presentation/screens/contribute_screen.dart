import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';

/// Proposition de contribution étudiant (modération avant publication).
class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _year = TextEditingController();

  DocumentType _type = DocumentType.tp;
  bool _loading = false;
  String? _error;

  static const _types = <(DocumentType, String)>[
    (DocumentType.corrige, 'TP corrigé'),
    (DocumentType.tp, 'TD / TP'),
    (DocumentType.examen, 'Examen'),
    (DocumentType.resume, 'Résumé de cours'),
    (DocumentType.supportCours, 'PDF de cours'),
    (DocumentType.pdf, 'Document gratuit'),
    (DocumentType.lien, 'Ressource libre'),
    (DocumentType.ficheRevision, 'Fiche de révision'),
  ];

  static const _pad = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = 'Connecte-toi pour contribuer.');
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Le titre est obligatoire.');
      return;
    }
    if (_url.text.trim().isEmpty) {
      setState(() => _error = 'Ajoute un lien vers le document (Drive, PDF…).');
      return;
    }
    if (user.universityId.isEmpty) {
      setState(
        () => _error =
            'Ton profil doit avoir une université. Mets à jour ton compte.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(academicRepositoryProvider).createDocument({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'doc_type': switch (_type) {
          DocumentType.supportCours => 'support_cours',
          DocumentType.resume => 'resume',
          DocumentType.pdf => 'pdf',
          DocumentType.tp => 'tp',
          DocumentType.corrige => 'corrige',
          DocumentType.examen => 'examen',
          DocumentType.lien => 'lien',
          DocumentType.ficheRevision => 'fiche_revision',
          _ => 'pdf',
        },
        'university': int.tryParse(user.universityId) ?? user.universityId,
        if (user.departmentId.isNotEmpty)
          'department':
              int.tryParse(user.departmentId) ?? user.departmentId,
        'external_url': _url.text.trim(),
        if (_year.text.trim().isNotEmpty)
          'academic_year': _year.text.trim(),
      });
      ref.invalidate(myDocumentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contribution envoyée. Statut : en cours d’examen. '
            'Tu seras notifié(e) après validation.',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkadexColors.background,
      appBar: AppBar(
        title: const Text('Proposer une contribution'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-contributions'),
            child: const Text('Mes envois'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SoftCard(
            child: Text(
              'Toute contribution passe par une modération. '
              'Après validation, tu reçois une notification avec tes points.',
              style: TextStyle(
                color: AkadexColors.inkMuted.withValues(alpha: 0.95),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Type de contenu',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  onSelected: (_) => setState(() => _type = t.$1),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Titre',
              filled: true,
              contentPadding: _pad,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              filled: true,
              contentPadding: _pad,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Lien du document (Drive, PDF, etc.)',
              filled: true,
              contentPadding: _pad,
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _year,
            decoration: const InputDecoration(
              labelText: 'Année académique (ex. 2025-2026)',
              filled: true,
              contentPadding: _pad,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AkadexColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AkadexColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AkadexColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Envoyer en modération'),
          ),
        ],
      ),
    );
  }
}

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(myDocumentsProvider);

    return Scaffold(
      backgroundColor: AkadexColors.background,
      appBar: AppBar(
        title: const Text('Mes contributions'),
        actions: [
          IconButton(
            onPressed: () => context.push('/contribute'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aucune contribution pour l’instant.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/contribute'),
                      child: const Text('Proposer un document'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myDocumentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = docs[i];
                return SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ModerationChip(status: d.moderationStatus),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.type.label,
                        style: const TextStyle(
                          color: AkadexColors.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (d.moderationStatus == 'approved' &&
                          d.pointsAwarded > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Félicitations ! +${d.pointsAwarded} points crédités.',
                          style: const TextStyle(
                            color: AkadexColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (d.moderationStatus == 'rejected' &&
                          d.rejectionReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Motif : ${d.rejectionReason}',
                          style: const TextStyle(color: AkadexColors.danger),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
