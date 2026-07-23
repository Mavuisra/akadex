from rest_framework import serializers

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    CourseValidationLog,
    Department,
    Document,
    DocumentComment,
    Faculty,
    Favorite,
    LearningDomain,
    Promotion,
    RewardPrize,
    RewardRedemption,
    University,
)


def _first_teacher(course):
    return course.teachers.all().first()


def teacher_title_of(course):
    t = _first_teacher(course)
    if t is None:
        return 'Professeur'
    raw = (t.headline or '').strip()
    known = (
        'Professeur',
        'Professeure',
        'Docteur',
        'Docteure',
        'Maître de conférences',
        'Maitre de conferences',
        'Chargé de cours',
        'Charge de cours',
        'Dr.',
        'Prof.',
    )
    for k in known:
        if raw.lower().startswith(k.lower()):
            return k if k not in ('Dr.', 'Prof.') else (
                'Docteur' if k == 'Dr.' else 'Professeur'
            )
    if raw:
        # headline = titre académique complet
        return raw.split(',')[0].split('—')[0].split('-')[0].strip() or 'Professeur'
    if getattr(t, 'gender', '') == 'F':
        return 'Professeure'
    return 'Professeur'


def teacher_payload(course):
    t = _first_teacher(course)
    if t is None:
        return {
            'teacher_title': 'Professeur',
            'teacher_full_name': '',
            'teacher_headline': '',
            'teacher_bio': '',
            'teacher_specialty': '',
            'teacher_avatar_url': '',
            'teacher_university': '',
        }
    photo = (getattr(t, 'photo_url', '') or '').strip()
    if not photo and t.avatar:
        try:
            photo = t.avatar.url
        except Exception:
            photo = ''
    uni = ''
    if t.university_id:
        uni = t.university.name
    return {
        'teacher_title': teacher_title_of(course),
        'teacher_full_name': t.get_full_name() or t.email,
        'teacher_headline': (t.headline or '').strip(),
        'teacher_bio': (t.bio or '').strip(),
        'teacher_specialty': (t.professional_domain or '').strip(),
        'teacher_avatar_url': photo,
        'teacher_university': uni,
    }


class UniversitySerializer(serializers.ModelSerializer):
    class Meta:
        model = University
        fields = [
            'id',
            'name',
            'slug',
            'country',
            'city',
            'logo',
            'primary_color',
            'accent_color',
            'description',
            'is_active',
            'is_verified',
            'is_user_suggested',
        ]


class CampusSerializer(serializers.ModelSerializer):
    class Meta:
        model = Campus
        fields = ['id', 'university', 'name', 'address']


class FacultySerializer(serializers.ModelSerializer):
    university_name = serializers.CharField(source='university.name', read_only=True)

    class Meta:
        model = Faculty
        fields = [
            'id',
            'university',
            'university_name',
            'campus',
            'name',
            'slug',
            'description',
            'is_verified',
            'is_user_suggested',
        ]


class DepartmentSerializer(serializers.ModelSerializer):
    faculty_name = serializers.CharField(source='faculty.name', read_only=True)
    university = serializers.IntegerField(source='faculty.university_id', read_only=True)

    class Meta:
        model = Department
        fields = [
            'id',
            'faculty',
            'faculty_name',
            'university',
            'name',
            'slug',
            'description',
            'is_verified',
            'is_user_suggested',
        ]


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = [
            'id',
            'department',
            'name',
            'year',
            'level',
            'is_verified',
            'is_user_suggested',
        ]


class LearningDomainSerializer(serializers.ModelSerializer):
    class Meta:
        model = LearningDomain
        fields = [
            'id',
            'slug',
            'name',
            'description',
            'keywords',
            'is_active',
            'order',
        ]


class CourseValidationLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = CourseValidationLog
        fields = [
            'id',
            'course',
            'actor',
            'actor_name',
            'action',
            'note',
            'domain_slugs',
            'created_at',
        ]
        read_only_fields = fields

    def get_actor_name(self, obj):
        if obj.actor_id is None:
            return ''
        return obj.actor.get_full_name() or obj.actor.email


