import '../../../domain/models/models.dart';

abstract final class CourseCoverImages {
  static String resolve(Course course) => course.coverUrl.trim();
}
