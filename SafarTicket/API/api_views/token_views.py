from rest_framework.views import APIView
from rest_framework.response import Response
from ..utils.jwt import verify_jwt, generate_access_token
import MySQLdb
import redis
import json
from datetime import timedelta

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class RefreshTokenAPIView(APIView):
    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'error': 'Refresh token is required'}, status=400)

        payload = verify_jwt(refresh_token)
        if not payload or payload.get('token_type') != 'refresh':
            return Response({'error': 'Invalid or expired refresh token'}, status=401)

        user_id = payload.get('user_id')

        conn = None
        try:
            conn = MySQLdb.connect(host="db", user="root", password="Aliprs2005", database="safarticket", port=3306)
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)
            
            cursor.execute("SELECT * FROM User WHERE user_id = %s", (user_id,))
            user = cursor.fetchone()

            if not user or user['account_status'] != 'ACTIVE':
                return Response({'error': 'User not found or is inactive'}, status=401)

            try:
                user_profile_json = json.dumps(user, default=str)
                redis_key = f"user_profile:{user_id}"
                redis_client.setex(redis_key, timedelta(seconds=360), user_profile_json)
            except (redis.exceptions.RedisError, TypeError):
                pass

            new_access_token = generate_access_token(user_id, user['email'])

            return Response({'access': new_access_token})

        except MySQLdb.Error as e:
            return Response({'error': f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            return Response({'error': f"An unexpected error occurred: {str(e)}"}, status=500)
        finally:
            if conn:
                cursor.close()
                conn.close()