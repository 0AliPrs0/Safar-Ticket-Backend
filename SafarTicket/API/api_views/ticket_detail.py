import MySQLdb
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
import json


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)



class TicketDetailAPIView(APIView):

    def get(self, request, ticket_id):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

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

            cursor.execute("""
                SELECT 
                    t.ticket_id,
                    t.seat_number, 
                    r.reservation_time,
                    c1.city_name AS departure_city,
                    tr.departure_time,
                    c2.city_name AS destination_city,
                    tr.arrival_time,
                    tr.price,
                    tr.transport_type,
                    vd.vehicle_type,
                    t.vehicle_id
                FROM Travel tr
                JOIN Terminal trm1 ON trm1.terminal_id = tr.departure_terminal_id
                JOIN Terminal trm2 ON trm2.terminal_id = tr.destination_terminal_id
                JOIN City c1 ON c1.city_id = trm1.city_id
                JOIN City c2 ON c2.city_id = trm2.city_id
                JOIN Ticket t ON tr.travel_id = t.travel_id
                JOIN Reservation r ON r.ticket_id = t.ticket_id
                JOIN VehicleDetail vd ON vd.vehicle_id = t.vehicle_id
                WHERE t.ticket_id = %s
            """, (ticket_id,))

            ticket = cursor.fetchone()
            if not ticket:
                return Response({"error": "Ticket not found"}, status=404)

            vehicle_id = ticket["vehicle_id"]
            transport_type = ticket["vehicle_type"] 

            facilities = {}

            if transport_type == 'train':
                cursor.execute("SELECT facilities FROM TrainDetail WHERE train_id = %s", (vehicle_id,))
                result = cursor.fetchone()
                if result and result.get("facilities"):
                    facilities = json.loads(result["facilities"])
            elif transport_type == 'bus':
                cursor.execute("SELECT facilities FROM BusDetail WHERE bus_id = %s", (vehicle_id,))
                result = cursor.fetchone()
                if result and result.get("facilities"):
                    facilities = json.loads(result["facilities"])
            elif transport_type == 'flight':
                cursor.execute("SELECT facilities FROM FlightDetail WHERE flight_id = %s", (vehicle_id,))
                result = cursor.fetchone()
                if result and result.get("facilities"):
                    facilities = json.loads(result["facilities"])

            cursor.close()
            conn.close()

            response_data = {
                "ticket_id": ticket["ticket_id"],
                "seat_number": ticket["seat_number"], 
                "reservation_time": ticket["reservation_time"],
                "departure_city": ticket["departure_city"],
                "departure_time": ticket["departure_time"],
                "destination_city": ticket["destination_city"],
                "arrival_time": ticket["arrival_time"],
                "price": ticket["price"],
                "transport_type": ticket["transport_type"],
                "facilities": facilities
            }

            return Response(response_data)

        except Exception as e:
            return Response({"error": str(e)}, status=500)