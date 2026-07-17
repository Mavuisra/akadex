from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AnnouncementViewSet,
    CalendarEventViewSet,
    CampusViewSet,
    CourseViewSet,
    DepartmentViewSet,
    DocumentCommentViewSet,
    DocumentViewSet,
    FacultyViewSet,
    FavoriteViewSet,
    PromotionViewSet,
    UniversityViewSet,
)

router = DefaultRouter()
router.register('universities', UniversityViewSet, basename='university')
router.register('campuses', CampusViewSet, basename='campus')
router.register('faculties', FacultyViewSet, basename='faculty')
router.register('departments', DepartmentViewSet, basename='department')
router.register('promotions', PromotionViewSet, basename='promotion')
router.register('courses', CourseViewSet, basename='course')
router.register('documents', DocumentViewSet, basename='document')
router.register('document-comments', DocumentCommentViewSet, basename='document-comment')
router.register('favorites', FavoriteViewSet, basename='favorite')
router.register('announcements', AnnouncementViewSet, basename='announcement')
router.register('events', CalendarEventViewSet, basename='event')

urlpatterns = [
    path('', include(router.urls)),
]
