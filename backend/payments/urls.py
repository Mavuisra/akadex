from django.urls import path

from .views import (
    CatalogPricingView,
    DepositCallbackView,
    DepositStatusView,
    InitiateDepositView,
    MyPurchasedCoursesView,
    PaymentsHealthView,
    ProvidersView,
)

urlpatterns = [
    path('payments/health/', PaymentsHealthView.as_view(), name='payment-health'),
    path('payments/pricing/', CatalogPricingView.as_view(), name='payment-pricing'),
    path('payments/providers/', ProvidersView.as_view(), name='payment-providers'),
    path('payments/my-courses/', MyPurchasedCoursesView.as_view(), name='payment-my-courses'),
    path('payments/deposits/', InitiateDepositView.as_view(), name='payment-deposit-create'),
    path(
        'payments/deposits/callback/',
        DepositCallbackView.as_view(),
        name='payment-deposit-callback',
    ),
    path(
        'payments/deposits/<uuid:deposit_id>/',
        DepositStatusView.as_view(),
        name='payment-deposit-status',
    ),
]
