from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import AppNotification, PushDeviceToken

User = get_user_model()

SELF_REGISTER_ROLES = {User.Role.STUDENT, User.Role.ALUMNI}


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
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    posts_count = serializers.SerializerMethodField()
    avatar = serializers.SerializerMethodField()
    cover = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'pending_email',
            'username',
            'first_name',
            'last_name',
            'postnom',
            'full_name',
            'phone',
            'role',
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
            'followers_count',
            'following_count',
            'posts_count',
            'date_joined',
            'last_seen_at',
            'is_active',
            'is_staff',
            'is_superuser',
        ]
        read_only_fields = [
            'id',
            'pending_email',
            'reputation',
            'contributions_count',
            'badges',
            'followers_count',
            'following_count',
            'posts_count',
            'date_joined',
            'role',
            'last_seen_at',
            'is_active',
            'is_staff',
            'is_superuser',
        ]

    def get_full_name(self, obj):
        return obj.get_full_name() or obj.email

    def _abs_media(self, file_field):
        from config.media_urls import file_field_url

        return file_field_url(file_field, self.context.get('request')) or None

    def get_avatar(self, obj):
        if getattr(obj, 'photo_url', None):
            return obj.photo_url
        return self._abs_media(obj.avatar)

    def get_cover(self, obj):
        return self._abs_media(obj.cover)

    def get_followers_count(self, obj):
        if hasattr(obj, 'alumni_followers'):
            return obj.alumni_followers.count()
        return 0

    def get_following_count(self, obj):
        if hasattr(obj, 'alumni_following'):
            return obj.alumni_following.count()
        return 0

    def get_posts_count(self, obj):
        if hasattr(obj, 'posts'):
            return obj.posts.filter(moderation_status='approved').count()
        return 0

    def update(self, instance, validated_data):
        import secrets

        request = self.context.get('request')
        files = getattr(request, 'FILES', None) if request else None

        new_email = validated_data.pop('email', None)
        if new_email and new_email.lower() != instance.email.lower():
            if User.objects.filter(email__iexact=new_email).exclude(
                pk=instance.pk
            ).exists():
                raise serializers.ValidationError(
                    {'email': 'Cette adresse e-mail est déjà utilisée.'}
                )
            instance.pending_email = new_email
            instance.email_verification_token = secrets.token_urlsafe(32)
            AppNotification.objects.create(
                user=instance,
                kind=AppNotification.Kind.GENERAL,
                title='Confirme ton nouvel e-mail',
                message=(
                    f'Une demande de changement vers {new_email} a été enregistrée. '
                    f'Code de confirmation : {instance.email_verification_token}'
                ),
            )

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if files:
            if 'avatar' in files:
                instance.avatar = files['avatar']
            if 'cover' in files:
                instance.cover = files['cover']

        instance.save()
        return instance


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
            'postnom',
            'phone',
            'role',
            'gender',
            'birth_date',
            'matricule',
            'university',
            'faculty',
            'department',
            'promotion',
            'level',
            'bio',
            'headline',
            'professional_domain',
            'company',
            'graduation_year',
        ]

    def validate_role(self, value):
        if value not in SELF_REGISTER_ROLES:
            raise serializers.ValidationError(
                'Les comptes enseignants sont créés exclusivement par '
                "l'administrateur. Choisissez Étudiant ou Ancien étudiant."
            )
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError(
                {'password_confirm': 'Les mots de passe ne correspondent pas.'}
            )

        role = attrs.get('role', User.Role.STUDENT)
        required = {
            'first_name': 'Le prénom est obligatoire.',
            'last_name': 'Le nom est obligatoire.',
            'postnom': 'Le postnom est obligatoire.',
            'email': "L'email est obligatoire.",
            'phone': 'Le téléphone est obligatoire.',
            'university': "L'université est obligatoire.",
            'department': 'Le département est obligatoire.',
            'promotion': 'La promotion est obligatoire.',
        }

        if role == User.Role.STUDENT:
            required.update(
                {
                    'gender': 'Le sexe est obligatoire.',
                    'birth_date': 'La date de naissance est obligatoire.',
                }
            )
        elif role == User.Role.ALUMNI:
            required.update(
                {
                    'professional_domain': 'Le domaine professionnel est obligatoire.',
                    'graduation_year': "L'année d'obtention du diplôme est obligatoire.",
                }
            )

        errors = {}
        for field, message in required.items():
            value = attrs.get(field)
            if value is None or value == '':
                errors[field] = message
        if errors:
            raise serializers.ValidationError(errors)
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        if not validated_data.get('username'):
            validated_data['username'] = validated_data['email'].split('@')[0]
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class AppNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppNotification
        fields = [
            'id',
            'kind',
            'title',
            'message',
            'points',
            'is_read',
            'created_at',
        ]
        read_only_fields = fields


class PushTokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=512)
    platform = serializers.ChoiceField(
        choices=PushDeviceToken.Platform.choices,
        default=PushDeviceToken.Platform.UNKNOWN,
        required=False,
    )

    def validate_token(self, value):
        token = value.strip()
        if len(token) < 20:
            raise serializers.ValidationError('Token FCM invalide.')
        return token
