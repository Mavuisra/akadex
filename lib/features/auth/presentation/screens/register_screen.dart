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

  List<String> get _stepLabels => const [
        'Profil',
        'Identité',
        'Compte',
        'Parcours',
      ];

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
      context.go('/onboarding');
    }
  }

  void _goNext() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() {
        _step += 1;
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

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _totalSteps - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: _StepProgress(
                        current: _step,
                        labels: _stepLabels,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AkadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _stepSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AkadexColors.inkMuted
                                  .withValues(alpha: 0.95),
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
                                0 => _buildRoleStep(),
                                1 => _buildIdentityStep(),
                                2 => _buildAccountStep(),
                                _ => _buildAcademicStep(),
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
                                color: const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(14),
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
                                child: const Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      color: AkadexColors.inkMuted,
                                    ),
                                    children: [
                                      TextSpan(text: 'Déjà un compte ? '),
                                      TextSpan(
                                        text: 'Se connecter',
                                        style: TextStyle(
                                          color: AkadexColors.primary,
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
                                child: const Text('Étape précédente'),
                              ),
                            ),
                          ],
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

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleCard(
          selected: _role == 'student',
          icon: Icons.school_outlined,
          title: 'Étudiant',
          subtitle: 'Cours, communauté et mentorat alumni',
          onTap: () => setState(() => _role = 'student'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          selected: _role == 'alumni',
          icon: Icons.workspace_premium_outlined,
          title: 'Ancien étudiant (Alumni)',
          subtitle: 'Partage ton parcours et mentorise',
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
              const Expanded(
                child: Text(
                  'Les comptes enseignants sont créés exclusivement '
                  'par l’administrateur.',
                  style: TextStyle(height: 1.4, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep() {
    final isStudent = _role == 'student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _softField(
          child: TextField(
            controller: _lastName,
            decoration: _dec('Nom', icon: Icons.badge_outlined),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _postnom,
            decoration: _dec('Postnom', icon: Icons.badge_outlined),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _firstName,
            decoration: _dec('Prénom', icon: Icons.person_outline_rounded),
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
              decoration: _dec('Sexe'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Masculin')),
                DropdownMenuItem(value: 'F', child: Text('Féminin')),
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
                ),
                child: Text(
                  _birthDate == null
                      ? 'Sélectionner'
                      : DateFormat('dd/MM/yyyy').format(_birthDate!),
                  style: TextStyle(
                    color: _birthDate == null
                        ? AkadexColors.inkSoft
                        : AkadexColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _softField(
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _dec('Email', icon: Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _dec('Téléphone', icon: Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        _softField(
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: _dec('Mot de passe', icon: Icons.lock_outline_rounded)
                .copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
            color: AkadexColors.inkSoft.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicStep() {
    final unisAsync = ref.watch(universitiesProvider);
    final facultiesAsync = ref.watch(facultiesProvider(_universityId));
    final deptsAsync = ref.watch(departmentsProvider(_universityId));
    final promosAsync = ref.watch(promotionsProvider(_departmentId));
    final isStudent = _role == 'student';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        unisAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(apiErrorMessage(e)),
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
          facultiesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text(apiErrorMessage(e)),
            data: (facs) => AcademicAutocomplete(
              key: ValueKey('fac-$_universityId-$_facultyId'),
              label: 'Faculté',
              softStyle: true,
              selectedId: _facultyId,
              selectedName: _facultyName,
              enabled: _universityId != null,
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
              onCreateCustom: _universityId == null
                  ? null
                  : (name) async {
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
        deptsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(apiErrorMessage(e)),
          data: (all) {
            final filtered = all.where((d) {
              if (_universityId != null &&
                  d.universityId != _universityId &&
                  d.universityId != 'null') {
                return false;
              }
              if (isStudent &&
                  _facultyId != null &&
                  d.facultyId.isNotEmpty &&
                  d.facultyId != _facultyId) {
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
                return id;
              },
            );
          },
        ),
        const SizedBox(height: 12),
        promosAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text(apiErrorMessage(e)),
          data: (promos) => AcademicAutocomplete(
            key: ValueKey('promo-$_departmentId-$_promotionId'),
            label: 'Promotion',
            softStyle: true,
            selectedId: _promotionId,
            selectedName: _promotionName,
            enabled: _departmentId != null,
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
            onCreateCustom: _departmentId == null
                ? null
                : (name) async {
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
              decoration: _dec('Matricule', icon: Icons.numbers_rounded),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _domain,
              decoration: _dec(
                'Domaine professionnel',
                icon: Icons.work_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _company,
              decoration: _dec(
                'Entreprise (optionnel)',
                icon: Icons.business_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _softField(
            child: TextField(
              controller: _gradYear,
              keyboardType: TextInputType.number,
              decoration: _dec(
                'Année du diplôme',
                icon: Icons.calendar_today_outlined,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.current,
    required this.labels,
  });

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= current
                          ? AkadexColors.primary
                          : AkadexColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              _StepDot(
                index: i,
                completed: i < current,
                isCurrent: i == current,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == labels.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        i == current ? FontWeight.w800 : FontWeight.w600,
                    color: i <= current
                        ? AkadexColors.primary
                        : AkadexColors.inkSoft,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.completed,
    required this.isCurrent,
  });

  final int index;
  final bool completed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final active = completed || isCurrent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isCurrent ? 28 : 22,
      height: isCurrent ? 28 : 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AkadexColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? AkadexColors.primary : AkadexColors.border,
          width: 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AkadexColors.primary.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: completed
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: active ? Colors.white : AkadexColors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  : AkadexColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected ? AkadexColors.primary : AkadexColors.inkMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AkadexColors.inkMuted,
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
            color: selected ? AkadexColors.primary : AkadexColors.inkSoft,
          ),
        ],
      ),
    );
  }
}
