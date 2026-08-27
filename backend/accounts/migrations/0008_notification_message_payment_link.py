# Generated manually for Vague B notifications

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_password_reset_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='appnotification',
            name='link',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AlterField(
            model_name='appnotification',
            name='kind',
            field=models.CharField(
                choices=[
                    ('document_approved', 'Document validé'),
                    ('document_rejected', 'Document refusé'),
                    ('post_approved', 'Publication validée'),
                    ('post_rejected', 'Publication refusée'),
                    ('points', 'Points'),
                    ('message', 'Message'),
                    ('payment', 'Paiement'),
                    ('general', 'Général'),
                ],
                default='general',
                max_length=32,
            ),
        ),
    ]
