from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .admin_api import (
    AdminBroadcastNotificationView,
    AdminDashboardView,
    AdminDepositViewSet,
    AdminEnrollmentView,
    AdminUserViewSet,
)
from .views import (
    ConfirmEmailView,
    MeView,
    NotificationViewSet,
    PushTestView,
    PushTokenView,
    RegisterView,
    UserViewSet,
)

router = DefaultRouter()
router.register('users', UserViewSet, basename='user')
router.register('notifications', NotificationViewSet, basename='notification')

admin_router = DefaultRouter()
admin_router.register('users', AdminUserViewSet, basename='admin-user')
admin_router.register('deposits', AdminDepositViewSet, basename='admin-deposit')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('me/', MeView.as_view(), name='me'),
    path('me/confirm-email/', ConfirmEmailView.as_view(), name='confirm-email'),
    path('push-token/', PushTokenView.as_view(), name='push-token'),
    path('push-test/', PushTestView.as_view(), name='push-test'),
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('admin/enrollments/', AdminEnrollmentView.as_view(), name='admin-enrollments'),
    path(
        'admin/notifications/',
        AdminBroadcastNotificationView.as_view(),
        name='admin-notifications',
    ),
    path('admin/', include(admin_router.urls)),
    path('', include(router.urls)),
]
