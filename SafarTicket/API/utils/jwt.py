import jwt
import datetime
from django.conf import settings

SECRET_KEY = settings.JWT_SECRET_KEY

def generate_jwt(payload, expires_in_minutes=60):
    expiration = datetime.datetime.utcnow() + datetime.timedelta(minutes=expires_in_minutes)
    payload['exp'] = expiration
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token
