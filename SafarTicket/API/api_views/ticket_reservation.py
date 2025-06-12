import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
import redis
import json
from datetime import timedelta
from ..utils.email_utils import send_payment_reminder_email

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)


class ReserveTicketAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')
        user_email = user_info.get('email')
        travel_id = request.data.get("travel_id")
        seat_number = request.data.get("seat_number")

        if not all([travel_id, seat_number]):
            return Response({"error": "travel_id and seat_number are required"}, status=400)

        conn = None
        cursor = None
        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306,
                cursorclass=MySQLdb.cursors.DictCursor
            )
            cursor = conn.cursor()

            conn.begin()

            cursor.execute("""
                SELECT tr.remaining_capacity, tr.total_capacity, tr.transport_type, tr.departure_time, tr.price,
                       dep_city.city_name AS departure_city, dest_city.city_name AS destination_city
                FROM Travel tr
                JOIN Terminal dep_term ON tr.departure_terminal_id = dep_term.terminal_id
                JOIN City dep_city ON dep_term.city_id = dep_city.city_id
                JOIN Terminal dest_term ON tr.destination_terminal_id = dest_term.terminal_id
                JOIN City dest_city ON dest_term.city_id = dest_city.city_id
                WHERE tr.travel_id = %s FOR UPDATE
            """, (travel_id,))
            travel_info = cursor.fetchone()

            if not travel_info:
                conn.rollback()
                return Response({"error": "Travel not found"}, status=404)
            
            if travel_info["departure_time"] < datetime.datetime.now():
                conn.rollback()
                return Response({"error": "This travel has already departed and cannot be reserved."}, status=400)

            if travel_info["remaining_capacity"] <= 0:
                conn.rollback()
                return Response({"error": "No remaining capacity for this travel"}, status=400)

            if not (1 <= int(seat_number) <= travel_info['total_capacity']):
                conn.rollback()
                return Response({"error": f"Invalid seat number. Must be between 1 and {travel_info['total_capacity']}."}, status=400)

            cursor.execute("""
                SELECT r.status FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                WHERE t.travel_id = %s AND t.seat_number = %s AND r.status IN ('paid', 'reserved')
            """, (travel_id, seat_number))
            
            if cursor.fetchone():
                conn.rollback()
                return Response({"error": f"Seat {seat_number} is already occupied."}, status=400)

            vehicle_id = None
            cursor.execute("SELECT vehicle_id FROM Ticket WHERE travel_id = %s LIMIT 1", (travel_id,))
            existing_ticket = cursor.fetchone()

            if existing_ticket:
                vehicle_id = existing_ticket['vehicle_id']
            else:
                transport_type = travel_info['transport_type']
                vehicle_type_in_detail = 'flight' if transport_type == 'plane' else transport_type
                
                cursor.execute("SELECT vehicle_id FROM VehicleDetail WHERE vehicle_type = %s ORDER BY RAND() LIMIT 1", (vehicle_type_in_detail,))
                
                new_vehicle_assignment = cursor.fetchone()
                
                if not new_vehicle_assignment:
                    conn.rollback()
                    return Response({"error": f"No available vehicle found for transport type: {transport_type}"}, status=500)
                
                vehicle_id = new_vehicle_assignment['vehicle_id']

            cursor.execute("""
                INSERT INTO Ticket (travel_id, vehicle_id, seat_number) 
                VALUES (%s, %s, %s)
            """, (travel_id, vehicle_id, seat_number))
            
            new_ticket_id = cursor.lastrowid

            reservation_time = datetime.datetime.now()
            expiration_time = reservation_time + timedelta(minutes=10)

            cursor.execute("""
                INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time)
                VALUES (%s, %s, 'reserved', %s, %s)
            """, (user_id, new_ticket_id, reservation_time.strftime('%Y-%m-%d %H:%M:%S'), expiration_time.strftime('%Y-%m-%d %H:%M:%S')))
            
            new_reservation_id = cursor.lastrowid

            cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity - 1 WHERE travel_id = %s", (travel_id,))

            conn.commit()
            
            try:
                reservation_cache_data = {
                    "status": "reserved",
                    "user_id": user_id,
                    "ticket_id": new_ticket_id,
                    "price": travel_info["price"]
                }
                redis_key = f"reservation_details:{new_reservation_id}"
                redis_client.setex(redis_key, timedelta(minutes=10), json.dumps(reservation_cache_data))
                
                email_details = {
                    "reservation_id": new_reservation_id,
                    "departure_city": travel_info['departure_city'],
                    "destination_city": travel_info['destination_city'],
                    "departure_time": travel_info['departure_time'].strftime('%Y-%m-%d %H:%M')
                }
                send_payment_reminder_email(user_email, expiration_time, email_details)
            except redis.exceptions.RedisError:
                pass

            return Response({
                "message": "Ticket reserved successfully. Please complete the payment.",
                "reservation_id": new_reservation_id,
                "ticket_id": new_ticket_id,
                "seat_number": seat_number,
                "expires_at": expiration_time.isoformat()
            }, status=201)

        except MySQLdb.Error as e:
            if conn:
                conn.rollback()
            return Response({"error": f"Database transaction failed: {str(e)}"}, status=500)
        except Exception as e:
            import traceback
            traceback.print_exc()
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
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')

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
                WHERE r.user_id = %s AND r.status != 'canceled'
                ORDER BY r.reservation_time DESC
            """, (user_id,))
            reservations = cursor.fetchall()
            cursor.close()
            conn.close()
            return Response(reservations)
        except Exception as e:
            return Response({"error": str(e)}, status=500)