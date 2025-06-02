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



class ProfileUserUpdateAPIView(APIView):
    # permission_classes = [IsAuthenticated]

    def put(self, request):
        data = request.data
        user_id = data['user_id']

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            set_parts = []
            if 'first_name' in data:
                set_parts.append(f"first_name = '{data['first_name']}'")
            if 'last_name' in data:
                set_parts.append(f"last_name = '{data['last_name']}'")
            if 'phone_number' in data:
                set_parts.append(f"phone_number = '{data['phone_number']}'")
            if 'birth_date' in data:
                set_parts.append(f"birth_date = '{data['birth_date']}'")

            if not set_parts:
                return Response({'error': 'No valid fields provided'}, status=400)


            query = f"UPDATE User SET {', '.join(set_parts)} WHERE user_id = {user_id}"
            cursor.execute(query)
            conn.commit()

            redis_key = f"user_profile:{user_id}"
            redis_client.delete(redis_key)

            cursor.close()
            conn.close()

            return Response({'message': 'Profile updated successfully'})

        except Exception as e:
            return Response({'error': str(e)}, status=500)