class CourseListSerializer(serializers.ModelSerializer):
    """Payload léger pour listes (Apprendre / Ma Fac) — sans bios ni textes longs."""

    department_name = serializers.CharField(source='department.name', read_only=True)
    faculty_name = serializers.CharField(
        source='department.faculty.name',
        read_only=True,
        default='',
    )
    university_name = serializers.CharField(
        source='department.faculty.university.name',
        read_only=True,
        default='',
    )
    document_count = serializers.SerializerMethodField()
    teacher_names = serializers.SerializerMethodField()
    teacher_full_name = serializers.SerializerMethodField()
    promotion = serializers.SerializerMethodField()
    domains = LearningDomainSerializer(many=True, read_only=True)
    submitted_by_name = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            'id',
            'department',
            'department_name',
            'faculty_name',
            'university_name',
            'code',
            'title',
            'credits',
            'semester',
            'promotion',
            'cover_url',
            'level_label',
            'estimated_hours',
            'teacher_name',
            'teacher_names',
            'teacher_full_name',
            'document_count',
            'views',
            'is_approved',
            'moderation_status',
            'moderation_note',
            'domains',
            'submitted_by',
            'submitted_by_name',
        ]

    def get_document_count(self, obj):
        annotated = getattr(obj, 'approved_document_count', None)
        if annotated is not None:
            return annotated
        return obj.documents.filter(is_approved=True).count()

    def get_teacher_names(self, obj):
        names = [u.get_full_name() or u.email for u in obj.teachers.all()]
        if names:
            return names
        tn = (obj.teacher_name or '').strip()
        return [tn] if tn else []

    def get_teacher_full_name(self, obj):
        teachers = list(obj.teachers.all())
        if teachers:
            return teachers[0].get_full_name() or teachers[0].email
        return (obj.teacher_name or '').strip()

    def get_submitted_by_name(self, obj):
        if obj.submitted_by_id is None:
            return ''
        return obj.submitted_by.get_full_name() or obj.submitted_by.email

    def get_promotion(self, obj):
        if obj.promotion_id:
            return obj.promotion.name
        s = (obj.semester or '').strip()
        mapping = {
            'L1': 'L1',
            'L2': 'L2',
            'L3': 'L3',
            'Master 1': 'M1',
            'Master 2': 'M2',
            'M1': 'M1',
            'M2': 'M2',
        }
        return mapping.get(s, s)


class CourseSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    faculty_name = serializers.CharField(
        source='department.faculty.name',
        read_only=True,
        default='',
    )
    university_name = serializers.CharField(
        source='department.faculty.university.name',
        read_only=True,
        default='',
    )
    document_count = serializers.SerializerMethodField()
    teacher_names = serializers.SerializerMethodField()
    teacher_title = serializers.SerializerMethodField()
    teacher_full_name = serializers.SerializerMethodField()
    teacher_headline = serializers.SerializerMethodField()
    teacher_bio = serializers.SerializerMethodField()
    teacher_specialty = serializers.SerializerMethodField()
    teacher_avatar_url = serializers.SerializerMethodField()
    teacher_university = serializers.SerializerMethodField()
    promotion = serializers.SerializerMethodField()
    domains = LearningDomainSerializer(many=True, read_only=True)
    domain_ids = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=LearningDomain.objects.filter(is_active=True),
        source='domains',
        write_only=True,
        required=False,
    )
    submitted_by_name = serializers.SerializerMethodField()
    validation_logs = CourseValidationLogSerializer(many=True, read_only=True)

    class Meta:
        model = Course
        fields = [
            'id',
            'department',
            'department_name',
            'faculty_name',
            'university_name',
            'code',
            'title',
            'description',
            'objectives',
            'skills',
            'prerequisites',
            'bibliography',
            'credits',
            'semester',
            'promotion',
            'cover_url',
            'level_label',
            'estimated_hours',
            'teacher_name',
            'teachers',
            'teacher_names',
            'teacher_title',
            'teacher_full_name',
            'teacher_headline',
            'teacher_bio',
            'teacher_specialty',
            'teacher_avatar_url',
            'teacher_university',
            'document_count',
            'views',
            'domains',
            'domain_ids',
            'is_approved',
            'moderation_status',
            'moderation_note',
            'submitted_by',
            'submitted_by_name',
            'validated_by',
            'validated_at',
            'validation_logs',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'created_at',
            'updated_at',
            'is_approved',
            'moderation_status',
            'submitted_by',
            'validated_by',
            'validated_at',
            'validation_logs',
            'views',
        ]

    def get_document_count(self, obj):
        annotated = getattr(obj, 'approved_document_count', None)
        if annotated is not None:
            return annotated
        return obj.documents.filter(is_approved=True).count()

    def get_teacher_names(self, obj):
        return [u.get_full_name() or u.email for u in obj.teachers.all()]

    def _teacher(self, obj):
        if not hasattr(obj, '_akadex_teacher_payload'):
            obj._akadex_teacher_payload = teacher_payload(obj)
        return obj._akadex_teacher_payload

    def get_teacher_title(self, obj):
        return self._teacher(obj)['teacher_title']

    def get_teacher_full_name(self, obj):
        name = self._teacher(obj)['teacher_full_name']
        if name:
            return name
        return (obj.teacher_name or '').strip()

    def get_teacher_headline(self, obj):
        return self._teacher(obj)['teacher_headline']

    def get_teacher_bio(self, obj):
        return self._teacher(obj)['teacher_bio']

    def get_teacher_specialty(self, obj):
        return self._teacher(obj)['teacher_specialty']

    def get_teacher_avatar_url(self, obj):
        return self._teacher(obj)['teacher_avatar_url']

    def get_teacher_university(self, obj):
        return self._teacher(obj)['teacher_university']

    def get_submitted_by_name(self, obj):
        if obj.submitted_by_id is None:
            return ''
        return obj.submitted_by.get_full_name() or obj.submitted_by.email

    def get_promotion(self, obj):
        if obj.promotion_id:
            return obj.promotion.name
        s = (obj.semester or '').strip()
        if not s:
            return ''
        mapping = {
            'L1': 'L1',
            'L2': 'L2',
            'L3': 'L3',
            'Master 1': 'M1',
            'Master 2': 'M2',
            'M1': 'M1',
            'M2': 'M2',
        }
        return mapping.get(s, s)


