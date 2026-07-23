import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';

final teacherDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final repo = ref.watch(academicRepositoryProvider);
  return repo.fetchTeacherDashboard(
    userId: user?.id,
    userName: user?.name,
  );
});

/// Tableau de bord enseignant — insights style Facebook.
class ProfessorDashboardScreen extends ConsumerWidget {
  const ProfessorDashboardScreen({super.key});

  static const _fbBg = Color(0xFFF0F2F5);
  static const _fbInk = Color(0xFF050505);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBlue = Color(0xFF0866FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(teacherDashboardProvider);

    return Scaffold(
      backgroundColor: _fbBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _fbInk,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _fbBorder),
        ),
      ),
      body: dash.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(e), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(teacherDashboardProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final activity = (data['activity_7d'] as List?) ?? const [];
          final top = (data['top_courses'] as List?) ?? const [];
          final chartValues = activity
              .map((e) => ((e as Map)['value'] as num?)?.toDouble() ?? 0)
              .toList();
          final chartLabels = activity
              .map((e) => ((e as Map)['label'] ?? '').toString())
              .toList();

          return RefreshIndicator(
            color: _fbBlue,
            onRefresh: () async {
              ref.invalidate(teacherDashboardProvider);
              await ref.read(teacherDashboardProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: const Text(
                    'Aperçu',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _fbInk,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _StatCard(
                        label: 'Visites',
                        value: '${data['views'] ?? 0}',
                        icon: Icons.visibility_outlined,
                        color: _fbBlue,
                      ),
                      _StatCard(
                        label: 'Étudiants',
                        value: '${data['students'] ?? 0}',
                        icon: Icons.people_outline,
                        color: const Color(0xFF45BD62),
                      ),
                      _StatCard(
                        label: 'Cours',
                        value: '${data['courses_count'] ?? 0}',
                        icon: Icons.menu_book_outlined,
                        color: const Color(0xFFF7B928),
                      ),
                      _StatCard(
                        label: 'Leçons',
                        value: '${data['lessons'] ?? 0}',
                        icon: Icons.play_lesson_outlined,
                        color: const Color(0xFFF5533D),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activité 7 derniers jours',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _fbInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Progressions et lectures des étudiants',
                        style: TextStyle(fontSize: 13, color: _fbMuted),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _BarChart(
                          values: chartValues,
                          labels: chartLabels,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: const Text(
                    'Tes cours',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _fbInk,
                    ),
                  ),
                ),
                if (top.isEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Publie un cours pour voir les stats ici.',
                      style: TextStyle(color: _fbMuted),
                    ),
                  )
                else
                  for (final raw in top)
                    _TopCourseRow(
                      data: Map<String, dynamic>.from(raw as Map),
                      onTap: () => context.push(
                        '/teacher-course/${raw['id']}',
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Color(0xFF050505),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF65676B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCourseRow extends StatelessWidget {
  const _TopCourseRow({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFCED0D4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['title'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF050505),
                      ),
                    ),
                    Text(
                      '${data['code'] ?? ''} · ${data['views'] ?? 0} vues · '
                      '${data['students'] ?? 0} étudiants',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF65676B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore d’activité',
          style: TextStyle(color: Color(0xFF65676B)),
        ),
      );
    }
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    final peak = maxV <= 0 ? 1.0 : maxV;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (values[i] / peak).clamp(0.04, 1.0),
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ProfessorDashboardScreen._fbBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF65676B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
