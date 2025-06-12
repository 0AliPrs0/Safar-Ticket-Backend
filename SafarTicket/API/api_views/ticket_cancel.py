import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
from datetime import datetime, timedelta
import redis

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

class TicketCancelAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')
        reservation_id = request.data.get("reservation_id")

        if not reservation_id:
            return Response({"error": "reservation_id is required"}, status=400)

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
                SELECT status, ticket_id FROM Reservation 
                WHERE reservation_id = %s FOR UPDATE
            """, (reservation_id,))
            reservation = cursor.fetchone()

            if not reservation:
                conn.rollback()
                return Response({"error": "Reservation not found"}, status=404)

            status, ticket_id = reservation["status"], reservation["ticket_id"]
            if status != 'paid':
                conn.rollback()
                return Response({"error": "Only paid reservations can be canceled by the user"}, status=400)

            cursor.execute("SELECT travel_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
            travel = cursor.fetchone()
            if not travel:
                conn.rollback()
                return Response({"error": "Ticket or related travel not found"}, status=404)
            travel_id = travel["travel_id"]

            cursor.execute("SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1")
            support_user = cursor.fetchone()
            if not support_user:
                conn.rollback()
                return Response({"error": "No support user found to log this change"}, status=500)
            support_user_id = support_user["user_id"]
            
            cursor.execute("""
                SELECT tr.departure_time, p.amount 
                FROM Travel tr
                LEFT JOIN Payment p ON p.reservation_id = %s
                WHERE tr.travel_id = %s
            """, (reservation_id, travel_id))
            travel_info = cursor.fetchone()

            if not travel_info:
                conn.rollback()
                return Response({"error": "Travel or Payment data not found"}, status=404)

            departure_time, amount_paid = travel_info["departure_time"], travel_info["amount"]

            now = datetime.now()
            remaining_time = departure_time - now

            if remaining_time <= timedelta(hours=1):
                penalty_percent = 90
            elif remaining_time <= timedelta(hours=3):
                penalty_percent = 50
            else:
                penalty_percent = 10

            penalty_amount = round(float(amount_paid) * penalty_percent / 100)
            refund_amount = float(amount_paid) - penalty_amount

            cursor.execute("UPDATE User SET wallet = wallet + %s WHERE user_id = %s", (refund_amount, user_id))
            cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))
            cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity + 1 WHERE travel_id = %s", (travel_id,))
            cursor.execute("UPDATE Payment SET payment_status = 'failed' WHERE reservation_id = %s", (reservation_id,))
            cursor.execute("""
                INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
                VALUES (%s, %s, 'paid', 'canceled')
            """, (reservation_id, support_user_id))

            conn.commit()
            
            return Response({"message": "Ticket canceled and refund initiated"})

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