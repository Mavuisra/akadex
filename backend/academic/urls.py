from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .suggest_views import (
    SuggestDepartmentView,
    SuggestFacultyView,
    SuggestPromotionView,
    SuggestUniversityView,
)
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
    LearningDomainViewSet,
    PromotionViewSet,
    RewardPrizeViewSet,
    UniversityViewSet,
)

router = DefaultRouter()
router.register('universities', UniversityViewSet, basename='university')
router.register('campuses', CampusViewSet, basename='campus')
router.register('faculties', FacultyViewSet, basename='faculty')
router.register('departments', DepartmentViewSet, basename='department')
router.register('promotions', PromotionViewSet, basename='promotion')
router.register('learning-domains', LearningDomainViewSet, basename='learning-domain')
router.register('courses', CourseViewSet, basename='course')
router.register('documents', DocumentViewSet, basename='document')
router.register('document-comments', DocumentCommentViewSet, basename='document-comment')
router.register('favorites', FavoriteViewSet, basename='favorite')
router.register('announcements', AnnouncementViewSet, basename='announcement')
router.register('events', CalendarEventViewSet, basename='event')
router.register('rewards', RewardPrizeViewSet, basename='reward')

urlpatterns = [
    path(
        'suggest/university/',
        SuggestUniversityView.as_view(),
        name='suggest-university',
    ),
    path(
        'suggest/faculty/',
        SuggestFacultyView.as_view(),
        name='suggest-faculty',
    ),
    path(
        'suggest/department/',
        SuggestDepartmentView.as_view(),
        name='suggest-department',
    ),
    path(
        'suggest/promotion/',
        SuggestPromotionView.as_view(),
        name='suggest-promotion',
    ),
    path('', include(router.urls)),
]
