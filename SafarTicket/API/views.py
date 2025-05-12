import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis
from rest_framework.views import APIView
from rest_framework.response import Response
import mysql.connector
from .serializers import UserSerializer
from .jwt import generate_jwt

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
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

        otp = str(random.randint(100000, 999999))
        redis_client.setex(f"otp:{email}", 300, otp)

        print(f"[OTP] Sent to {email}: {otp}")  # شبیه‌سازی ارسال

        return Response({'message': 'OTP sent to email'}, status=status.HTTP_200_OK)


class VerifyOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=400)

        saved_otp = redis_client.get(f"otp:{email}")
        if saved_otp is None or otp != saved_otp.decode():
            return Response({'error': 'Invalid or expired OTP'}, status=400)

        # اتصال به MySQL
        conn = mysql.connector.connect(
            host="db",
            user="root",
            password="Aliprs2005",
            database="safarticket"
        )
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT user_id, first_name, last_name, email, phone_number, user_type, city_id, registration_date, account_status FROM User WHERE email = %s", (email,))
        user_data = cursor.fetchone()

        cursor.close()
        conn.close()

        if not user_data:
            return Response({'error': 'User not found'}, status=404)

        token = generate_jwt({'user_id': user_data['user_id'], 'email': user_data['email']})

        serializer = UserSerializer(user_data)

        return Response({
            'token': token,
            'user': serializer.data
        })