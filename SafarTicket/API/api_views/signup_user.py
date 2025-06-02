import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
from ..utils.email_utils import send_otp_email, send_payment_reminder_email 
from ..serializers import UserSerializer 
import datetime
import hashlib 
from ..utils.jwt import generate_jwt 
from rest_framework.permissions import IsAuthenticated
import json
from datetime import datetime, timedelta 


redis_client = redis.Redis(host='redis', port=6379, db=0)



class SignupUserAPIView(APIView):
    def post(self, request):
        data = request.data
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        email = data.get('email')
        phone_number = data.get('phone_number')
        password = data.get('password')
        city_id = data.get('city_id', 1)

        if not all([first_name, last_name, email, phone_number, password]):
            return Response({'error': 'All fields are required'}, status=400)

        password_hash = hashlib.sha256(password.encode()).hexdigest()
        registration_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_id FROM User WHERE email = %s", (email,))
            if cursor.fetchone():
                return Response({'error': 'User with this email already exists'}, status=400)

            cursor.execute("""
                INSERT INTO User (first_name, last_name, email, phone_number, password_hash, user_type, city_id, registration_date, account_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (first_name, last_name, email, phone_number, password_hash, "customer", city_id, registration_date, "active"))

            conn.commit()
            user_id = cursor.lastrowid
            cursor.close()
            conn.close()

            token = generate_jwt({'user_id': user_id, 'email': email})

            return Response({
                'message': 'User registered successfully',
                'token': token,
                'user': {
                    'user_id': user_id,
                    'first_name': first_name,
                    'last_name': last_name,
                    'email': email,
                    'phone_number': phone_number,
                    'user_type': 'customer',
                    'city_id': city_id,
                    'registration_date': registration_date,
                    'account_status': 'active'
                }
            }, status=201)

        except Exception as e:
            return Response({'error': str(e)}, status=500)