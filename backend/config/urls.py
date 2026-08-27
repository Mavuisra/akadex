from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.auth import EmailTokenObtainPairView
from config.views import (
    admin_app,
    home,
    legal_delete_account,
    legal_privacy,
    legal_terms,
    storage_health,
    teacher_app,
)

urlpatterns = [
    path('', home, name='home'),
    path('legal/privacy/', legal_privacy, name='legal-privacy'),
    path('legal/terms/', legal_terms, name='legal-terms'),
    path('legal/delete-account/', legal_delete_account, name='legal-delete-account'),
    path('enseignant/', teacher_app, name='teacher-app'),
    path('enseignant/<path:path>', teacher_app, name='teacher-app-path'),
    path('admin/', admin_app, name='akadex-admin'),
    path('admin/<path:path>', admin_app, name='akadex-admin-path'),
    path('django-admin/', admin.site.urls),
    path('api/health/storage/', storage_health, name='storage-health'),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path(
        'api/docs/',
        SpectacularSwaggerView.as_view(url_name='schema'),
        name='swagger-ui',
    ),
    path('api/auth/token/', EmailTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/', include('accounts.urls')),
    path('api/', include('academic.urls')),
    path('api/', include('community.urls')),
    path('api/', include('messaging.urls')),
    path('api/', include('learning.urls')),
    path('api/', include('payments.urls')),
    re_path(
        r'^media/(?P<path>.*)$',
        serve,
        {'document_root': settings.MEDIA_ROOT},
    ),
]
