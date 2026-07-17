from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ('email',)
    list_display = (
        'email',
        'first_name',
        'last_name',
        'role',
        'university',
        'reputation',
        'is_staff',
    )
    list_filter = ('role', 'is_staff', 'university')
    search_fields = ('email', 'first_name', 'last_name', 'username')

    fieldsets = DjangoUserAdmin.fieldsets + (
        (
            'Profil Akadex',
            {
                'fields': (
                    'phone',
                    'role',
                    'avatar',
                    'bio',
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
                'fields': ('email', 'username', 'password1', 'password2', 'role'),
            },
        ),
    )
