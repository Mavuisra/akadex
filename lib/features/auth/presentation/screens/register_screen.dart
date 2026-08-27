import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/auth_entry_style.dart';
import '../../../../core/widgets/academic_autocomplete.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  /// 0 identité · 1 compte · 2 parcours
  int _step = 0;

  final _lastName = TextEditingController();
  final _postnom = TextEditingController();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _matricule = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  String? _universityId;
  String? _universityName;
  String? _facultyId;
  String? _facultyName;
  String? _departmentId;
  String? _departmentName;
  String? _promotionId;
  String? _promotionName;

  bool _obscure = true;
  bool _loading = false;
  bool _acceptedTerms = false;
  String? _error;

  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(universitiesProvider);
    });
  }

  @override
  void dispose() {
    _lastName.dispose();
    _postnom.dispose();
    _firstName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _matricule.dispose();
    super.dispose();
  }

  String get _stepTitle => switch (_step) {
        0 => 'Qui es-tu ?',
        1 => 'Ton compte',
        _ => 'Ton parcours',
      };

  String get _stepSubtitle => switch (_step) {
        0 => 'Profil et identité',
        1 => 'Email et mot de passe',
        _ => 'Université et filière',
      };

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_lastName.text.trim().isEmpty) return 'Le nom est obligatoire.';
        if (_postnom.text.trim().isEmpty) return 'Le postnom est obligatoire.';
        if (_firstName.text.trim().isEmpty) return 'Le prénom est obligatoire.';
        if (_gender == null || _gender!.isEmpty) {
          return 'Le sexe est obligatoire.';
        }
        if (_birthDate == null) {
          return 'La date de naissance est obligatoire.';
        }
        return null;
      case 1:
        if (_email.text.trim().isEmpty) return "L'email est obligatoire.";
        if (_phone.text.trim().isEmpty) return 'Le téléphone est obligatoire.';
        if (_password.text.length < 8) {
          return 'Le mot de passe doit contenir au moins 8 caractères.';
        }
        return null;
      case 2:
        if (!_acceptedTerms) {
          return 'Tu dois accepter les conditions d’utilisation.';
        }
        if (_universityId == null || _universityId!.isEmpty) {
          return "L'université est obligatoire.";
        }
        if (_facultyId == null || _facultyId!.isEmpty) {
          return 'La faculté est obligatoire.';
        }
        if (_departmentId == null || _departmentId!.isEmpty) {
          return 'Le département est obligatoire.';
        }
        if (_promotionId == null || _promotionId!.isEmpty) {
          return 'La promotion est obligatoire.';
        }
        if (_matricule.text.trim().isEmpty) {
          return 'Le matricule est obligatoire.';
        }
        return null;
      default:
        return null;
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _error = null;
      });
    } else {
      context.go('/login');
    }
  }

  void _goNext() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (_step < _totalSteps - 1) {
      final next = _step + 1;
      // Prefetch catalogue avant d’arriver sur l’étape parcours.
      if (next >= 1) {
        ref.read(universitiesProvider);
      }
      setState(() {
        _step = next;
        _error = null;
      });
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    final err = _validateStep(3);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    final username =
        email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    await ref.read(authStateProvider.notifier).register(
          email: email,
          username: username,
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          postnom: _postnom.text.trim(),
          phone: _phone.text.trim(),
          role: 'student',
          gender: _gender ?? '',
          birthDate: _birthDate == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_birthDate!),
          matricule: _matricule.text.trim(),
          university: _universityId,
          faculty: _facultyId,
          department: _departmentId,
          promotion: _promotionId,
        );
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.hasError) {
      setState(() {
        _error = apiErrorMessage(auth.error!);
        _loading = false;
      });
      return;
    }
    if (auth.valueOrNull != null) {
      context.go(auth.valueOrNull!.homeRoute);
    } else {
      setState(() {
        _error = 'Inscription impossible.';
        _loading = false;
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  InputDecoration _field(String hint, {Widget? suffix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AuthEntryStyle.fieldDecoration(
      hint: hint,
      isDark: isDark,
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _totalSteps - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AuthEntryStyle.background(isDark);
    final titleColor = AuthEntryStyle.title(isDark);
    final muted = AuthEntryStyle.muted(isDark);
    final primary = AuthEntryStyle.primary(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _loading ? null : _goBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: titleColor,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_step == 0) ...[
                          const Center(
                            child: AkadexLogo(size: 72, borderRadius: 36),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          _stepTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _stepSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StepProgress(
                          current: _step,
                          total: _totalSteps,
                          activeColor: primary,
                          idleColor: muted.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            final offset = Tween<Offset>(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero,
                            ).animate(anim);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: offset,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey('step-$_step'),
                            child: switch (_step) {
                              0 => _buildIdentityStep(
                                  titleColor: titleColor,
                                  muted: muted,
                                ),
                              1 => _buildAccountStep(
                                  titleColor: titleColor,
                                  muted: muted,
                                ),
                              _ => _buildAcademicStep(
                                  titleColor: titleColor,
                                  muted: muted,
                                  primary: primary,
                                ),
                            },
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AkadexColors.danger,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _goNext,
                            style: AuthEntryStyle.primaryButton(isDark),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isLast ? "S'inscrire" : 'Continuer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    if (_step == 0)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          style: AuthEntryStyle.outlineButton(isDark),
                          child: const Text('Se connecter'),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _loading ? null : _goBack,
                        style: TextButton.styleFrom(
                          foregroundColor: titleColor,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('Étape précédente'),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      'Akadex',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityStep({
    required Color titleColor,
    required Color muted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _lastName,
          style: TextStyle(color: titleColor, fontSize: 16),
          decoration: _field('Nom'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _postnom,
          style: TextStyle(color: titleColor, fontSize: 16),
          decoration: _field('Postnom'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _firstName,
          style: TextStyle(color: titleColor, fontSize: 16),
          decoration: _field('Prénom'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('gender-$_gender'),
          initialValue: _gender,
          dropdownColor: AuthEntryStyle.fieldFill(isDark),
          style: TextStyle(color: titleColor, fontSize: 16),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          decoration: _field('Sexe'),
          items: [
            DropdownMenuItem(
              value: 'M',
              child: Text('Masculin', style: TextStyle(color: titleColor)),
            ),
            DropdownMenuItem(
              value: 'F',
              child: Text('Féminin', style: TextStyle(color: titleColor)),
            ),
          ],
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _field('Date de naissance'),
              child: Text(
                _birthDate == null
                    ? 'Sélectionner'
                    : DateFormat('dd/MM/yyyy').format(_birthDate!),
                style: TextStyle(
                  color: _birthDate == null ? muted : titleColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStep({
    required Color titleColor,
    required Color muted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          style: TextStyle(color: titleColor, fontSize: 16),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _field('E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          style: TextStyle(color: titleColor, fontSize: 16),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: _field('Téléphone'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          style: TextStyle(color: titleColor, fontSize: 16),
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          decoration: _field(
            'Mot de passe',
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: muted,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Au moins 8 caractères',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget _catalogPlaceholder(String label, {required Color muted}) {
    return TextField(
      enabled: false,
      style: TextStyle(color: muted, fontSize: 16),
      decoration: _field(label),
    );
  }

  Widget _buildAcademicStep({
    required Color titleColor,
    required Color muted,
    required Color primary,
  }) {
    final unisAsync = ref.watch(universitiesProvider);
    final hasUni = _universityId != null && _universityId!.isNotEmpty;
    final hasFac = _facultyId != null && _facultyId!.isNotEmpty;
    final hasDept = _departmentId != null && _departmentId!.isNotEmpty;
    final facultiesAsync = hasUni
        ? ref.watch(facultiesProvider(_universityId))
        : const AsyncValue<List<FacultyItem>>.data([]);
    final deptsAsync = hasFac
        ? ref.watch(facultyDepartmentsProvider(_facultyId))
        : const AsyncValue<List<DepartmentItem>>.data([]);
    final promosAsync = hasDept
        ? ref.watch(promotionsProvider(_departmentId))
        : const AsyncValue<List<PromotionItem>>.data([]);
    Object? catalogError;
    if (unisAsync.hasError) {
      catalogError = unisAsync.error;
    } else if (hasUni && facultiesAsync.hasError) {
      catalogError = facultiesAsync.error;
    } else if (hasUni && deptsAsync.hasError) {
      catalogError = deptsAsync.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (catalogError != null) ...[
          Text(
            apiErrorMessage(catalogError),
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(universitiesProvider);
              if (hasUni) {
                ref.invalidate(facultiesProvider(_universityId));
                ref.invalidate(departmentsProvider(_universityId));
              }
              if (hasFac) {
                ref.invalidate(facultyDepartmentsProvider(_facultyId));
              }
              if (hasDept) {
                ref.invalidate(promotionsProvider(_departmentId));
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: AuthEntryStyle.outlineButton(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          const SizedBox(height: 12),
        ],
        unisAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                minHeight: 2,
                color: primary,
                backgroundColor: muted.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              _catalogPlaceholder(
                'Université (chargement…)',
                muted: muted,
              ),
            ],
          ),
          error: (_, _) => _catalogPlaceholder(
            'Université (indisponible — réessayer)',
            muted: muted,
          ),
          data: (unis) => AcademicAutocomplete(
            key: ValueKey('uni-$_universityId'),
            label: 'Université',
            authOutline: true,
            selectedId: _universityId,
            selectedName: _universityName,
            options: [
              for (final u in unis) AcademicOption(id: u.id, name: u.name),
            ],
            onSelected: (id, name) => setState(() {
              _universityId = id.isEmpty ? null : id;
              _universityName = name;
              _facultyId = null;
              _facultyName = null;
              _departmentId = null;
              _departmentName = null;
              _promotionId = null;
              _promotionName = null;
            }),
            onCreateCustom: (name) async {
              final id = await ref
                  .read(academicRepositoryProvider)
                  .suggestUniversity(name);
              ref.invalidate(universitiesProvider);
              return id;
            },
          ),
        ),
        const SizedBox(height: 12),
        if (!hasUni)
          _catalogPlaceholder(
            'Faculté (choisis d’abord l’université)',
            muted: muted,
          )
        else
          facultiesAsync.when(
            loading: () => _catalogPlaceholder(
              'Faculté (chargement…)',
              muted: muted,
            ),
            error: (_, _) => _catalogPlaceholder(
              'Faculté (indisponible — réessayer)',
              muted: muted,
            ),
            data: (facs) => AcademicAutocomplete(
              key: ValueKey('fac-$_universityId-$_facultyId'),
              label: 'Faculté',
              authOutline: true,
              selectedId: _facultyId,
              selectedName: _facultyName,
              enabled: true,
              options: [
                for (final f in facs) AcademicOption(id: f.id, name: f.name),
              ],
              onSelected: (id, name) => setState(() {
                _facultyId = id.isEmpty ? null : id;
                _facultyName = name;
                _departmentId = null;
                _departmentName = null;
                _promotionId = null;
                _promotionName = null;
              }),
              onCreateCustom: (name) async {
                final id = await ref
                    .read(academicRepositoryProvider)
                    .suggestFaculty(
                      name: name,
                      universityId: _universityId!,
                    );
                ref.invalidate(facultiesProvider(_universityId));
                return id;
              },
            ),
          ),
        const SizedBox(height: 12),
        if (!hasUni)
          _catalogPlaceholder(
            'Département (choisis d’abord l’université)',
            muted: muted,
          )
        else if (!hasFac)
          _catalogPlaceholder(
            'Département (choisis d’abord la faculté)',
            muted: muted,
          )
        else
          deptsAsync.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  minHeight: 2,
                  color: primary,
                  backgroundColor: muted.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 8),
                _catalogPlaceholder(
                  'Département (chargement…)',
                  muted: muted,
                ),
              ],
            ),
            error: (_, _) => _catalogPlaceholder(
              'Département (indisponible — réessayer)',
              muted: muted,
            ),
            data: (all) {
              final uniId = _universityId;
              final facId = _facultyId;
              final filtered = all.where((d) {
                if (uniId != null &&
                    d.universityId != uniId &&
                    d.universityId != 'null') {
                  return false;
                }
                if (facId != null &&
                    d.facultyId.isNotEmpty &&
                    d.facultyId != facId) {
                  return false;
                }
                return true;
              }).toList();
              return AcademicAutocomplete(
                key: ValueKey(
                  'dept-$_universityId-$_facultyId-$_departmentId',
                ),
                label: 'Département',
                authOutline: true,
                selectedId: _departmentId,
                selectedName: _departmentName,
                options: [
                  for (final d in filtered)
                    AcademicOption(id: d.id, name: d.name),
                ],
                onSelected: (id, name) => setState(() {
                  _departmentId = id.isEmpty ? null : id;
                  _departmentName = name;
                  _promotionId = null;
                  _promotionName = null;
                }),
                onCreateCustom: (name) async {
                  final id = await ref
                      .read(academicRepositoryProvider)
                      .suggestDepartment(
                        name: name,
                        facultyId: _facultyId,
                        universityId: _universityId,
                      );
                  ref.invalidate(departmentsProvider(_universityId));
                  ref.invalidate(facultyDepartmentsProvider(_facultyId));
                  return id;
                },
              );
            },
          ),
        const SizedBox(height: 12),
        if (!hasDept)
          _catalogPlaceholder(
            'Promotion (choisis d’abord le département)',
            muted: muted,
          )
        else
          promosAsync.when(
            loading: () => _catalogPlaceholder(
              'Promotion (chargement…)',
              muted: muted,
            ),
            error: (_, _) => _catalogPlaceholder(
              'Promotion (indisponible — réessayer)',
              muted: muted,
            ),
            data: (promos) => AcademicAutocomplete(
              key: ValueKey('promo-$_departmentId-$_promotionId'),
              label: 'Promotion',
              authOutline: true,
              selectedId: _promotionId,
              selectedName: _promotionName,
              enabled: true,
              options: [
                for (final p in promos)
                  AcademicOption(
                    id: p.id,
                    name: p.year > 0 ? '${p.name} (${p.year})' : p.name,
                  ),
              ],
              onSelected: (id, name) => setState(() {
                _promotionId = id.isEmpty ? null : id;
                _promotionName = name;
              }),
              onCreateCustom: (name) async {
                final id = await ref
                    .read(academicRepositoryProvider)
                    .suggestPromotion(
                      name: name,
                      departmentId: _departmentId!,
                    );
                ref.invalidate(promotionsProvider(_departmentId));
                return id;
              },
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _matricule,
          style: TextStyle(color: titleColor, fontSize: 16),
          decoration: _field('Matricule'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptedTerms,
              activeColor: primary,
              onChanged: (v) =>
                  setState(() => _acceptedTerms = v ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _acceptedTerms = !_acceptedTerms),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'J’accepte les '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => context.push('/profile/terms'),
                            child: Text(
                              'conditions d’utilisation',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: ' d’Akadex.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.current,
    required this.total,
    required this.activeColor,
    required this.idleColor,
  });

  final int current;
  final int total;
  final Color activeColor;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= current ? activeColor : idleColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ],
    );
  }
}
