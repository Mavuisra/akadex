import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/academic_autocomplete.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _postnom = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _headline = TextEditingController();
  final _email = TextEditingController();
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

  XFile? _avatarFile;
  XFile? _coverFile;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;

  String? _avatarUrl;
  String? _coverUrl;
  String _role = 'student';

  bool _initialized = false;
  bool _loading = false;
  String? _error;

  static const _pad = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  final _picker = ImagePicker();

  @override
  void dispose() {
    _firstName.dispose();
    _postnom.dispose();
    _lastName.dispose();
    _phone.dispose();
    _bio.dispose();
    _headline.dispose();
    _email.dispose();
    _domain.dispose();
    _company.dispose();
    _gradYear.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile user) {
    _firstName.text = user.firstName;
    _postnom.text = user.postnom;
    _lastName.text = user.lastName;
    _phone.text = user.phone;
    _bio.text = user.bio;
    _headline.text = user.headline;
    _email.text = user.email;
    _domain.text = user.professionalDomain;
    _company.text = user.company;
    _gradYear.text = user.graduationYear?.toString() ?? '';
    _gender = user.gender.isEmpty ? null : user.gender;
    _birthDate = user.birthDate;
    _universityId = user.universityId.isEmpty ? null : user.universityId;
    _universityName = user.university;
    _facultyId = user.facultyId.isEmpty ? null : user.facultyId;
    _facultyName = user.faculty;
    _departmentId = user.departmentId.isEmpty ? null : user.departmentId;
    _departmentName = user.department;
    _promotionId = user.promotionId.isEmpty ? null : user.promotionId;
    _promotionName = user.promotion;
    _avatarUrl = user.avatarUrl;
    _coverUrl = user.coverUrl;
    _role = user.role;
    _initialized = true;
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      contentPadding: _pad,
    );
  }

  Future<void> _pickImage({required bool cover}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: cover ? 1600 : 800,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (cover) {
        _coverFile = file;
        _coverBytes = bytes;
      } else {
        _avatarFile = file;
        _avatarBytes = bytes;
      }
    });
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

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'first_name': _firstName.text.trim(),
        'postnom': _postnom.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'bio': _bio.text.trim(),
        'headline': _headline.text.trim(),
        'email': _email.text.trim(),
        if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
        if (_birthDate != null)
          'birth_date': DateFormat('yyyy-MM-dd').format(_birthDate!),
        if (_universityId != null && _universityId!.isNotEmpty)
          'university': int.tryParse(_universityId!) ?? _universityId,
        if (_facultyId != null && _facultyId!.isNotEmpty)
          'faculty': int.tryParse(_facultyId!) ?? _facultyId,
        if (_departmentId != null && _departmentId!.isNotEmpty)
          'department': int.tryParse(_departmentId!) ?? _departmentId,
        if (_promotionId != null && _promotionId!.isNotEmpty)
          'promotion': int.tryParse(_promotionId!) ?? _promotionId,
        if (_role == 'alumni') ...{
          'professional_domain': _domain.text.trim(),
          'company': _company.text.trim(),
          if (_gradYear.text.trim().isNotEmpty)
            'graduation_year': int.tryParse(_gradYear.text.trim()),
        },
        if (_avatarFile != null) 'avatar': _avatarFile,
        if (_coverFile != null) 'cover': _coverFile,
      };

      await ref.read(authStateProvider.notifier).updateProfile(data);
      final me = ref.read(authStateProvider).valueOrNull;
      ref.invalidate(postsProvider);
      ref.invalidate(postsProvider('alumni'));
      ref.invalidate(postsProvider('community'));
      if (me != null) {
        ref.invalidate(alumniProfileProvider(me.id));
        ref.invalidate(alumniPostsByAuthorProvider(me.id));
      }
      ref.invalidate(notificationsProvider);

      if (!mounted) return;
      final pending = (me?.pendingEmail ?? '').isNotEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending
                ? 'Profil mis à jour. Confirme ton nouvel e-mail via le code dans tes notifications.'
                : 'Profil mis à jour',
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
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;

    if (user != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialized) setState(() => _hydrate(user));
      });
    }

    final isStudent = _role == 'student';
    final unisAsync = ref.watch(universitiesProvider);
    final facultiesAsync = ref.watch(facultiesProvider(_universityId));
    final deptsAsync = ref.watch(departmentsProvider(_universityId));
    final promosAsync = ref.watch(promotionsProvider(_departmentId));

    return Scaffold(
      backgroundColor: AkadexColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Connecte-toi pour modifier ton profil.'))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(cover: true),
                        child: Stack(
                          children: [
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                gradient: AkadexColors.brandGradient,
                                image: _coverImage(),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: _PhotoChip(
                                label: 'Couverture',
                                onTap: () => _pickImage(cover: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(cover: false),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _avatarImage(),
                                    child: _avatarImage() == null
                                        ? Text(
                                            user.name.isEmpty
                                                ? '?'
                                                : user.name.characters.first
                                                    .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                              color: AkadexColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AkadexColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _pickImage(cover: false),
                              icon: const Icon(Icons.photo_outlined, size: 18),
                              label: const Text('Changer la photo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Identité',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _firstName,
                        decoration: _dec(
                          'Prénom',
                          icon: Icons.person_outline_rounded,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _postnom,
                        decoration: _dec(
                          'Postnom',
                          icon: Icons.badge_outlined,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _lastName,
                        decoration: _dec(
                          'Nom',
                          icon: Icons.badge_outlined,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _dec(
                          'Téléphone',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _dec(
                          'Email',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),
                      if (isStudent) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          key: ValueKey('gender-$_gender'),
                          initialValue: _gender,
                          decoration: _dec('Sexe'),
                          items: const [
                            DropdownMenuItem(
                              value: 'M',
                              child: Text('Masculin'),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text('Féminin'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: _dec(
                              'Date de naissance',
                              icon: Icons.cake_outlined,
                            ),
                            child: Text(
                              _birthDate == null
                                  ? 'Sélectionner'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_birthDate!),
                              style: TextStyle(
                                color: _birthDate == null
                                    ? AkadexColors.inkSoft
                                    : AkadexColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Présentation',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _headline,
                        decoration: _dec(
                          'Titre / accroche',
                          icon: Icons.short_text_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bio,
                        maxLines: 4,
                        decoration: _dec(
                          'Bio',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                      if (_role == 'alumni') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _domain,
                          decoration: _dec(
                            'Domaine professionnel',
                            icon: Icons.work_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _company,
                          decoration: _dec(
                            'Entreprise',
                            icon: Icons.business_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _gradYear,
                          keyboardType: TextInputType.number,
                          decoration: _dec(
                            'Année du diplôme',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Parcours académique',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      unisAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(apiErrorMessage(e)),
                        data: (unis) => AcademicAutocomplete(
                          key: ValueKey('uni-$_universityId'),
                          label: 'Université',
                          icon: Icons.account_balance_outlined,
                          selectedId: _universityId,
                          selectedName: _universityName,
                          options: [
                            for (final u in unis)
                              AcademicOption(id: u.id, name: u.name),
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
                        const SizedBox(height: 10),
                        facultiesAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text(apiErrorMessage(e)),
                          data: (facs) => AcademicAutocomplete(
                            key: ValueKey('fac-$_universityId-$_facultyId'),
                            label: 'Faculté',
                            selectedId: _facultyId,
                            selectedName: _facultyName,
                            enabled: _universityId != null,
                            options: [
                              for (final f in facs)
                                AcademicOption(id: f.id, name: f.name),
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
                                    ref.invalidate(
                                      facultiesProvider(_universityId),
                                    );
                                    return id;
                                  },
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      promosAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => Text(apiErrorMessage(e)),
                        data: (promos) => AcademicAutocomplete(
                          key: ValueKey('promo-$_departmentId-$_promotionId'),
                          label: 'Promotion',
                          selectedId: _promotionId,
                          selectedName: _promotionName,
                          enabled: _departmentId != null,
                          options: [
                            for (final p in promos)
                              AcademicOption(
                                id: p.id,
                                name: p.year > 0
                                    ? '${p.name} (${p.year})'
                                    : p.name,
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
                                  ref.invalidate(
                                    promotionsProvider(_departmentId),
                                  );
                                  return id;
                                },
                        ),
                      ),
                    ],
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
                        const Icon(
                          Icons.error_outline,
                          color: AkadexColors.danger,
                        ),
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
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ],
            ),
    );
  }

  DecorationImage? _coverImage() {
    if (_coverBytes != null) {
      return DecorationImage(
        image: MemoryImage(_coverBytes!),
        fit: BoxFit.cover,
      );
    }
    final url = _coverUrl;
    if (url != null && url.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  ImageProvider? _avatarImage() {
    if (_avatarBytes != null) return MemoryImage(_avatarBytes!);
    final url = _avatarUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }
}

class _PhotoChip extends StatelessWidget {
  const _PhotoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_camera_outlined,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
