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



class TicketPaymentAPIView(APIView):
    def post(self, request):
        data = request.data
        user_id = data.get('user_id')
        reservation_id = data.get('reservation_id')
        payment_method = data.get('payment_method')

        if not all([user_id, reservation_id, payment_method]):
            return Response({"error": "Missing required fields"}, status=400)

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
                SELECT r.status, t.ticket_id, tr.price
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                JOIN Travel tr ON t.travel_id = tr.travel_id
                WHERE r.reservation_id = %s AND r.user_id = %s
            """, (reservation_id, user_id))
            reservation = cursor.fetchone()

            if not reservation:
                return Response({"error": "Reservation not found"}, status=404)

            status, ticket_id, amount = reservation

            if status != 'reserved':
                return Response({"error": "Reservation is not in a payable state"}, status=400)

            if payment_method == 'wallet':
                cursor.execute("SELECT wallet FROM User WHERE user_id = %s", (user_id,))
                wallet = cursor.fetchone()
                if not wallet:
                    return Response({"error": "User not found"}, status=404)
                current_balance = wallet[0]

                if current_balance < amount:
                    return Response({"error": "Insufficient wallet balance"}, status=400)

                cursor.execute("UPDATE User SET wallet = wallet - %s WHERE user_id = %s", (amount, user_id))

            cursor.execute("""
                INSERT INTO Payment (user_id, reservation_id, amount, payment_method, payment_status)
                VALUES (%s, %s, %s, %s, %s)
            """, (user_id, reservation_id, amount, payment_method, 'completed'))

            cursor.execute("""
                UPDATE Reservation
                SET status = 'paid'
                WHERE reservation_id = %s
            """, (reservation_id,))

            conn.commit()

            redis_client.delete(f"user_profile:{user_id}")
            redis_client.delete(f"reservation:{reservation_id}")

            cursor.close()
            conn.close()

            return Response({"message": "Payment completed and reservation confirmed."})

        except Exception as e:
            return Response({"error": str(e)}, status=500)
