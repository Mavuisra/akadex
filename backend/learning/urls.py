from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CourseCommentViewSet,
    CourseLessonViewSet,
    CourseModuleViewSet,
    CourseOutlineViewSet,
    LessonProgressViewSet,
    student_dashboard,
)

router = DefaultRouter()
router.register('course-outlines', CourseOutlineViewSet, basename='course-outline')
router.register('course-modules', CourseModuleViewSet, basename='course-module')
router.register('course-lessons', CourseLessonViewSet, basename='course-lesson')
router.register('course-comments', CourseCommentViewSet, basename='course-comment')
router.register('lesson-progress', LessonProgressViewSet, basename='lesson-progress')

urlpatterns = [
    path('student-dashboard/', student_dashboard, name='student-dashboard'),
    path('', include(router.urls)),
]
