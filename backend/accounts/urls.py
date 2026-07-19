from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    ConfirmEmailView,
    MeView,
    NotificationViewSet,
    RegisterView,
    UserViewSet,
)

router = DefaultRouter()
router.register('users', UserViewSet, basename='user')
router.register('notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('me/', MeView.as_view(), name='me'),
    path('me/confirm-email/', ConfirmEmailView.as_view(), name='confirm-email'),
    path('', include(router.urls)),
]
