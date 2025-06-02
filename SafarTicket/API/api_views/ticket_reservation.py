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




class ReserveTicketAPIView(APIView):
    def post(self, request):
        user_id = request.data.get("user_id")
        ticket_id = request.data.get("ticket_id")

        if not user_id or not ticket_id:
            return Response({"error": "user_id and ticket_id are required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT ticket_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
            if not cursor.fetchone():
                return Response({"error": "Ticket not found"}, status=404)

            cursor.execute("""
                SELECT reservation_id FROM Reservation 
                WHERE ticket_id = %s AND status IN ('reserved', 'paid')
            """, (ticket_id,))
            if cursor.fetchone():
                return Response({"error": "Ticket already reserved or paid"}, status=400)

            cursor.execute("SELECT NOW()")
            now = cursor.fetchone()[0]
            expiration = now + timedelta(minutes=1)

            cursor.execute("""
                INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time)
                VALUES (%s, %s, 'reserved', %s, %s)
            """, (user_id, ticket_id, now, expiration))

            cursor.execute("SELECT email FROM User WHERE user_id = %s", (user_id,))
            result = cursor.fetchone()
            if result:
                user_email = result[0]
                try:
                    send_payment_reminder_email(user_email, expiration)
                except Exception:
                    pass 

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Ticket reserved successfully", "expires_at": expiration})

        except Exception as e:
            return Response({"error": str(e)}, status=500)


class UserReservationsAPIView(APIView):
    def get(self, request):
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({"error": "user_id is required."}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)
            cursor.execute("""
                SELECT r.reservation_id, r.status, r.reservation_time, r.expiration_time,
                       t.travel_id, t.seat_number
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                WHERE r.user_id = %s
                ORDER BY r.reservation_time DESC
            """, (user_id,))
            reservations = cursor.fetchall()
            cursor.close()
            conn.close()
            return Response(reservations)
        except Exception as e:
            return Response({"error": str(e)}, status=500)