import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis
from rest_framework.views import APIView
from rest_framework.response import Response
from .utils.email_utils import send_otp_email
from .serializers import UserSerializer
import datetime
import hashlib
from .utils.jwt import generate_jwt 
from rest_framework.permissions import IsAuthenticated
import json

redis_client = redis.Redis(host='redis', port=6379, db=0)

class CityListView(View):
    def get(self, request):
        try:
            db = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = db.cursor()
            cursor.execute("SELECT city_id, province_name, city_name FROM City")
            rows = cursor.fetchall()

            cities = []
            for row in rows:
                cities.append({
                    "city_id": row[0],
                    "province_name": row[1],
                    "city_name": row[2]
                })

            cursor.close()
            db.close()

            return JsonResponse(cities, safe=False)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
        

class SendOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=400)

        otp = str(random.randint(100000, 999999))
        redis_client.setex(f"otp:{email}", 300, otp)

        try:
            send_otp_email(email, otp)
        except Exception:
            return Response({'error': 'Failed to send email. Try again later.'}, status=500)

        return Response({'message': 'OTP sent to your email'}, status=200)



class VerifyOtpAPIView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=400)

        saved_otp = redis_client.get(f"otp:{email}")
        if not saved_otp or saved_otp.decode() != otp:
            return Response({'error': 'Invalid or expired OTP'}, status=400)

        conn = MySQLdb.connect(
            host="db",
            user="root",
            password="Aliprs2005",
            database="safarticket",
            port=3306
        )
        cursor = conn.cursor()

        cursor.execute("SELECT user_id, first_name, last_name, email, phone_number, user_type, city_id, registration_date, account_status FROM User WHERE email = %s", (email,))
        row = cursor.fetchone()

        if not row:
            registration_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            cursor.execute("""
                INSERT INTO User (first_name, last_name, email, user_type, city_id, registration_date, account_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, ("", "", email, "customer", 1, registration_date, "active"))
            conn.commit()
            user_id = cursor.lastrowid
            user_data = {
                "user_id": user_id,
                "first_name": "",
                "last_name": "",
                "email": email,
                "phone_number": None,
                "user_type": "customer",
                "city_id": 1,
                "registration_date": registration_date,
                "account_status": "active"
            }
        else:
            user_data = {
                "user_id": row[0],
                "first_name": row[1],
                "last_name": row[2],
                "email": row[3],
                "phone_number": row[4],
                "user_type": row[5],
                "city_id": row[6],
                "registration_date": row[7],
                "account_status": row[8]
            }

        cursor.close()
        conn.close()

        token = generate_jwt({'user_id': user_data['user_id'], 'email': user_data['email']})
        serializer = UserSerializer(user_data)

        return Response({
            'token': token,
            'user': serializer.data
        }, status=200)
     

class SignupUserAPIView(APIView):
    def post(self, request):
        data = request.data
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        email = data.get('email')
        phone_number = data.get('phone_number')
        password = data.get('password')
        city_id = data.get('city_id', 1)

        if not all([first_name, last_name, email, phone_number, password]):
            return Response({'error': 'All fields are required'}, status=400)

        password_hash = hashlib.sha256(password.encode()).hexdigest()
        registration_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_id FROM User WHERE email = %s", (email,))
            if cursor.fetchone():
                return Response({'error': 'User with this email already exists'}, status=400)

            cursor.execute("""
                INSERT INTO User (first_name, last_name, email, phone_number, password_hash, user_type, city_id, registration_date, account_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (first_name, last_name, email, phone_number, password_hash, "customer", city_id, registration_date, "active"))

            conn.commit()
            user_id = cursor.lastrowid
            cursor.close()
            conn.close()

            token = generate_jwt({'user_id': user_id, 'email': email})

            return Response({
                'message': 'User registered successfully',
                'token': token,
                'user': {
                    'user_id': user_id,
                    'first_name': first_name,
                    'last_name': last_name,
                    'email': email,
                    'phone_number': phone_number,
                    'user_type': 'customer',
                    'city_id': city_id,
                    'registration_date': registration_date,
                    'account_status': 'active'
                }
            }, status=201)

        except Exception as e:
            return Response({'error': str(e)}, status=500)


class TicketDetailAPIView(APIView):
    # permission_classes = [IsAuthenticated]

    def get(self, request, ticket_id):
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
                SELECT 
                    t.ticket_id,
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
                if result and result["facilities"]:
                    facilities = json.loads(result["facilities"])
            elif transport_type == 'bus':
                cursor.execute("SELECT facilities FROM BusDetail WHERE bus_id = %s", (vehicle_id,))
                result = cursor.fetchone()
                if result and result["facilities"]:
                    facilities = json.loads(result["facilities"])
            elif transport_type == 'flight':
                cursor.execute("SELECT facilities FROM FlightDetail WHERE flight_id = %s", (vehicle_id,))
                result = cursor.fetchone()
                if result and result["facilities"]:
                    facilities = json.loads(result["facilities"])

            cursor.close()
            conn.close()

            response_data = {
                "ticket_id": ticket["ticket_id"],
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

class ProfileUserUpdateAPIView(APIView):
    # permission_classes = [IsAuthenticated]

    def put(self, request):
        data = request.data
        user_id = data['user_id']

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            set_parts = []
            if 'first_name' in data:
                set_parts.append(f"first_name = '{data['first_name']}'")
            if 'last_name' in data:
                set_parts.append(f"last_name = '{data['last_name']}'")
            if 'phone_number' in data:
                set_parts.append(f"phone_number = '{data['phone_number']}'")
            if 'birth_date' in data:
                set_parts.append(f"birth_date = '{data['birth_date']}'")

            if not set_parts:
                return Response({'error': 'No valid fields provided'}, status=400)


            query = f"UPDATE User SET {', '.join(set_parts)} WHERE user_id = {user_id}"
            cursor.execute(query)
            conn.commit()

            redis_key = f"user_profile:{user_id}"
            redis_client.delete(redis_key)

            cursor.close()
            conn.close()

            return Response({'message': 'Profile updated successfully'})

        except Exception as e:
            return Response({'error': str(e)}, status=500)
