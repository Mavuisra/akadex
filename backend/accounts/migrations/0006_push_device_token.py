# Generated manually for push notifications

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0005_user_photo_url'),
    ]

    operations = [
        migrations.CreateModel(
            name='PushDeviceToken',
            fields=[
                (
                    'id',
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name='ID',
                    ),
                ),
                ('token', models.CharField(max_length=512, unique=True)),
                (
                    'platform',
                    models.CharField(
                        choices=[
                            ('android', 'Android'),
                            ('ios', 'iOS'),
                            ('unknown', 'Inconnu'),
                        ],
                        default='unknown',
                        max_length=16,
                    ),
                ),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                (
                    'user',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='push_tokens',
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                'ordering': ['-updated_at'],
            },
        ),
    ]
