import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/models.dart';
import 'course_pricing.dart';

/// Ligne panier (cours vidéo à 15$).
class CartItem {
  const CartItem({
    required this.courseId,
    required this.title,
    required this.teacher,
    required this.coverUrl,
    this.priceUsd = CoursePricing.salePriceUsd,
  });

  final String courseId;
  final String title;
  final String teacher;
  final String coverUrl;
  final double priceUsd;

  factory CartItem.fromCourse(Course course) {
    return CartItem(
      courseId: course.id,
      title: course.title,
      teacher: course.displayTeacher,
      coverUrl: course.coverUrl,
      priceUsd: CoursePricing.salePriceUsd,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  bool contains(String courseId) =>
      state.any((e) => e.courseId == courseId);

  bool add(CartItem item) {
    if (contains(item.courseId)) return false;
    state = [...state, item];
    return true;
  }

  bool addCourse(Course course) => add(CartItem.fromCourse(course));

  void remove(String courseId) {
    state = state.where((e) => e.courseId != courseId).toList();
  }

  void clear() => state = const [];

  double get totalUsd =>
      state.fold<double>(0, (sum, e) => sum + e.priceUsd);

  int get count => state.length;
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