class CourseContributeSerializer(serializers.ModelSerializer):
    """Soumission d’un cours (étudiant en attente, enseignant publié)."""

    domain_slugs = serializers.ListField(
        child=serializers.SlugField(max_length=64),
        required=False,
        allow_empty=True,
        write_only=True,
    )

    class Meta:
        model = Course
        fields = [
            'id',
            'title',
            'code',
            'description',
            'objectives',
            'skills',
            'prerequisites',
            'estimated_hours',
            'teacher_name',
            'semester',
            'credits',
            'level_label',
            'cover_url',
            'domain_slugs',
        ]
        extra_kwargs = {
            'code': {'required': False, 'allow_blank': True},
            'description': {'required': False, 'allow_blank': True},
            'objectives': {'required': False, 'allow_blank': True},
            'skills': {'required': False, 'allow_blank': True},
            'prerequisites': {'required': False, 'allow_blank': True},
            'estimated_hours': {'required': False},
            'teacher_name': {'required': False, 'allow_blank': True},
            'semester': {'required': False, 'allow_blank': True},
            'credits': {'required': False},
            'level_label': {'required': False, 'allow_blank': True},
            'cover_url': {'required': False, 'allow_blank': True},
        }

    def validate_title(self, value):
        title = (value or '').strip()
        if len(title) < 3:
            raise serializers.ValidationError(
                'L’intitulé du cours est trop court.'
            )
        return title

    def create(self, validated_data):
        domain_slugs = validated_data.pop('domain_slugs', None) or []
        course = super().create(validated_data)
        if domain_slugs:
            domains = LearningDomain.objects.filter(
                slug__in=domain_slugs,
                is_active=True,
            )
            course.domains.set(domains)
        return course


class DocumentCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()

    class Meta:
        model = DocumentComment
        fields = ['id', 'document', 'author', 'author_name', 'content', 'created_at']
        read_only_fields = ['author', 'created_at']

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email


class DocumentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    university_name = serializers.CharField(source='university.name', read_only=True)
    department_name = serializers.CharField(
        source='department.name',
        read_only=True,
        default='',
    )
    course_code = serializers.CharField(source='course.code', read_only=True, default='')
    course_title = serializers.CharField(
        source='course.title',
        read_only=True,
        default='',
    )
    size_label = serializers.CharField(read_only=True)
    doc_type_display = serializers.CharField(
        source='get_doc_type_display',
        read_only=True,
    )
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Document
        fields = [
            'id',
            'title',
            'description',
            'doc_type',
            'doc_type_display',
            'author',
            'author_name',
            'university',
            'university_name',
            'department',
            'department_name',
            'course',
            'course_code',
            'course_title',
            'academic_year',
            'file',
            'external_url',
            'file_size',
            'size_label',
            'downloads',
            'views',
            'favorites_count',
            'rating_avg',
            'rating_count',
            'is_approved',
            'moderation_status',
            'rejection_reason',
            'is_featured',
            'is_favorited',
            'points_awarded',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'author',
            'downloads',
            'views',
            'favorites_count',
            'rating_avg',
            'rating_count',
            'is_approved',
            'moderation_status',
            'rejection_reason',
            'points_awarded',
            'created_at',
            'updated_at',
        ]

    def get_author_name(self, obj):
        if not obj.author:
            return ''
        return obj.author.get_full_name() or obj.author.email

    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.favorited_by.filter(user=request.user).exists()


class FavoriteSerializer(serializers.ModelSerializer):
    document_detail = DocumentSerializer(source='document', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'document', 'document_detail', 'created_at']
        read_only_fields = ['created_at']


class AnnouncementSerializer(serializers.ModelSerializer):
    university_name = serializers.CharField(source='university.name', read_only=True)

    class Meta:
        model = Announcement
        fields = [
            'id',
            'university',
            'university_name',
            'title',
            'body',
            'category',
            'author',
            'is_published',
            'created_at',
        ]
        read_only_fields = ['author', 'created_at']


class CalendarEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CalendarEvent
        fields = [
            'id',
            'university',
            'title',
            'description',
            'event_type',
            'starts_at',
            'ends_at',
            'location',
            'created_at',
        ]


class RewardPrizeSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(
        source='get_category_display',
        read_only=True,
    )

    class Meta:
        model = RewardPrize
        fields = [
            'id',
            'name',
            'description',
            'category',
            'category_display',
            'min_points',
            'points_cost',
            'weight',
            'is_active',
        ]


class RewardRedemptionSerializer(serializers.ModelSerializer):
    prize_detail = RewardPrizeSerializer(source='prize', read_only=True)

    class Meta:
        model = RewardRedemption
        fields = ['id', 'prize', 'prize_detail', 'points_spent', 'created_at']
        read_only_fields = ['points_spent', 'created_at']
