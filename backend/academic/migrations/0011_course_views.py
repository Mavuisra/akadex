from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0010_course_collaboration_and_domains'),
    ]

    operations = [
        migrations.AddField(
            model_name='course',
            name='views',
            field=models.PositiveIntegerField(
                default=0,
                help_text='Nombre de consultations de la page cours',
            ),
        ),
    ]
