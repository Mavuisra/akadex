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

/// Proposition collaborative d’un cours — style formulaire d’inscription.
class SuggestCourseScreen extends ConsumerStatefulWidget {
  const SuggestCourseScreen({super.key});

  @override
  ConsumerState<SuggestCourseScreen> createState() =>
      _SuggestCourseScreenState();
}

class _SuggestCourseScreenState extends ConsumerState<SuggestCourseScreen> {
  final _title = TextEditingController();
  final _code = TextEditingController();
  final _credits = TextEditingController();
  final _hours = TextEditingController();
  final _teacher = TextEditingController();
  final _description = TextEditingController();
  final _objectives = TextEditingController();
  final _prerequisites = TextEditingController();

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
    _teacher.dispose();
    _description.dispose();
    _objectives.dispose();
    _prerequisites.dispose();
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
      setState(() => _error = 'Connecte-toi pour proposer un cours.');
      return;
    }
    if (user.departmentId.isEmpty) {
      setState(
        () => _error =
            'Complète ton département dans le profil avant de proposer un cours.',
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
      await ref.read(academicRepositoryProvider).createCourse({
        'title': _title.text.trim(),
        if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        if (_objectives.text.trim().isNotEmpty)
          'objectives': _objectives.text.trim(),
        if (_prerequisites.text.trim().isNotEmpty)
          'prerequisites': _prerequisites.text.trim(),
        if (_teacher.text.trim().isNotEmpty)
          'teacher_name': _teacher.text.trim(),
        if (hours > 0) 'estimated_hours': hours,
        if (credits > 0) 'credits': credits,
        'semester': _cycle,
        'level_label': _semester,
      });
      ref.invalidate(coursesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cours proposé — visible avec le badge « En attente de validation ».',
          ),
        ),
      );
      context.pop();
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
                        'Proposer un cours',
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
                            'Comme à l’inscription : renseigne le cycle, le semestre, '
                            'les crédits et le cours. Validation admin ensuite.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AkadexColors.inkMuted
                                  .withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _sectionTitle('1. Parcours'),
                          _softField(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('cycle-$_cycle'),
                              initialValue: _cycle,
                              decoration: _dec(
                                'Cycle *',
                                icon: Icons.layers_outlined,
                              ),
                              items: [
                                for (final c in _cycles)
                                  DropdownMenuItem(value: c, child: Text(c)),
                              ],
                              onChanged: (v) => setState(() => _cycle = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('sem-$_semester'),
                              initialValue: _semester,
                              decoration: _dec(
                                'Semestre *',
                                icon: Icons.calendar_view_month_outlined,
                              ),
                              items: [
                                for (final s in _semesters)
                                  DropdownMenuItem(value: s, child: Text(s)),
                              ],
                              onChanged: (v) => setState(() => _semester = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _credits,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dec(
                                'Crédits UE',
                                icon: Icons.stars_outlined,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          const SizedBox(height: 18),
                          _sectionTitle('2. Cours'),
                          _softField(
                            child: TextField(
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _dec(
                                'Intitulé du cours *',
                                icon: Icons.menu_book_outlined,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _code,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _dec(
                                'Code UE (ex. INF211)',
                                icon: Icons.tag_outlined,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _hours,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dec(
                                'Volume horaire (heures)',
                                icon: Icons.schedule_outlined,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _softField(
                            child: TextField(
                              controller: _teacher,
                              textCapitalization: TextCapitalization.words,
                              decoration: _dec(
                                'Titulaire du cours',
                                icon: Icons.person_outline_rounded,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          const SizedBox(height: 18),
                          _sectionTitle('3. Détails pédagogiques'),
                          _softField(
                            child: TextField(
                              controller: _description,
                              maxLines: 3,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: _dec(
                                'Description du cours',
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

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            SoftCard(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AkadexColors.danger,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Soumettre le cours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => context.push('/contribute'),
                            child: const Text('Plutôt ajouter un document ?'),
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
