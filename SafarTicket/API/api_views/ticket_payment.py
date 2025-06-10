import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
import redis
import json
from django.http import JsonResponse

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class TicketPaymentAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')
        
        data = request.data
        reservation_id = data.get('reservation_id')
        payment_method = data.get('payment_method')

        if not all([user_id, reservation_id, payment_method]):
            return Response({"error": "Missing required fields"}, status=400)

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

            cursor.execute("""
                SELECT r.status, t.ticket_id, tr.price
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                JOIN Travel tr ON t.travel_id = tr.travel_id
                WHERE r.reservation_id = %s AND r.user_id = %s
            """, (reservation_id, user_id))
            reservation = cursor.fetchone()

            if not reservation:
                conn.rollback()
                return Response({"error": "Reservation not found"}, status=404)

            status, ticket_id, amount = reservation["status"], reservation["ticket_id"], reservation["price"]

            if status != 'reserved':
                conn.rollback()
                return Response({"error": "Reservation is not in a payable state"}, status=400)

            if payment_method == 'wallet':
                cursor.execute("SELECT wallet FROM User WHERE user_id = %s FOR UPDATE", (user_id,))
                wallet = cursor.fetchone()
                if not wallet:
                    conn.rollback()
                    return Response({"error": "User not found"}, status=404)
                
                current_balance = wallet["wallet"]
                if current_balance < amount:
                    conn.rollback()
                    return Response({"error": "Insufficient wallet balance"}, status=400)

                cursor.execute("UPDATE User SET wallet = wallet - %s WHERE user_id = %s", (amount, user_id))

            cursor.execute("""
                INSERT INTO Payment (user_id, reservation_id, amount, payment_method, payment_status)
                VALUES (%s, %s, %s, %s, %s)
            """, (user_id, reservation_id, amount, payment_method, 'completed'))

            cursor.execute("UPDATE Reservation SET status = 'paid' WHERE reservation_id = %s", (reservation_id,))

            conn.commit()

            try:
                redis_client.delete(f"user_profile:{user_id}")
                redis_client.delete(f"reservation:{reservation_id}")
            except redis.exceptions.RedisError:
                pass

            return Response({"message": "Payment completed and reservation confirmed."})

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