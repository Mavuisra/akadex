# Generated manually for rapport / projet_tutore / tfc / memoire post kinds

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0007_post_background_color'),
    ]

    operations = [
        migrations.AlterField(
            model_name='post',
            name='kind',
            field=models.CharField(
                choices=[
                    ('discussion', 'Discussion'),
                    ('question', 'Question'),
                    ('tp', 'TP / TD'),
                    ('summary', 'Résumé de cours'),
                    ('exam', 'Examen corrigé'),
                    ('notes', 'Notes de cours'),
                    ('support', 'Support de cours'),
                    ('rapport', 'Rapport de stage'),
                    ('projet_tutore', 'Projet tuteuré'),
                    ('tfc', 'TFC'),
                    ('memoire', 'Mémoire'),
                    ('alumni_advice', 'Conseil académique'),
                    ('alumni_path', 'Parcours universitaire'),
                    ('alumni_career', 'Parcours professionnel'),
                    ('alumni_tfc', 'Stages / mémoire / TFC'),
                    ('alumni_video', 'Vidéo de conseil'),
                ],
                default='discussion',
                max_length=32,
            ),
        ),
    ]
