import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
from datetime import datetime, timedelta

class AdminManageReservationAPIView(APIView):
    def post(self, request):
        admin_user_id = request.data.get("admin_id")
        reservation_id = request.data.get("reservation_id")
        action = request.data.get("action")
        new_data = request.data.get("new_data", {})

        if not all([admin_user_id, reservation_id, action]):
            return Response({"error": "admin_id, reservation_id, and action are required"}, status=400)

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

            cursor.execute("SELECT user_type FROM User WHERE user_id = %s", (admin_user_id,))
            result = cursor.fetchone()
            if not result or result['user_type'] not in ['ADMIN', 'SUPPORT']:
                conn.rollback()
                return Response({"error": "Only admins or support can perform this action"}, status=403)

            cursor.execute("""
                SELECT status, user_id, ticket_id FROM Reservation WHERE reservation_id = %s FOR UPDATE
            """, (reservation_id,))
            reservation = cursor.fetchone()
            if not reservation:
                conn.rollback()
                return Response({"error": "Reservation not found"}, status=404)

            current_status, user_id, ticket_id = reservation['status'], reservation['user_id'], reservation['ticket_id']
            next_status = current_status

            if action == "approve":
                if current_status != 'reserved':
                    conn.rollback()
                    return Response({"error": "Only reserved reservations can be approved"}, status=400)
                cursor.execute("UPDATE Reservation SET status = 'paid' WHERE reservation_id = %s", (reservation_id,))
                next_status = 'paid'

            elif action == "cancel":
                if current_status == 'canceled':
                    conn.rollback()
                    return Response({"error": "Reservation is already canceled"}, status=400)

                cursor.execute("SELECT travel_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
                travel = cursor.fetchone()
                if not travel:
                    conn.rollback()
                    return Response({"error": "Travel not found"}, status=404)
                travel_id = travel['travel_id']

                cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))
                cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity + 1 WHERE travel_id = %s", (travel_id,))

                if current_status == 'paid':
                    cursor.execute("UPDATE Payment SET payment_status = 'failed' WHERE reservation_id = %s", (reservation_id,))
                
                next_status = 'canceled'

            elif action == "modify":
                if "expiration_time" not in new_data:
                    conn.rollback()
                    return Response({"error": "Only 'expiration_time' can be modified"}, status=400)
                try:
                    expiration_time = datetime.fromisoformat(new_data["expiration_time"])
                except ValueError:
                    conn.rollback()
                    return Response({"error": "Invalid expiration_time format. Use ISO 8601 format."}, status=400)
                
                cursor.execute("UPDATE Reservation SET expiration_time = %s WHERE reservation_id = %s", (expiration_time, reservation_id))
                next_status = current_status

            else:
                conn.rollback()
                return Response({"error": "Invalid action"}, status=400)

            if action in ["approve", "cancel"]:
                cursor.execute("""
                    INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
                    VALUES (%s, %s, %s, %s)
                """, (reservation_id, admin_user_id, current_status, next_status))

            conn.commit()

            return Response({"message": f"Reservation {action} successful"})

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