import MySQLdb
from django.http import JsonResponse
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


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class CityListView(APIView):
    def get(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return JsonResponse({"error": "Authentication credentials were not provided."}, status=401)

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