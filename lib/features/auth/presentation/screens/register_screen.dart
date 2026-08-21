import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/academic_autocomplete.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
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
  /// 0 rôle · 1 identité · 2 compte · 3 parcours
  int _step = 0;
  String _role = 'student';

  final _lastName = TextEditingController();
  final _postnom = TextEditingController();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _matricule = TextEditingController();
  final _domain = TextEditingController();
  final _company = TextEditingController();
  final _gradYear = TextEditingController();

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
  String? _error;

  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    // Réveil API + cache unis pendant les étapes 0–2 (évite l’attente à « Ton parcours »).
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
    _domain.dispose();
    _company.dispose();
    _gradYear.dispose();
    super.dispose();
  }

  String get _stepTitle => switch (_step) {
        0 => 'Créer un compte',
        1 => 'Qui es-tu ?',
        2 => 'Ton compte',
        _ => _role == 'student' ? 'Ton parcours' : 'Ton expérience',
      };

  String get _stepSubtitle => switch (_step) {
        0 => 'Choisis ton type de profil',
        1 => 'Informations d’identité',
        2 => 'Email et mot de passe',
        _ => _role == 'student'
            ? 'Université et filière'
            : 'Parcours académique et pro',
      };

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        return null;
      case 1:
        if (_lastName.text.trim().isEmpty) return 'Le nom est obligatoire.';
        if (_postnom.text.trim().isEmpty) return 'Le postnom est obligatoire.';
        if (_firstName.text.trim().isEmpty) return 'Le prénom est obligatoire.';
        if (_role == 'student') {
          if (_gender == null || _gender!.isEmpty) {
            return 'Le sexe est obligatoire.';
          }
          if (_birthDate == null) {
            return 'La date de naissance est obligatoire.';
          }
        }
        return null;
      case 2:
        if (_email.text.trim().isEmpty) return "L'email est obligatoire.";
        if (_phone.text.trim().isEmpty) return 'Le téléphone est obligatoire.';
        if (_password.text.length < 8) {
          return 'Le mot de passe doit contenir au moins 8 caractères.';
        }
        return null;
      case 3:
        if (_universityId == null || _universityId!.isEmpty) {
          return "L'université est obligatoire.";
        }
        if (_departmentId == null || _departmentId!.isEmpty) {
          return 'Le département est obligatoire.';
        }
        if (_promotionId == null || _promotionId!.isEmpty) {
          return 'La promotion est obligatoire.';
        }
        if (_role == 'student') {
          if (_facultyId == null || _facultyId!.isEmpty) {
            return 'La faculté est obligatoire.';
          }
          if (_matricule.text.trim().isEmpty) {
            return 'Le matricule est obligatoire.';
          }
        } else {
          if (_domain.text.trim().isEmpty) {
            return 'Le domaine professionnel est obligatoire.';
          }
          final year = int.tryParse(_gradYear.text.trim());
          if (year == null || year < 1950 || year > DateTime.now().year + 1) {
            return "L'année d'obtention du diplôme est obligatoire.";
          }
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
      if (next >= 2) {
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
          role: _role,
          gender: _gender ?? '',
          birthDate: _birthDate == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_birthDate!),
          matricule: _matricule.text.trim(),
          university: _universityId,
          faculty: _facultyId,
          department: _departmentId,
          promotion: _promotionId,
          professionalDomain: _domain.text.trim(),
          company: _company.text.trim(),
          graduationYear: int.tryParse(_gradYear.text.trim()),
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

  InputDecoration _dec(
    String hint, {
    IconData? icon,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: icon == null ? null : Icon(icon, color: hintColor),
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: _fieldPad,
    );
  }

  Widget _softField({required Widget child}) {
    return SoftCard(padding: EdgeInsets.zero, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _totalSteps - 1;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AkadexColors.inkOnDark : AkadexColors.ink;
    final subtitleColor =
        isDark ? AkadexColors.metaOnDark : AkadexColors.inkMuted;
    final linkColor =
        isDark ? AkadexColors.primaryOnDark : AkadexColors.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                          if (_step == 0) ...[
                            const Center(child: AkadexLogo(size: 80)),
                            const SizedBox(height: 12),
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
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 22),
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
                              key: ValueKey('step-$_step-$_role'),
                              child: switch (_step) {
                                0 => _buildRoleStep(
                                    titleColor: titleColor,
                                    subtitleColor: subtitleColor,
                                  ),
                                1 => _buildIdentityStep(
                                    titleColor: titleColor,
                                    subtitleColor: subtitleColor,
                                  ),
                                2 => _buildAccountStep(
                                    titleColor: titleColor,
                                    subtitleColor: subtitleColor,
                                  ),
                                _ => _buildAcademicStep(
                                    titleColor: titleColor,
                                    subtitleColor: subtitleColor,
                                  ),
                              },
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
                                color: isDark
                                    ? const Color(0xFF3A2020)
                                    : const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AkadexColors.danger.withValues(
                                    alpha: isDark ? 0.45 : 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AkadexColors.danger,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AkadexColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _goNext,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isLast
                                          ? "S'inscrire"
                                          : 'Continuer',
                                    ),
                            ),
                          ),
                          if (_step == 0) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(color: subtitleColor),
                                    children: [
                                      const TextSpan(text: 'Déjà un compte ? '),
                                      TextSpan(
                                        text: 'Se connecter',
                                        style: TextStyle(
                                          color: linkColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_step > 0) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _loading ? null : _goBack,
                                child: Text(
                                  'Étape précédente',
                                  style: TextStyle(color: linkColor),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRoleStep({
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleCard(
          selected: _role == 'student',
          icon: Icons.school_outlined,
          title: 'Étudiant',
          subtitle: 'Cours, communauté et mentorat alumni',
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          onTap: () => setState(() => _role = 'student'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          selected: _role == 'alumni',
          icon: Icons.workspace_premium_outlined,
          title: 'Ancien étudiant (Alumni)',
          subtitle: 'Partage ton parcours et mentorise',
          titleColor: titleColor,
          subtitleColor: subtitleColor,
          onTap: () => setState(() => _role = 'alumni'),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AkadexColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Les comptes enseignants sont créés exclusivement '
                  'par l’administrateur.',
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep({
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isStudent = _role == 'student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _softField(
          child: TextField(
            controller: _lastName,
            style: TextStyle(color: titleColor),
            decoration: _dec(
              'Nom',
              icon: Icons.badge_outlined,
              hintColor: subtitleColor,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _postnom,
            style: TextStyle(color: titleColor),
            decoration: _dec(
              'Postnom',
              icon: Icons.badge_outlined,
              hintColor: subtitleColor,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _firstName,
            style: TextStyle(color: titleColor),
            decoration: _dec(
              'Prénom',
              icon: Icons.person_outline_rounded,
              hintColor: subtitleColor,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
        ),
        if (isStudent) ...[
          const SizedBox(height: 12),
          _softField(
            child: DropdownButtonFormField<String>(
              key: ValueKey('gender-$_gender'),
              initialValue: _gender,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: titleColor),
              decoration: _dec('Sexe', hintColor: subtitleColor),
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
          ),
          const SizedBox(height: 12),
          _softField(
            child: InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _dec(
                  'Date de naissance',
                  icon: Icons.cake_outlined,
                  hintColor: subtitleColor,
                ),
                child: Text(
                  _birthDate == null
                      ? 'Sélectionner'
                      : DateFormat('dd/MM/yyyy').format(_birthDate!),
                  style: TextStyle(
                    color: _birthDate == null ? subtitleColor : titleColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountStep({
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _softField(
          child: TextField(
            controller: _email,
            style: TextStyle(color: titleColor),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _dec(
              'Email',
              icon: Icons.mail_outline_rounded,
              hintColor: subtitleColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _phone,
            style: TextStyle(color: titleColor),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _dec(
              'Téléphone',
              icon: Icons.phone_outlined,
              hintColor: subtitleColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _password,
            style: TextStyle(color: titleColor),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: _dec(
              'Mot de passe',
              icon: Icons.lock_outline_rounded,
              hintColor: subtitleColor,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: subtitleColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Au moins 8 caractères',
          style: TextStyle(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _catalogPlaceholder(
    String label, {
    IconData? icon,
    required Color subtitleColor,
  }) {
    return _softField(
      child: TextField(
        enabled: false,
        style: TextStyle(color: subtitleColor),
        decoration: _dec(label, icon: icon, hintColor: subtitleColor),
      ),
    );
  }

  Widget _buildAcademicStep({
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final unisAsync = ref.watch(universitiesProvider);
    final hasUni = _universityId != null && _universityId!.isNotEmpty;
    final hasFac = _facultyId != null && _facultyId!.isNotEmpty;
    final hasDept = _departmentId != null && _departmentId!.isNotEmpty;
    // Ne charge pas tout le catalogue avant la sélection d’université
    // (évite un GET departments/ énorme + cold start Render).
    final facultiesAsync = hasUni
        ? ref.watch(facultiesProvider(_universityId))
        : const AsyncValue<List<FacultyItem>>.data([]);
    // Départements filtrés par faculté dès qu’elle est choisie.
    final deptsAsync = hasFac
        ? ref.watch(facultyDepartmentsProvider(_facultyId))
        : hasUni
            ? ref.watch(departmentsProvider(_universityId))
            : const AsyncValue<List<DepartmentItem>>.data([]);
    final promosAsync = hasDept
        ? ref.watch(promotionsProvider(_departmentId))
        : const AsyncValue<List<PromotionItem>>.data([]);
    final isStudent = _role == 'student';
    Object? catalogError;
    if (unisAsync.hasError) {
      catalogError = unisAsync.error;
    } else if (isStudent && hasUni && facultiesAsync.hasError) {
      catalogError = facultiesAsync.error;
    } else if (hasUni && deptsAsync.hasError) {
      catalogError = deptsAsync.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (catalogError != null) ...[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  apiErrorMessage(catalogError),
                  style: TextStyle(
                    color: subtitleColor,
                    height: 1.35,
                  ),
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        unisAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
              _catalogPlaceholder(
                'Université (chargement…)',
                icon: Icons.account_balance_outlined,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
          error: (_, _) => _catalogPlaceholder(
            'Université (indisponible — réessayer)',
            icon: Icons.account_balance_outlined,
            subtitleColor: subtitleColor,
          ),
          data: (unis) => AcademicAutocomplete(
            key: ValueKey('uni-$_universityId'),
            label: 'Université',
            softStyle: true,
            icon: Icons.account_balance_outlined,
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
        if (isStudent) ...[
          const SizedBox(height: 12),
          if (!hasUni)
            _catalogPlaceholder(
              'Faculté (choisis d’abord l’université)',
              subtitleColor: subtitleColor,
            )
          else
            facultiesAsync.when(
              loading: () => _catalogPlaceholder(
                'Faculté (chargement…)',
                subtitleColor: subtitleColor,
              ),
              error: (_, _) => _catalogPlaceholder(
                'Faculté (indisponible — réessayer)',
                subtitleColor: subtitleColor,
              ),
              data: (facs) => AcademicAutocomplete(
                key: ValueKey('fac-$_universityId-$_facultyId'),
                label: 'Faculté',
                softStyle: true,
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
        ],
        const SizedBox(height: 12),
        if (!hasUni)
          _catalogPlaceholder(
            'Département (choisis d’abord l’université)',
            subtitleColor: subtitleColor,
          )
        else if (isStudent && !hasFac)
          _catalogPlaceholder(
            'Département (choisis d’abord la faculté)',
            subtitleColor: subtitleColor,
          )
        else
          deptsAsync.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 8),
                _catalogPlaceholder(
                  'Département (chargement…)',
                  subtitleColor: subtitleColor,
                ),
              ],
            ),
            error: (_, _) => _catalogPlaceholder(
              'Département (indisponible — réessayer)',
              subtitleColor: subtitleColor,
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
                if (isStudent &&
                    facId != null &&
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
                softStyle: true,
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
            subtitleColor: subtitleColor,
          )
        else
          promosAsync.when(
            loading: () => _catalogPlaceholder(
              'Promotion (chargement…)',
              subtitleColor: subtitleColor,
            ),
            error: (_, _) => _catalogPlaceholder(
              'Promotion (indisponible — réessayer)',
              subtitleColor: subtitleColor,
            ),
            data: (promos) => AcademicAutocomplete(
              key: ValueKey('promo-$_departmentId-$_promotionId'),
              label: 'Promotion',
              softStyle: true,
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
        if (isStudent) ...[
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _matricule,
              style: TextStyle(color: titleColor),
              decoration: _dec(
                'Matricule',
                icon: Icons.numbers_rounded,
                hintColor: subtitleColor,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _domain,
              style: TextStyle(color: titleColor),
              decoration: _dec(
                'Domaine professionnel',
                icon: Icons.work_outline_rounded,
                hintColor: subtitleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _company,
              style: TextStyle(color: titleColor),
              decoration: _dec(
                'Entreprise (optionnel)',
                icon: Icons.business_outlined,
                hintColor: subtitleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _gradYear,
              style: TextStyle(color: titleColor),
              keyboardType: TextInputType.number,
              decoration: _dec(
                'Année du diplôme',
                icon: Icons.calendar_today_outlined,
                hintColor: subtitleColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SoftCard(
      onTap: onTap,
      accentBorder: selected,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? AkadexColors.primarySoft
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AkadexColors.background),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected
                  ? (isDark ? AkadexColors.primaryOnDark : AkadexColors.primary)
                  : subtitleColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected
                ? (isDark ? AkadexColors.primaryOnDark : AkadexColors.primary)
                : subtitleColor,
          ),
        ],
      ),
    );
  }
}
