from django.urls import path

from .views import DepositStatusView, InitiateDepositView, ProvidersView

urlpatterns = [
    path('payments/providers/', ProvidersView.as_view(), name='payment-providers'),
    path('payments/deposits/', InitiateDepositView.as_view(), name='payment-deposit-create'),
    path(
        'payments/deposits/<uuid:deposit_id>/',
        DepositStatusView.as_view(),
        name='payment-deposit-status',
    ),
]
