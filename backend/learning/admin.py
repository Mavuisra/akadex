from django.contrib import admin

from .models import CourseComment, CourseLesson, CourseModule, LessonProgress


@admin.register(CourseModule)
class CourseModuleAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'order')
    list_filter = ('course__department',)
    ordering = ('course', 'order')


@admin.register(CourseLesson)
class CourseLessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'content_type', 'order', 'is_published')
    list_filter = ('content_type', 'is_published')


admin.site.register(CourseComment)
admin.site.register(LessonProgress)
