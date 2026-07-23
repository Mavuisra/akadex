import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../learn/data/learn_domains.dart';

/// Publication d’un cours complet côté enseignant (tous les champs d’abord).
class ProfessorCreateCourseScreen extends ConsumerStatefulWidget {
  const ProfessorCreateCourseScreen({super.key});

  @override
  ConsumerState<ProfessorCreateCourseScreen> createState() =>
      _ProfessorCreateCourseScreenState();
}

class _ProfessorCreateCourseScreenState
    extends ConsumerState<ProfessorCreateCourseScreen> {
  final _title = TextEditingController();
  final _code = TextEditingController();
  final _credits = TextEditingController();
  final _hours = TextEditingController();
  final _description = TextEditingController();
  final _objectives = TextEditingController();
  final _skills = TextEditingController();
  final _prerequisites = TextEditingController();
  final _coverUrl = TextEditingController();

  static const _cycles = <String>[
    'L1',
    'L2',
    'L3',
    'Master 1',
    'Master 2',
  ];
  static const _semesters = <String>['S1', 'S2'];
  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  String? _cycle;
  String? _semester;
  final Set<String> _domainSlugs = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      final promo = (user?.promotion ?? user?.level ?? '').trim();
      if (promo.isEmpty) return;
      for (final c in _cycles) {
        if (promo.toLowerCase().contains(c.toLowerCase()) ||
            promo == c.replaceAll(' ', '')) {
          setState(() => _cycle = c);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _code.dispose();
    _credits.dispose();
    _hours.dispose();
    _description.dispose();
    _objectives.dispose();
    _skills.dispose();
    _prerequisites.dispose();
    _coverUrl.dispose();
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

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AkadexColors.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AkadexColors.inkMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !user.usesTeacherShell) {
      setState(() => _error = 'Réservé aux enseignants.');
      return;
    }
    if (user.departmentId.isEmpty) {
      setState(
        () => _error =
            'Complète ton département dans le profil avant de publier un cours.',
      );
      return;
    }
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'L’intitulé du cours est obligatoire.');
      return;
    }
    if (_cycle == null || _cycle!.isEmpty) {
      setState(() => _error = 'Choisis le cycle (L1, L2, L3…).');
      return;
    }
    if (_semester == null || _semester!.isEmpty) {
      setState(() => _error = 'Choisis le semestre (S1 ou S2).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hours = int.tryParse(_hours.text.trim()) ?? 0;
      final credits = int.tryParse(_credits.text.trim()) ?? 0;
      final course = await ref.read(academicRepositoryProvider).createCourse({
        'title': _title.text.trim(),
        if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        if (_objectives.text.trim().isNotEmpty)
          'objectives': _objectives.text.trim(),
        if (_skills.text.trim().isNotEmpty) 'skills': _skills.text.trim(),
        if (_prerequisites.text.trim().isNotEmpty)
          'prerequisites': _prerequisites.text.trim(),
        if (_coverUrl.text.trim().isNotEmpty)
          'cover_url': _coverUrl.text.trim(),
        if (hours > 0) 'estimated_hours': hours,
        if (credits > 0) 'credits': credits,
        'semester': _cycle,
        'level_label': _semester,
        'teacher_name': user.name,
        if (_domainSlugs.isNotEmpty) 'domain_slugs': _domainSlugs.toList(),
      });
      ref.invalidate(coursesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cours « ${course.title} » publié.'),
        ),
      );
      context.push('/teacher-publish');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Publier un cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
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
                            'Renseigne d’abord le cours complet. '
                            'Ensuite tu pourras ajouter modules et leçons.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AkadexColors.inkMuted
                                  .withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                          _sectionTitle('1. Identification'),
                          _softField(
                            child: TextField(
                              controller: _title,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                'Intitulé du cours *',
                                icon: Icons.title_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _code,
                              textCapitalization:
                                  TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                'Code UE (ex. INFO301)',
                                icon: Icons.qr_code_2_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _softField(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _cycle,
                                    decoration: _dec('Cycle *'),
                                    items: [
                                      for (final c in _cycles)
                                        DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _cycle = v),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _softField(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _semester,
                                    decoration: _dec('Semestre *'),
                                    items: [
                                      for (final s in _semesters)
                                        DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _semester = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _softField(
                                  child: TextField(
                                    controller: _credits,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _dec(
                                      'Crédits',
                                      icon: Icons.toll_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _softField(
                                  child: TextField(
                                    controller: _hours,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _dec(
                                      'Volume (h)',
                                      icon: Icons.schedule_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _sectionTitle(
                            '2. Contenu pédagogique',
                            subtitle:
                                'Description, objectifs, compétences et prérequis.',
                          ),
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
                              controller: _objectives,
                              maxLines: 3,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: _dec(
                                'Objectifs d’apprentissage',
                                icon: Icons.flag_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _skills,
                              maxLines: 3,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: _dec(
                                'Compétences visées',
                                icon: Icons.psychology_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _prerequisites,
                              maxLines: 2,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: _dec(
                                'Prérequis',
                                icon: Icons.checklist_outlined,
                              ),
                            ),
                          ),
                          _sectionTitle(
                            '3. Domaine Apprendre',
                            subtitle:
                                'Lien vers les ressources vidéo du domaine '
                                '(indépendant du programme de promo).',
                          ),
                          SoftCard(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in LearnDomains.all)
                                  FilterChip(
                                    label: Text(d.shortLabel),
                                    selected: _domainSlugs.contains(d.id),
                                    showCheckmark: true,
                                    selectedColor: AkadexColors.primary,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _domainSlugs.contains(d.id)
                                          ? Colors.white
                                          : AkadexColors.ink,
                                    ),
                                    side: BorderSide(
                                      color: _domainSlugs.contains(d.id)
                                          ? AkadexColors.primary
                                          : AkadexColors.inkMuted
                                              .withValues(alpha: 0.25),
                                    ),
                                    backgroundColor: Colors.white,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _domainSlugs.add(d.id);
                                        } else {
                                          _domainSlugs.remove(d.id);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          _sectionTitle('4. Visuel (optionnel)'),
                          _softField(
                            child: TextField(
                              controller: _coverUrl,
                              keyboardType: TextInputType.url,
                              decoration: _dec(
                                'URL de couverture',
                                icon: Icons.image_outlined,
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
                              style: FilledButton.styleFrom(
                                backgroundColor: AkadexColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Publier le cours'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => context.push('/teacher-publish'),
                            child: const Text(
                              'J’ai déjà un cours — ajouter une leçon',
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
