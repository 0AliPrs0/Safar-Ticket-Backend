import jwt
from django.conf import settings
import datetime

def generate_jwt(payload):
    exp = datetime.datetime.utcnow() + datetime.timedelta(seconds=settings.JWT_EXP_DELTA_SECONDS)
    payload['exp'] = exp
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
