import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import hashlib
import json
import redis
from datetime import timedelta
from ..utils.jwt import generate_access_token, generate_refresh_token

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class LoginAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')

        if not email or not password:
            return Response({'error': 'Email and password are required'}, status=400)

        conn = None
        cursor = None
        try:
            conn = MySQLdb.connect(host="db", user="root", password="Aliprs2005", database="safarticket", port=3306)
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)
            
            cursor.execute("SELECT * FROM User WHERE email = %s", (email,))
            user_data_dict = cursor.fetchone()

            if not user_data_dict:
                return Response({'error': 'Invalid credentials'}, status=401)
            
            if user_data_dict['account_status'] != 'ACTIVE':
                return Response({'error': 'Account is not active. Please verify your email first.'}, status=403)

            password_hash = hashlib.sha256(password.encode()).hexdigest()
            if user_data_dict['password_hash'] != password_hash:
                return Response({'error': 'Invalid credentials'}, status=401)

            user_id = user_data_dict['user_id']

            try:
                user_profile_json = json.dumps(user_data_dict, default=str)
                redis_key = f"user_profile:{user_id}"
                redis_client.setex(redis_key, timedelta(seconds=360), user_profile_json)
            except redis.exceptions.RedisError as e:
                pass

            access_token = generate_access_token(user_id, email)
            refresh_token = generate_refresh_token(user_id)

            return Response({
                'access': access_token,
                'refresh': refresh_token
            }, status=200)

        except MySQLdb.Error as e:
            return Response({'error': f"Database error: {str(e)}"}, status=500)
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()