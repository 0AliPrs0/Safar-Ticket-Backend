import MySQLdb
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)




class UserBookingsAPIView(APIView):
    def get(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')

        status_filter = request.query_params.get("status")

        if not user_id:
            return Response({"error": "user_id is required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)

            base_query = """
                SELECT 
                    r.reservation_id,
                    r.status AS reservation_status,
                    t.ticket_id,
                    t.seat_number,
                    tr.departure_time,
                    tr.arrival_time,
                    tr.price,
                    tr.transport_type,
                    tr.travel_class
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                JOIN Travel tr ON t.travel_id = tr.travel_id
                WHERE r.user_id = %s
            """

            params = [user_id]

            now_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            if status_filter == "future":
                base_query += " AND r.status = 'paid' AND tr.departure_time > %s"
                params.append(now_str)
            elif status_filter == "used":
                base_query += " AND r.status = 'paid' AND tr.departure_time <= %s"
                params.append(now_str)
            elif status_filter == "canceled":
                base_query += " AND r.status = 'canceled'"

            cursor.execute(base_query, params)
            rows = cursor.fetchall()

            cursor.close()
            conn.close()

            return Response({"bookings": rows})

        except Exception as e:
            return Response({"error": str(e)}, status=500)