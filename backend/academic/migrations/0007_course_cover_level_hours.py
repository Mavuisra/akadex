# Generated manually for cover_url / level / hours

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0006_profile_edit_and_rdc_suggest'),
    ]

    operations = [
        migrations.AddField(
            model_name='course',
            name='cover_url',
            field=models.URLField(blank=True, help_text='Image de couverture (URL publique)', max_length=500),
        ),
        migrations.AddField(
            model_name='course',
            name='level_label',
            field=models.CharField(blank=True, help_text='Débutant / Intermédiaire / Avancé', max_length=32),
        ),
        migrations.AddField(
            model_name='course',
            name='estimated_hours',
            field=models.PositiveSmallIntegerField(default=0, help_text='Durée estimée en heures'),
        ),
    ]
