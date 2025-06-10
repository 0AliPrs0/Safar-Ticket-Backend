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
from ..utils.jwt import generate_access_token, generate_refresh_token, verify_jwt
from rest_framework.permissions import IsAuthenticated
import json
from datetime import datetime, timedelta
from rest_framework_simplejwt.tokens import RefreshToken
from ..utils.jwt import generate_access_token, generate_refresh_token

redis_client = redis.Redis(host='redis', port=6379, db=0)
        

class SendOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return JsonResponse({'error': 'Email is required'}, status=400)

        otp = str(random.randint(100000, 999999))
        redis_client.setex(f"otp:{email}", 300, otp)

        try:
            send_otp_email(email, otp)
        except Exception:
            return JsonResponse({'error': 'Failed to send email. Try again later.'}, status=500)

        return JsonResponse({'message': 'OTP sent to your email'}, status=200)





class VerifyOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=400)

        saved_otp_bytes = redis_client.get(f"otp:{email}")
        if not saved_otp_bytes or saved_otp_bytes.decode() != otp:
            return Response({'error': 'Invalid or expired OTP'}, status=400)
        
        redis_client.delete(f"otp:{email}")

        conn = None
        cursor = None
        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306,
                cursorclass=MySQLdb.cursors.DictCursor
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_id FROM User WHERE email = %s", (email,))
            user_row = cursor.fetchone()

            if not user_row:
                return Response({"error": "User with this email does not exist. Please sign up first."}, status=404)
            
            user_id = user_row['user_id']

            access_token = generate_access_token(user_id, email)
            refresh_token = generate_refresh_token(user_id)

            return Response({
                'access': access_token,
                'refresh': refresh_token
            }, status=200)

        except MySQLdb.Error as e:
            return Response({"error": f"Database error: {str(e)}"}, status=500)
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()