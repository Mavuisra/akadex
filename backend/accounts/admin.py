from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import AppNotification, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ('email',)
    list_display = (
        'email',
        'first_name',
        'postnom',
        'last_name',
        'role',
        'university',
        'reputation',
        'is_staff',
    )
    list_filter = ('role', 'is_staff', 'university', 'gender')
    search_fields = (
        'email',
        'first_name',
        'last_name',
        'postnom',
        'username',
        'matricule',
    )

    fieldsets = DjangoUserAdmin.fieldsets + (
        (
            'Profil Akadex',
            {
                'fields': (
                    'phone',
                    'role',
                    'postnom',
                    'gender',
                    'birth_date',
                    'matricule',
                    'avatar',
                    'cover',
                    'bio',
                    'headline',
                    'professional_domain',
                    'company',
                    'graduation_year',
                    'university',
                    'faculty',
                    'department',
                    'promotion',
                    'level',
                    'reputation',
                    'contributions_count',
                    'badges',
                )
            },
        ),
    )
    add_fieldsets = (
        (
            None,
            {
                'classes': ('wide',),
                'fields': (
                    'email',
                    'username',
                    'password1',
                    'password2',
                    'role',
                    'first_name',
                    'postnom',
                    'last_name',
                ),
            },
        ),
    )


@admin.register(AppNotification)
class AppNotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'kind', 'title', 'points', 'is_read', 'created_at')
    list_filter = ('kind', 'is_read')
    search_fields = ('title', 'message', 'user__email')
