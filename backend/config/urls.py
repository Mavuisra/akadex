from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.auth import EmailTokenObtainPairView

urlpatterns = [
    path('admin/', admin.site.urls),
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
    # Render tourne avec DEBUG=False : sans ça, les photos uploadées sont en 404.
    re_path(
        r'^media/(?P<path>.*)$',
        serve,
        {'document_root': settings.MEDIA_ROOT},
    ),
]
