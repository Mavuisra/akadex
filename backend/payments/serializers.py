from decimal import Decimal

from django.conf import settings
from rest_framework import serializers

from .pawapay import PROVIDERS


class InitiateDepositSerializer(serializers.Serializer):
    phone = serializers.CharField(min_length=9, max_length=20)
    provider = serializers.ChoiceField(choices=list(PROVIDERS.keys()))
    # Montant client ignoré : recalculé serveur (COURSE_SALE_PRICE_USD × n cours).
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal('0.01'),
        required=False,
        allow_null=True,
    )
    course_ids = serializers.ListField(
        child=serializers.CharField(max_length=64),
        required=True,
        allow_empty=False,
    )
    statement = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=22,
        default='Akadex cours',
    )

    def validate(self, attrs):
        course_ids = attrs.get('course_ids') or []
        sale = getattr(settings, 'COURSE_SALE_PRICE_USD', Decimal('15'))
        if not isinstance(sale, Decimal):
            sale = Decimal(str(sale))
        expected = (sale * len(course_ids)).quantize(Decimal('0.01'))
        client_amount = attrs.get('amount')
        if client_amount is not None:
            client = Decimal(str(client_amount)).quantize(Decimal('0.01'))
            if abs(client - expected) > Decimal('0.01'):
                raise serializers.ValidationError(
                    {
                        'amount': (
                            f'Montant invalide. Attendu {expected} USD '
                            f'pour {len(course_ids)} cours.'
                        ),
                    }
                )
        attrs['amount'] = expected
        return attrs
