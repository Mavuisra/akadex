from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0012_document_peer_validation'),
    ]

    operations = [
        migrations.AddField(
            model_name='documentpeervalidation',
            name='score',
            field=models.PositiveSmallIntegerField(
                default=5,
                help_text='Note de 1 à 5 étoiles.',
            ),
        ),
    ]
