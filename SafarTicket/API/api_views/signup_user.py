import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import hashlib
import re
import random
import json
import redis
from ..utils.email_utils import send_otp_email
from datetime import timedelta

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class SignupUserAPIView(APIView):
    def _is_password_strong(self, password):
        if len(password) < 8: return False
        if not re.search(r"[a-z]", password): return False
        if not re.search(r"[A-Z]", password): return False
        if not re.search(r"[0-9]", password): return False
        if not re.search(r"[!@#$%^&*(),.?:{}|<>]", password): return False
        return True

    def post(self, request):
        data = request.data
        email = data.get('email')
        password = data.get('password')

        required_fields = ['first_name', 'last_name', 'email', 'phone_number', 'password']
        errors = {}
        for field in required_fields:
            if not data.get(field):
                errors[field] = f"{field.replace('_', ' ')} is required and cannot be empty."
        if errors:
            return Response({'errors': errors}, status=400)

        if not self._is_password_strong(password):
            return Response({'error': 'Password is not strong enough.'}, status=400)

        conn = None
        cursor = None
        try:
            conn = MySQLdb.connect(host="db", user="root", password="Aliprs2005", database="safarticket", port=3306)
            cursor = conn.cursor()
            
            cursor.execute("SELECT user_id FROM User WHERE email = %s", (email,))
            if cursor.fetchone():
                return Response({'error': 'User with this email already exists'}, status=400)

            password_hash = hashlib.sha256(password.encode()).hexdigest()
            data['password_hash'] = password_hash
            
            user_data_json = json.dumps(data)
            
            otp = str(random.randint(100000, 999999))
            
            redis_client.setex(f"temp_user:{email}", timedelta(minutes=5), user_data_json)
            redis_client.setex(f"signup_otp:{email}", timedelta(minutes=5), otp)

            send_otp_email(email, otp)

            return Response({'message': 'OTP sent to your email for account verification.'}, status=200)

        except MySQLdb.Error as e:
            return Response({'error': f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()