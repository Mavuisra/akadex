from decimal import Decimal

from rest_framework import serializers

from .pawapay import PROVIDERS


class InitiateDepositSerializer(serializers.Serializer):
    phone = serializers.CharField(min_length=9, max_length=20)
    provider = serializers.ChoiceField(choices=list(PROVIDERS.keys()))
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal('0.01'),
    )
    course_ids = serializers.ListField(
        child=serializers.CharField(max_length=64),
        required=False,
        allow_empty=True,
        default=list,
    )
    statement = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=22,
        default='Akadex cours',
    )
