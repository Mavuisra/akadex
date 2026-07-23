from rest_framework import serializers

from academic.models import Course
from academic.serializers import LearningDomainSerializer, teacher_payload

from .models import CourseComment, CourseLesson, CourseModule, LessonProgress


class CourseLessonSerializer(serializers.ModelSerializer):
    content_type_display = serializers.CharField(
        source='get_content_type_display',
        read_only=True,
    )
    course_id = serializers.IntegerField(source='module.course_id', read_only=True)

    class Meta:
        model = CourseLesson
        fields = [
            'id',
            'module',
            'course_id',
            'title',
            'description',
            'content_type',
            'content_type_display',
            'order',
            'video_url',
            'file',
            'external_url',
            'duration_seconds',
            'subtitles_url',
            'document',
            'is_published',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class CourseModuleSerializer(serializers.ModelSerializer):
    lessons = CourseLessonSerializer(many=True, read_only=True)
    lessons_count = serializers.SerializerMethodField()
    course_title = serializers.CharField(source='course.title', read_only=True)
    course_code = serializers.CharField(source='course.code', read_only=True)

    class Meta:
        model = CourseModule
        fields = [
            'id',
            'course',
            'course_title',
            'course_code',
            'title',
            'description',
            'order',
            'lessons',
            'lessons_count',
            'created_at',
        ]
        read_only_fields = ['created_at']

    def get_lessons_count(self, obj):
        return obj.lessons.filter(is_published=True).count()


class CourseOutlineSerializer(serializers.ModelSerializer):
    """Vue riche type Coursera pour une page cours."""

    department_name = serializers.CharField(source='department.name', read_only=True)
    faculty_name = serializers.CharField(
        source='department.faculty.name',
        read_only=True,
    )
    university_name = serializers.CharField(
        source='department.faculty.university.name',
        read_only=True,
    )
    teacher_names = serializers.SerializerMethodField()
    teacher_title = serializers.SerializerMethodField()
    teacher_full_name = serializers.SerializerMethodField()
    teacher_headline = serializers.SerializerMethodField()
    teacher_bio = serializers.SerializerMethodField()
    teacher_specialty = serializers.SerializerMethodField()
    teacher_avatar_url = serializers.SerializerMethodField()
    teacher_university = serializers.SerializerMethodField()
    promotion = serializers.SerializerMethodField()
    modules = CourseModuleSerializer(many=True, read_only=True)
    document_count = serializers.IntegerField(read_only=True)
    domains = LearningDomainSerializer(many=True, read_only=True)

    class Meta:
        model = Course
        fields = [
            'id',
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
            'views',
            'teacher_name',
            'department',
            'department_name',
            'faculty_name',
            'university_name',
            'teacher_names',
            'teacher_title',
            'teacher_full_name',
            'teacher_headline',
            'teacher_bio',
            'teacher_specialty',
            'teacher_avatar_url',
            'teacher_university',
            'document_count',
            'modules',
            'domains',
            'is_approved',
            'moderation_status',
            'moderation_note',
            'created_at',
        ]

    def get_teacher_names(self, obj):
        names = [t.get_full_name() or t.email for t in obj.teachers.all()]
        if names:
            return names
        if (obj.teacher_name or '').strip():
            return [obj.teacher_name.strip()]
        return []

    def get_teacher_title(self, obj):
        return teacher_payload(obj)['teacher_title']

    def get_teacher_full_name(self, obj):
        name = teacher_payload(obj)['teacher_full_name']
        if name:
            return name
        return (obj.teacher_name or '').strip()

    def get_teacher_headline(self, obj):
        return teacher_payload(obj)['teacher_headline']

    def get_teacher_bio(self, obj):
        return teacher_payload(obj)['teacher_bio']

    def get_teacher_specialty(self, obj):
        return teacher_payload(obj)['teacher_specialty']

    def get_teacher_avatar_url(self, obj):
        return teacher_payload(obj)['teacher_avatar_url']

    def get_teacher_university(self, obj):
        return teacher_payload(obj)['teacher_university']

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


class CourseCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    author_role = serializers.CharField(source='author.role', read_only=True)

    class Meta:
        model = CourseComment
        fields = [
            'id',
            'course',
            'lesson',
            'author',
            'author_name',
            'author_role',
            'content',
            'parent',
            'created_at',
        ]
        read_only_fields = ['author', 'created_at']

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email


class LessonProgressSerializer(serializers.ModelSerializer):
    class Meta:
        model = LessonProgress
        fields = [
            'id',
            'lesson',
            'position_seconds',
            'completed',
            'updated_at',
        ]
        read_only_fields = ['updated_at']
