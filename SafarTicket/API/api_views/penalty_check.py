import MySQLdb
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
from datetime import datetime, timedelta 


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)



class PenaltyCheckAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        reservation_id = request.data.get("reservation_id")
        if not reservation_id:
            return Response({"error": "reservation_id is required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("""
                SELECT r.status, t.travel_id, tr.departure_time, tr.price
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                JOIN Travel tr ON t.travel_id = tr.travel_id
                WHERE r.reservation_id = %s
            """, (reservation_id,))
            result = cursor.fetchone()

            if not result:
                return Response({"error": "Reservation not found"}, status=404)

            status, travel_id, departure_time, price = result

            if status != "paid":
                return Response({"error": "Only paid reservations have a penalty policy"}, status=400)

            now = datetime.utcnow()
            departure_dt = departure_time
            remaining_time = departure_dt - now

            if remaining_time <= timedelta(hours=1):
                penalty_percent = 90
            elif remaining_time <= timedelta(hours=3):
                penalty_percent = 50
            else:
                penalty_percent = 10

            penalty_amount = round(price * penalty_percent / 100)

            cursor.close()
            conn.close()

            return Response({
                "reservation_id": reservation_id,
                "penalty_percent": penalty_percent,
                "penalty_amount": penalty_amount,
                "refund_amount": price - penalty_amount
            })

        except Exception as e:
            return Response({"error": str(e)}, status=500) 