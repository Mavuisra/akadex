import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/mocks/mock_data.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final course = MockData.courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => MockData.courses.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(course.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AkadexColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(course.icon, color: AkadexColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${course.meta} • ${course.docs}',
                        style: const TextStyle(color: AkadexColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Documents'),
          const SizedBox(height: 10),
          ...MockData.docs.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                onTap: () => context.push('/library/document/${d.id}'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AkadexColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                    DocTypeTag(d.type),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
