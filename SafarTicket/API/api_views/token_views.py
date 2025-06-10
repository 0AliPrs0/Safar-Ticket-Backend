from rest_framework.views import APIView
from rest_framework.response import Response
from ..utils.jwt import verify_jwt, generate_access_token
import MySQLdb
from django.http import JsonResponse

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
            cursor.execute("SELECT email, account_status FROM User WHERE user_id = %s", (user_id,))
            user = cursor.fetchone()
            if not user or user['account_status'] != 'ACTIVE':
                return Response({'error': 'User not found or is inactive'}, status=401)

            new_access_token = generate_access_token(user_id, user['email'])

            return Response({'access': new_access_token})

        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            if conn:
                conn.close()