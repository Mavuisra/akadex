from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AlumniFollowViewSet,
    PostCommentViewSet,
    PostViewSet,
    SavedPostViewSet,
)

router = DefaultRouter()
router.register('posts', PostViewSet, basename='post')
router.register('post-comments', PostCommentViewSet, basename='post-comment')
router.register('alumni-follows', AlumniFollowViewSet, basename='alumni-follow')
router.register('saved-posts', SavedPostViewSet, basename='saved-post')

urlpatterns = [
    path('', include(router.urls)),
]
