import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime

class ReserveTicketAPIView(APIView):
    def post(self, request):
        user_id = request.data.get("user_id")
        travel_id = request.data.get("travel_id")

        if not user_id or not travel_id:
            return Response({"error": "user_id and travel_id are required"}, status=400)

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
                SELECT remaining_capacity, total_capacity, transport_type 
                FROM Travel 
                WHERE travel_id = %s FOR UPDATE
            """, (travel_id,))
            travel_info = cursor.fetchone()

            if not travel_info:
                conn.rollback()
                return Response({"error": "Travel not found"}, status=404)

            if travel_info["remaining_capacity"] <= 0:
                conn.rollback()
                return Response({"error": "No remaining capacity for this travel"}, status=400)

            vehicle_id = None
            cursor.execute("SELECT vehicle_id FROM Ticket WHERE travel_id = %s LIMIT 1", (travel_id,))
            existing_ticket = cursor.fetchone()

            if existing_ticket:
                vehicle_id = existing_ticket['vehicle_id']
            else:
                transport_type = travel_info['transport_type']
                if transport_type == 'plane':
                    vehicle_type_in_detail = 'flight'
                else:
                    vehicle_type_in_detail = transport_type
                
                cursor.execute("SELECT vehicle_id FROM VehicleDetail WHERE vehicle_type = %s ORDER BY RAND() LIMIT 1", (vehicle_type_in_detail,))
                
                new_vehicle_assignment = cursor.fetchone()
                
                if not new_vehicle_assignment:
                    conn.rollback()
                    return Response({"error": f"No available vehicle found for transport type: {transport_type}"}, status=500)
                
                vehicle_id = new_vehicle_assignment['vehicle_id']

            cursor.execute("SELECT MAX(seat_number) FROM Ticket WHERE travel_id = %s", (travel_id,))
            last_seat = cursor.fetchone()
            new_seat_number = (last_seat['MAX(seat_number)'] or 0) + 1
            
            if new_seat_number > travel_info['total_capacity']:
                conn.rollback()
                return Response({"error": "Cannot assign seat, exceeds total capacity"}, status=500)

            cursor.execute("""
                INSERT INTO Ticket (travel_id, vehicle_id, seat_number) 
                VALUES (%s, %s, %s)
            """, (travel_id, vehicle_id, new_seat_number))
            
            new_ticket_id = cursor.lastrowid

            reservation_time = datetime.datetime.now()
            expiration_time = reservation_time + datetime.timedelta(minutes=10)

            cursor.execute("""
                INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time)
                VALUES (%s, %s, 'reserved', %s, %s)
            """, (user_id, new_ticket_id, reservation_time.strftime('%Y-%m-%d %H:%M:%S'), expiration_time.strftime('%Y-%m-%d %H:%M:%S')))
            
            new_reservation_id = cursor.lastrowid

            cursor.execute("""
                UPDATE Travel SET remaining_capacity = remaining_capacity - 1 
                WHERE travel_id = %s
            """, (travel_id,))

            conn.commit()

            return Response({
                "message": "Ticket reserved successfully. Please complete the payment.",
                "reservation_id": new_reservation_id,
                "ticket_id": new_ticket_id,
                "seat_number": new_seat_number,
                "expires_at": expiration_time.isoformat()
            }, status=201)

        except MySQLdb.Error as e:
            if conn:
                conn.rollback()
            return Response({"error": f"Database transaction failed: {str(e)}"}, status=500)
        except Exception as e:
            if conn:
                conn.rollback()
            return Response({"error": f"An unexpected error occurred: {str(e)}"}, status=500)
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()


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