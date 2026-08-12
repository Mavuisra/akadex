from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


def migrate_pending_to_peers(apps, schema_editor):
    Document = apps.get_model('academic', 'Document')
    Document.objects.filter(moderation_status='pending', is_approved=False).update(
        moderation_status='pending_peers',
    )


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('academic', '0011_course_views'),
    ]

    operations = [
        migrations.CreateModel(
            name='DocumentPeerValidation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('document', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='peer_validations', to='academic.document')),
                ('validator', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='document_peer_validations', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['created_at'],
                'unique_together': {('document', 'validator')},
            },
        ),
        migrations.AlterField(
            model_name='document',
            name='moderation_status',
            field=models.CharField(
                choices=[
                    ('pending_peers', 'En attente validation fac'),
                    ('pending_admin', 'En attente validation admin'),
                    ('pending', 'En attente'),
                    ('approved', 'Validée'),
                    ('rejected', 'Refusée'),
                ],
                db_index=True,
                default='pending_peers',
                max_length=16,
            ),
        ),
        migrations.RunPython(migrate_pending_to_peers, migrations.RunPython.noop),
    ]
