from django.contrib import admin

from .models import (
    CourseComment,
    CourseLesson,
    CourseModule,
    LessonProgress,
    StudentLearningEvent,
)


@admin.register(CourseModule)
class CourseModuleAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'order')
    list_filter = ('course__department',)
    ordering = ('course', 'order')


@admin.register(CourseLesson)
class CourseLessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'content_type', 'order', 'is_published')
    list_filter = ('content_type', 'is_published')


@admin.register(StudentLearningEvent)
class StudentLearningEventAdmin(admin.ModelAdmin):
    list_display = (
        'event_type',
        'student',
        'course',
        'lesson',
        'teacher',
        'created_at',
    )
    list_filter = ('event_type',)
    search_fields = (
        'student__email',
        'student__first_name',
        'student__last_name',
        'course__title',
        'lesson__title',
    )
    readonly_fields = ('created_at',)


admin.site.register(CourseComment)
admin.site.register(LessonProgress)
