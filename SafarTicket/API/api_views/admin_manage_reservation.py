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




class AdminManageReservationAPIView(APIView):
    def post(self, request):
        admin_user_id = request.data.get("admin_id")
        reservation_id = request.data.get("reservation_id")
        action = request.data.get("action")
        new_data = request.data.get("new_data", {})

        if not all([admin_user_id, reservation_id, action]):
            return Response({"error": "admin_id, reservation_id, and action are required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_type FROM User WHERE user_id = %s", (admin_user_id,))
            result = cursor.fetchone()
            if not result or result[0] != 'ADMIN':
                return Response({"error": "Only admins can perform this action"}, status=403)

            cursor.execute("""
                SELECT status, user_id, ticket_id FROM Reservation WHERE reservation_id = %s
            """, (reservation_id,))
            reservation = cursor.fetchone()
            if not reservation:
                return Response({"error": "Reservation not found"}, status=404)

            current_status, user_id, ticket_id = reservation
            next_status = current_status

            if action == "approve":
                if current_status != 'reserved':
                    return Response({"error": "Only reserved reservations can be approved"}, status=400)
                cursor.execute("UPDATE Reservation SET status = 'paid' WHERE reservation_id = %s", (reservation_id,))
                next_status = 'paid'

            elif action == "cancel":
                if current_status == 'canceled':
                    return Response({"error": "Reservation is already canceled"}, status=400)

                cursor.execute("SELECT travel_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
                travel = cursor.fetchone()
                if not travel:
                    return Response({"error": "Travel not found"}, status=404)
                travel_id = travel[0]

                cursor.execute("SELECT departure_time, price FROM Travel WHERE travel_id = %s", (travel_id,))
                travel_info = cursor.fetchone()
                if not travel_info:
                    return Response({"error": "Travel details not found"}, status=404)
                departure_time, price = travel_info
                now = datetime.utcnow()
                remaining_time = departure_time - now

                if remaining_time <= timedelta(hours=1):
                    penalty_percent = 90
                elif remaining_time <= timedelta(hours=3):
                    penalty_percent = 50
                else:
                    penalty_percent = 10

                penalty_amount = round(price * penalty_percent / 100)
                refund_amount = price - penalty_amount

                cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))
                cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity + 1 WHERE travel_id = %s", (travel_id,))
                cursor.execute("UPDATE Payment SET payment_status = 'refunded' WHERE reservation_id = %s", (reservation_id,))
                cursor.execute("UPDATE User SET wallet = wallet + %s WHERE user_id = %s", (refund_amount, user_id))
                next_status = 'canceled'

            elif action == "modify":
                if "expiration_time" not in new_data:
                    return Response({"error": "Only 'expiration_time' can be modified"}, status=400)
                try:
                    expiration_time = datetime.fromisoformat(new_data["expiration_time"])
                except ValueError:
                    return Response({"error": "Invalid expiration_time format. Use ISO 8601 format."}, status=400)
                cursor.execute("""
                    UPDATE Reservation SET expiration_time = %s WHERE reservation_id = %s
                """, (expiration_time, reservation_id))
                next_status = current_status

            else:
                return Response({"error": "Invalid action"}, status=400)

            if action in ["approve", "cancel"]:
                cursor.execute("""
                    INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
                    VALUES (%s, %s, %s, %s)
                """, (reservation_id, admin_user_id, current_status, next_status))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": f"Reservation {action} successful"})

        except Exception as e:
            return Response({"error": str(e)}, status=500)