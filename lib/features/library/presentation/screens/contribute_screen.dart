import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
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
    (DocumentType.corrige, 'Examen / TP corrigé'),
    (DocumentType.tp, 'TD / TP'),
    (DocumentType.examen, 'Examen'),
    (DocumentType.resume, 'Résumé de cours'),
    (DocumentType.supportCours, 'PDF de cours'),
    (DocumentType.tfc, 'TFC'),
    (DocumentType.projetTutore, 'Projet tuteuré'),
    (DocumentType.rapport, 'Rapport de stage'),
    (DocumentType.memoire, 'Mémoire'),
    (DocumentType.projet, 'Projet'),
    (DocumentType.autre, 'Autre travail académique'),
    (DocumentType.pdf, 'Document gratuit'),
    (DocumentType.lien, 'Ressource libre'),
    (DocumentType.ficheRevision, 'Fiche de révision'),
  ];

  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    _year.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: _fieldPad,
    );
  }

  Widget _softField({required Widget child}) {
    return SoftCard(padding: EdgeInsets.zero, child: child);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AkadexColors.ink,
        ),
      ),
    );
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
        'doc_type': documentTypeToApi(_type) ?? 'pdf',
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
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Proposer une contribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/my-contributions'),
                      child: const Text('Mes envois'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Toute contribution passe par une modération. '
                            'Après validation, tu reçois une notification avec tes points.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AkadexColors.inkMuted
                                  .withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SoftCard(
                            onTap: () => context.push('/contribute/course'),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AkadexColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_outlined,
                                    color: AkadexColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Proposer un cours universitaire',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AkadexColors.ink,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'UE, cycle, semestre — validation admin',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AkadexColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AkadexColors.inkMuted
                                      .withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('1. Type de contenu'),
                          SoftCard(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final t in _types)
                                  FilterChip(
                                    label: Text(t.$2),
                                    selected: _type == t.$1,
                                    onSelected: (_) =>
                                        setState(() => _type = t.$1),
                                    showCheckmark: true,
                                    selectedColor: AkadexColors.primary,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _type == t.$1
                                          ? Colors.white
                                          : AkadexColors.ink,
                                    ),
                                    side: BorderSide(
                                      color: _type == t.$1
                                          ? AkadexColors.primary
                                          : AkadexColors.inkMuted
                                              .withValues(alpha: 0.25),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _sectionTitle('2. Document'),
                          _softField(
                            child: TextField(
                              controller: _title,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                'Titre *',
                                icon: Icons.title_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _description,
                              maxLines: 4,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: _dec(
                                'Description',
                                icon: Icons.notes_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _url,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                'Lien du document (Drive, PDF…)',
                                icon: Icons.link_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _year,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _loading ? null : _submit(),
                              decoration: _dec(
                                'Année académique (ex. 2025-2026)',
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AkadexColors.danger
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AkadexColors.danger,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AkadexColors.danger,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
