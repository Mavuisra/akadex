# Generated manually for academic share posts + attachments

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0005_sync_post_moderation'),
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
                    ('alumni_advice', 'Conseil académique'),
                    ('alumni_path', 'Parcours universitaire'),
                    ('alumni_career', 'Parcours professionnel'),
                    ('alumni_tfc', 'Stages / mémoire / TFC'),
                    ('alumni_video', 'Vidéo de conseil'),
                ],
                db_index=True,
                default='discussion',
                max_length=32,
            ),
        ),
        migrations.AddField(
            model_name='post',
            name='file',
            field=models.FileField(blank=True, null=True, upload_to='posts/'),
        ),
        migrations.AddField(
            model_name='post',
            name='image',
            field=models.ImageField(blank=True, null=True, upload_to='posts/images/'),
        ),
        migrations.AddField(
            model_name='post',
            name='file_url',
            field=models.URLField(blank=True, max_length=1000),
        ),
        migrations.AddField(
            model_name='post',
            name='page_count',
            field=models.PositiveSmallIntegerField(default=0),
        ),
    ]
