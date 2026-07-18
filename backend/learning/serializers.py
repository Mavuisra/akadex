from rest_framework import serializers

from academic.models import Course

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

    class Meta:
        model = CourseModule
        fields = [
            'id',
            'course',
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
    modules = CourseModuleSerializer(many=True, read_only=True)
    document_count = serializers.IntegerField(read_only=True)

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
            'department',
            'department_name',
            'faculty_name',
            'university_name',
            'teacher_names',
            'document_count',
            'modules',
            'created_at',
        ]

    def get_teacher_names(self, obj):
        return [
            t.get_full_name() or t.email
            for t in obj.teachers.all()
        ]


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
