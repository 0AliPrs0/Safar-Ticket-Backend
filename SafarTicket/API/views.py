import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis
from rest_framework.views import APIView
from rest_framework.response import Response
import mysql.connector
from .utils.email_utils import send_otp_email
from .serializers import UserSerializer
from .jwt import generate_jwt
import datetime

class CityListView(View):
    def get(self, request):
        try:
            db = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = db.cursor()
            cursor.execute("SELECT city_id, province_name, city_name FROM City")
            rows = cursor.fetchall()

            cities = []
            for row in rows:
                cities.append({
                    "city_id": row[0],
                    "province_name": row[1],
                    "city_name": row[2]
                })

            cursor.close()
            db.close()

            return JsonResponse(cities, safe=False)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
        

redis_client = redis.Redis(host='redis', port=6379, db=0)

class SendOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=400)

        otp = str(random.randint(100000, 999999))
        redis_client.setex(f"otp:{email}", 300, otp)

        try:
            send_otp_email(email, otp)
        except Exception:
            return Response({'error': 'Failed to send email. Try again later.'}, status=500)

        return Response({'message': 'OTP sent to your email'}, status=200)



class VerifyOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=400)

        saved_otp = redis_client.get(f"otp:{email}")
        if not saved_otp or saved_otp.decode() != otp:
            return Response({'error': 'Invalid or expired OTP'}, status=400)

        conn = mysql.connector.connect(
            host="db",
            user="root",
            password="Aliprs2005",
            database="safarticket"
        )
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT * FROM User WHERE email = %s", (email,))
        user_data = cursor.fetchone()

        if not user_data:
            registration_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            cursor.execute("""
                INSERT INTO User (first_name, last_name, email, user_type, city_id, registration_date, account_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, ("", "", email, "passenger", 1, registration_date, "active"))

            conn.commit()
            user_id = cursor.lastrowid
            user_data = {
                "user_id": user_id,
                "first_name": "",
                "last_name": "",
                "email": email,
                "phone_number": None,
                "user_type": "passenger",
                "city_id": 1,
                "registration_date": registration_date,
                "account_status": "active"
            }

        cursor.close()
        conn.close()

        token = generate_jwt({'user_id': user_data['user_id'], 'email': user_data['email']})
        serializer = UserSerializer(user_data)

        return Response({
            'token': token,
            'user': serializer.data
        }, status=200)