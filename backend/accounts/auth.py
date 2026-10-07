from rest_framework.throttling import AnonRateThrottle
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import UserSerializer


class AuthAnonThrottle(AnonRateThrottle):
    scope = 'auth'


class AuthBurstThrottle(AnonRateThrottle):
    scope = 'auth_burst'


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """JWT via email (USERNAME_FIELD du modèle User)."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        # Ne jamais renvoyer le hash mot de passe ; serializer user déjà safe.
        data['user'] = UserSerializer(self.user, context=self.context).data
        return data


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer
    throttle_classes = [AuthBurstThrottle, AuthAnonThrottle]
