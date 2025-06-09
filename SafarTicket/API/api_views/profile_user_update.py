import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import redis
import datetime

redis_client = redis.Redis(host='redis', port=6379, db=0)

class ProfileUserUpdateAPIView(APIView):
    def put(self, request):
        data = request.data
        user_id = data.get('user_id')

        if not user_id:
            return Response({'error': 'user_id is required'}, status=400)

        db = None
        cursor = None
        try:
            db = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = db.cursor()

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
                    return Response({"error": f"City '{city_name}' not found"}, status=404)
                update_fields['city_id'] = city_result[0]

            if not update_fields:
                return Response({'error': 'No valid fields provided for update'}, status=400)

            set_clause = ", ".join([f"{key} = %s" for key in update_fields.keys()])
            query_params = list(update_fields.values())
            query_params.append(user_id)
            
            query = f"UPDATE User SET {set_clause} WHERE user_id = %s"

            cursor.execute(query, tuple(query_params))
            
            if cursor.rowcount == 0:
                 return Response({'error': f"User with user_id '{user_id}' not found or no changes made."}, status=404)

            db.commit()

            redis_key = f"user_profile:{user_id}"
            try:
                redis_client.delete(redis_key)
            except redis.exceptions.RedisError:
                pass

            return Response({'message': 'Profile updated successfully'})

        except MySQLdb.Error as e:
            return Response({'error': f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            if cursor:
                cursor.close()
            if db:
                db.close()