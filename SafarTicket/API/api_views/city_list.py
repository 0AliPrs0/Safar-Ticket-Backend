import MySQLdb
from django.http import JsonResponse
from rest_framework.views import APIView
import redis 


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