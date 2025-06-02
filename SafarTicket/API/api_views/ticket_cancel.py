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




class TicketCancelAPIView(APIView):
    def post(self, request):
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

            cursor.execute("SELECT status, user_id, ticket_id FROM Reservation WHERE reservation_id = %s", (reservation_id,))
            reservation = cursor.fetchone()
            if not reservation:
                return Response({"error": "Reservation not found"}, status=404)

            status, user_id, ticket_id = reservation
            if status != 'paid':
                return Response({"error": "Only paid reservations can be canceled"}, status=400)

            cursor.execute("SELECT travel_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
            travel = cursor.fetchone()
            if not travel:
                return Response({"error": "Ticket or related travel not found"}, status=404)
            travel_id = travel[0]

            cursor.execute("SELECT user_id FROM User WHERE email = 'admin@gmail.com' LIMIT 1")
            admin = cursor.fetchone()
            if not admin:
                return Response({"error": "Admin user not found"}, status=500)
            admin_user_id = admin[0]

            cursor.execute("""
                SELECT t.departure_time, p.amount 
                FROM Travel t
                JOIN Ticket tk ON t.travel_id = tk.travel_id
                JOIN Reservation r ON r.ticket_id = tk.ticket_id
                JOIN Payment p ON p.reservation_id = r.reservation_id
                WHERE r.reservation_id = %s
            """, (reservation_id,))
            travel_info = cursor.fetchone()
            if not travel_info:
                return Response({"error": "Travel or Payment data not found"}, status=404)

            departure_time, amount_paid = travel_info

            now = datetime.utcnow()
            remaining_time = departure_time - now

            if remaining_time <= timedelta(hours=1):
                penalty_percent = 90
            elif remaining_time <= timedelta(hours=3):
                penalty_percent = 50
            else:
                penalty_percent = 10

            penalty_amount = round(amount_paid * penalty_percent / 100)
            refund_amount = amount_paid - penalty_amount

            cursor.execute("UPDATE User SET wallet = wallet + %s WHERE user_id = %s", (refund_amount, user_id))
            cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))
            cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity + 1 WHERE travel_id = %s", (travel_id,))
            cursor.execute("UPDATE Payment SET payment_status = 'failed' WHERE reservation_id = %s", (reservation_id,))
            cursor.execute("""
                INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
                VALUES (%s, %s, 'paid', 'canceled')
            """, (reservation_id, admin_user_id))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Ticket canceled and refund initiated"})

        except Exception as e:
            return Response({"error": str(e)}, status=500)