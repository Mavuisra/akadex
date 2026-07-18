from rest_framework import serializers

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    Department,
    Document,
    DocumentComment,
    Faculty,
    Favorite,
    Promotion,
    RewardPrize,
    RewardRedemption,
    University,
)


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
        ]


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ['id', 'department', 'name', 'year', 'level']


class CourseSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    document_count = serializers.IntegerField(read_only=True)
    teacher_names = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            'id',
            'department',
            'department_name',
            'code',
            'title',
            'description',
            'objectives',
            'skills',
            'prerequisites',
            'bibliography',
            'credits',
            'semester',
            'teachers',
            'teacher_names',
            'document_count',
            'created_at',
        ]
        read_only_fields = ['created_at']

    def get_teacher_names(self, obj):
        return [u.get_full_name() or u.email for u in obj.teachers.all()]


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
            'is_featured',
            'is_favorited',
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
