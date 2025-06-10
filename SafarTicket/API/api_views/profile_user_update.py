import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import redis
import datetime
from django.http import JsonResponse


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class ProfileUserUpdateAPIView(APIView):
    def put(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')
        data = request.data

        if not data:
            return Response({'error': 'No data provided for update'}, status=400)

        conn = None
        cursor = None
        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)
            
            conn.begin()

            update_fields = {}
            if 'first_name' in data:
                update_fields['first_name'] = data['first_name']
            if 'last_name' in data:
                update_fields['last_name'] = data['last_name']
            if 'phone_number' in data:
                update_fields['phone_number'] = data['phone_number']
            if 'birth_date' in data:
                update_fields['birth_date'] = data['birth_date']
            
            if 'city_name' in data:
                city_name = data['city_name']
                cursor.execute("SELECT city_id FROM City WHERE city_name = %s", (city_name,))
                city_result = cursor.fetchone()
                if not city_result:
                    conn.rollback()
                    return Response({"error": f"City '{city_name}' not found"}, status=404)
                update_fields['city_id'] = city_result["city_id"]

            if not update_fields:
                conn.rollback()
                return Response({'error': 'No valid fields provided for update'}, status=400)

            set_clause = ", ".join([f"{key} = %s" for key in update_fields.keys()])
            query_params = list(update_fields.values())
            query_params.append(user_id)
            
            query = f"UPDATE User SET {set_clause} WHERE user_id = %s"

            cursor.execute(query, tuple(query_params))
            
            if cursor.rowcount == 0:
                 conn.rollback()
                 return Response({'error': 'User not found or no changes made.'}, status=404)

            conn.commit()

            redis_key = f"user_profile:{user_id}"
            try:
                redis_client.delete(redis_key)
            except redis.exceptions.RedisError:
                pass

            return Response({'message': 'Profile updated successfully'})

        except MySQLdb.Error as e:
            if conn:
                conn.rollback()
            return Response({"error": f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            if conn:
                conn.rollback()
            return Response({"error": str(e)}, status=500)
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()