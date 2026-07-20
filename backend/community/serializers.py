from rest_framework import serializers
import json

from .models import AlumniFollow, Post, PostComment, SavedPost


class FlexibleTagsField(serializers.Field):
    """List JSON, chaîne JSON (multipart) ou tag unique → list[str]."""

    def to_representation(self, value):
        if value is None:
            return []
        if isinstance(value, list):
            return [str(t) for t in value]
        return [str(value)]

    def to_internal_value(self, data):
        if data is None or data == '':
            return []
        if isinstance(data, list):
            return [str(t) for t in data]
        if isinstance(data, str):
            raw = data.strip()
            if not raw:
                return []
            try:
                parsed = json.loads(raw)
            except json.JSONDecodeError:
                return [raw]
            if isinstance(parsed, list):
                return [str(t) for t in parsed]
            if parsed is None:
                return []
            return [str(parsed)]
        return [str(data)]


class PostCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    author_avatar = serializers.SerializerMethodField()

    class Meta:
        model = PostComment
        fields = [
            'id',
            'post',
            'author',
            'author_name',
            'author_avatar',
            'content',
            'parent',
            'created_at',
        ]
        read_only_fields = ['author', 'created_at']

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email

    def get_author_avatar(self, obj):
        request = self.context.get('request')
        if not obj.author.avatar:
            return ''
        url = obj.author.avatar.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url


class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    author_avatar = serializers.SerializerMethodField()
    author_role = serializers.CharField(source='author.role', read_only=True)
    author_id = serializers.IntegerField(source='author.id', read_only=True)
    author_university = serializers.SerializerMethodField()
    author_promotion = serializers.SerializerMethodField()
    department_name = serializers.CharField(
        source='department.name',
        read_only=True,
        default='',
    )
    kind_display = serializers.CharField(source='get_kind_display', read_only=True)
    attachment_url = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()
    is_following_author = serializers.SerializerMethodField()
    tags = FlexibleTagsField(required=False, default=list)

    class Meta:
        model = Post
        fields = [
            'id',
            'author',
            'author_id',
            'author_name',
            'author_avatar',
            'author_role',
            'author_university',
            'author_promotion',
            'department',
            'department_name',
            'title',
            'content',
            'kind',
            'kind_display',
            'video_url',
            'file',
            'image',
            'file_url',
            'attachment_url',
            'image_url',
            'page_count',
            'tags',
            'background_color',
            'likes_count',
            'comments_count',
            'is_approved',
            'moderation_status',
            'rejection_reason',
            'is_liked',
            'is_saved',
            'is_following_author',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'author',
            'likes_count',
            'comments_count',
            'is_approved',
            'moderation_status',
            'rejection_reason',
            'attachment_url',
            'image_url',
            'created_at',
            'updated_at',
        ]
        extra_kwargs = {
            'file': {'write_only': True, 'required': False},
            'image': {'write_only': True, 'required': False},
        }

    def _abs(self, url):
        if not url:
            return ''
        request = self.context.get('request')
        if request is not None and url.startswith('/'):
            return request.build_absolute_uri(url)
        return url

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email

    def get_author_avatar(self, obj):
        if not obj.author.avatar:
            return ''
        return self._abs(obj.author.avatar.url)

    def get_author_university(self, obj):
        uni = getattr(obj.author, 'university', None)
        return uni.name if uni else ''

    def get_author_promotion(self, obj):
        promo = getattr(obj.author, 'promotion', None)
        if promo is not None:
            return promo.name or promo.level or str(promo)
        return getattr(obj.author, 'level', '') or ''

    def get_attachment_url(self, obj):
        if obj.file:
            return self._abs(obj.file.url)
        return obj.file_url or ''

    def get_image_url(self, obj):
        if obj.image:
            return self._abs(obj.image.url)
        return ''

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.likes.filter(user=request.user).exists()

    def get_is_saved(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.saves.filter(user=request.user).exists()

    def get_is_following_author(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return AlumniFollow.objects.filter(
            follower=request.user,
            alumni=obj.author,
        ).exists()


class AlumniFollowSerializer(serializers.ModelSerializer):
    alumni_name = serializers.SerializerMethodField()
    alumni_avatar = serializers.SerializerMethodField()
    alumni_role = serializers.CharField(source='alumni.role', read_only=True)
    alumni_bio = serializers.CharField(source='alumni.bio', read_only=True)
    alumni_department = serializers.CharField(
        source='alumni.department.name',
        read_only=True,
        default='',
    )

    class Meta:
        model = AlumniFollow
        fields = [
            'id',
            'alumni',
            'alumni_name',
            'alumni_avatar',
            'alumni_role',
            'alumni_bio',
            'alumni_department',
            'created_at',
        ]
        read_only_fields = ['created_at']

    def get_alumni_name(self, obj):
        return obj.alumni.get_full_name() or obj.alumni.email

    def get_alumni_avatar(self, obj):
        request = self.context.get('request')
        if not obj.alumni.avatar:
            return ''
        url = obj.alumni.avatar.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url


class SavedPostSerializer(serializers.ModelSerializer):
    post_detail = PostSerializer(source='post', read_only=True)

    class Meta:
        model = SavedPost
        fields = ['id', 'post', 'post_detail', 'created_at']
        read_only_fields = ['created_at']
