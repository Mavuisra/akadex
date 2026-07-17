from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    university_name = serializers.CharField(
        source='university.name',
        read_only=True,
        default='',
    )
    faculty_name = serializers.CharField(
        source='faculty.name',
        read_only=True,
        default='',
    )
    department_name = serializers.CharField(
        source='department.name',
        read_only=True,
        default='',
    )
    promotion_name = serializers.CharField(
        source='promotion.name',
        read_only=True,
        default='',
    )

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'username',
            'first_name',
            'last_name',
            'full_name',
            'phone',
            'role',
            'avatar',
            'bio',
            'university',
            'university_name',
            'faculty',
            'faculty_name',
            'department',
            'department_name',
            'promotion',
            'promotion_name',
            'level',
            'reputation',
            'contributions_count',
            'badges',
            'date_joined',
        ]
        read_only_fields = [
            'id',
            'reputation',
            'contributions_count',
            'badges',
            'date_joined',
        ]

    def get_full_name(self, obj):
        return obj.get_full_name() or obj.email


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'email',
            'username',
            'password',
            'password_confirm',
            'first_name',
            'last_name',
            'phone',
            'role',
            'university',
            'faculty',
            'department',
            'promotion',
            'level',
            'bio',
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError(
                {'password_confirm': 'Les mots de passe ne correspondent pas.'}
            )
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user
