import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis
from rest_framework.views import APIView
from rest_framework.response import Response
from .utils.email_utils import send_otp_email, send_payment_reminder_email
from .serializers import UserSerializer
import datetime
import hashlib
from .utils.jwt import generate_jwt 
from rest_framework.permissions import IsAuthenticated
import json
from datetime import datetime, timedelta


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


class SearchTicketsAPIView(APIView):
    def post(self, request):
        data = request.data
        origin_city_id = data.get('origin_city_id')
        destination_city_id = data.get('destination_city_id')
        travel_date_str = data.get('travel_date')

        transport_type = data.get('transport_type')
        min_price = data.get('min_price')
        max_price = data.get('max_price')
        company_id = data.get('company_id')
        travel_class = data.get('travel_class')

        if not all([origin_city_id, destination_city_id, travel_date_str]):
            return Response({'error': 'Origin city, destination city, and travel date are required in the request body.'}, status=400)

        try:
            datetime.datetime.strptime(travel_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({'error': 'Invalid travel_date format. Use YYYY-MM-DD.'}, status=400)

        cache_key_parts = [
            f"search_tickets_post",
            f"ocid_{origin_city_id}",
            f"dcid_{destination_city_id}",
            f"date_{travel_date_str}"
        ]
        if transport_type: cache_key_parts.append(f"tt_{transport_type}")
        if min_price is not None: cache_key_parts.append(f"minp_{min_price}")
        if max_price is not None: cache_key_parts.append(f"maxp_{max_price}")
        if company_id: cache_key_parts.append(f"comp_{company_id}")
        if travel_class: cache_key_parts.append(f"tc_{travel_class}")

        cache_key = ":".join(cache_key_parts)

        try:
            cached_results = redis_client.get(cache_key)
            if cached_results:
                return Response(json.loads(cached_results), status=200)
        except redis.exceptions.RedisError:
            pass

        db = None
        cursor = None
        try:
            db = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306,
                cursorclass=MySQLdb.cursors.DictCursor
            )
            cursor = db.cursor()

            query_params = []
            base_query = """
                SELECT
                    tr.travel_id,
                    tr.transport_type,
                    dep_city.city_name AS departure_city_name,
                    dep_term.terminal_name AS departure_terminal_name,
                    tr.departure_time,
                    dest_city.city_name AS destination_city_name,
                    dest_term.terminal_name AS destination_terminal_name,
                    tr.arrival_time,
                    tr.price,
                    tr.travel_class,
                    tr.remaining_capacity,
                    tc.company_name AS transport_company_name,
                    COUNT(r.reservation_id) AS demand_score
                FROM Travel tr
                JOIN Terminal dep_term ON tr.departure_terminal_id = dep_term.terminal_id
                JOIN City dep_city ON dep_term.city_id = dep_city.city_id
                JOIN Terminal dest_term ON tr.destination_terminal_id = dest_term.terminal_id
                JOIN City dest_city ON dest_term.city_id = dest_city.city_id
                LEFT JOIN TransportCompany tc ON tr.transport_company_id = tc.transport_company_id
                LEFT JOIN Ticket t ON t.travel_id = tr.travel_id
                LEFT JOIN Reservation r ON r.ticket_id = t.ticket_id
                WHERE tr.remaining_capacity > 0
            """

            base_query += " AND dep_city.city_id = %s"
            query_params.append(origin_city_id)
            base_query += " AND dest_city.city_id = %s"
            query_params.append(destination_city_id)
            base_query += " AND DATE(tr.departure_time) = %s"
            query_params.append(travel_date_str)

            if transport_type:
                base_query += " AND tr.transport_type = %s"
                query_params.append(transport_type)
            if min_price is not None:
                try:
                    base_query += " AND tr.price >= %s"
                    query_params.append(float(min_price))
                except ValueError:
                    return Response({'error': 'Invalid min_price format. Must be a number.'}, status=400)
            if max_price is not None:
                try:
                    base_query += " AND tr.price <= %s"
                    query_params.append(float(max_price))
                except ValueError:
                    return Response({'error': 'Invalid max_price format. Must be a number.'}, status=400)
            if company_id:
                base_query += " AND tr.transport_company_id = %s"
                query_params.append(company_id)
            if travel_class:
                base_query += " AND tr.travel_class = %s"
                query_params.append(travel_class)

            base_query += " GROUP BY tr.travel_id ORDER BY tr.departure_time ASC, demand_score DESC"

            cursor.execute(base_query, tuple(query_params))
            rows = cursor.fetchall()

            results = []
            for row in rows:
                row['departure_time'] = row['departure_time'].isoformat() if isinstance(row.get('departure_time'), datetime.datetime) else str(row.get('departure_time'))
                row['arrival_time'] = row['arrival_time'].isoformat() if isinstance(row.get('arrival_time'), datetime.datetime) else str(row.get('arrival_time'))
                results.append(row)

            try:
                redis_client.setex(cache_key, datetime.timedelta(minutes=15), json.dumps(results))
            except redis.exceptions.RedisError:
                pass

            return Response(results, status=200)

        except MySQLdb.Error as e:
            return Response({"error": f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            return Response({"error": f"An unexpected error occurred: {str(e)}"}, status=500)
        finally:
            if cursor:
                cursor.close()
            if db:
                db.close()


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



class UserBookingsAPIView(APIView):
    def get(self, request):
        user_id = request.query_params.get("user_id")
        status_filter = request.query_params.get("status")

        if not user_id:
            return Response({"error": "user_id is required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor(MySQLdb.cursors.DictCursor)

            base_query = """
                SELECT 
                    r.reservation_id,
                    r.status AS reservation_status,
                    t.ticket_id,
                    t.seat_number,
                    tr.departure_time,
                    tr.arrival_time,
                    tr.price,
                    tr.transport_type,
                    tr.travel_class
                FROM Reservation r
                JOIN Ticket t ON r.ticket_id = t.ticket_id
                JOIN Travel tr ON t.travel_id = tr.travel_id
                WHERE r.user_id = %s
            """

            params = [user_id]

            now_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            if status_filter == "future":
                base_query += " AND r.status = 'paid' AND tr.departure_time > %s"
                params.append(now_str)
            elif status_filter == "used":
                base_query += " AND r.status = 'paid' AND tr.departure_time <= %s"
                params.append(now_str)
            elif status_filter == "canceled":
                base_query += " AND r.status = 'canceled'"

            cursor.execute(base_query, params)
            rows = cursor.fetchall()

            cursor.close()
            conn.close()

            return Response({"bookings": rows})

        except Exception as e:
            return Response({"error": str(e)}, status=500)


class TicketCancelAPIView(APIView):
    def post(self, request):
        reservation_id = request.data.get("reservation_id")

        if not reservation_id:
            return Response({"error": "reservation_id is required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT status, user_id, ticket_id FROM Reservation WHERE reservation_id = %s", (reservation_id,))
            reservation = cursor.fetchone()
            if not reservation:
                return Response({"error": "Reservation not found"}, status=404)

            status, user_id, ticket_id = reservation
            if status != 'paid':
                return Response({"error": "Only paid reservations can be canceled"}, status=400)

            cursor.execute("SELECT travel_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
            travel = cursor.fetchone()
            if not travel:
                return Response({"error": "Ticket or related travel not found"}, status=404)
            travel_id = travel[0]

            cursor.execute("SELECT user_id FROM User WHERE email = 'admin@gmail.com' LIMIT 1")
            admin = cursor.fetchone()
            if not admin:
                return Response({"error": "Admin user not found"}, status=500)
            admin_user_id = admin[0]

            cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))

            cursor.execute("UPDATE Travel SET remaining_capacity = remaining_capacity + 1 WHERE travel_id = %s", (travel_id,))

            cursor.execute("UPDATE Payment SET payment_status = 'failed' WHERE reservation_id = %s", (reservation_id,))

            cursor.execute("""
                INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
                VALUES (%s, %s, 'paid', 'canceled')
            """, (reservation_id, admin_user_id))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Ticket canceled and refund initiated"})

        except Exception as e:
            return Response({"error": str(e)}, status=500)


class AdminManageReservationAPIView(APIView):
    def post(self, request):
        admin_user_id = request.data.get("admin_id")
        reservation_id = request.data.get("reservation_id")
        action = request.data.get("action")
        new_data = request.data.get("new_data", {})

        if not reservation_id or not action:
            return Response({"error": "admin_id and reservation_id and action are required"}, status=400)

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
            user_type = cursor.fetchone()

            if not user_type or user_type[0] != 'ADMIN':
                return Response({"error": "Only admins can change reservations"}, status=403)
 

            cursor.execute("SELECT status FROM Reservation WHERE reservation_id = %s", (reservation_id,))
            reservation = cursor.fetchone()
            if not reservation:
                return Response({"error": "Reservation not found"}, status=404)
            current_status = reservation[0]


            if action == "approve":
                if current_status != 'reserved':
                    return Response({"error": "Only reserved reservations can be approved (changed to paid)"}, status=400)
                cursor.execute("UPDATE Reservation SET status = 'paid' WHERE reservation_id = %s", (reservation_id,))
                next_status = 'paid'

            elif action == "cancel":
                if current_status == 'canceled':
                    return Response({"error": "Reservation is already canceled"}, status=400)
                cursor.execute("UPDATE Reservation SET status = 'canceled' WHERE reservation_id = %s", (reservation_id,))
                next_status = 'canceled'

            elif action == "modify":
                if "expiration_time" not in new_data:
                    return Response({"error": "Only 'expiration_time' field is allowed for modification"}, status=400)
                cursor.execute("UPDATE Reservation SET expiration_time = %s WHERE reservation_id = %s", (
                    new_data["expiration_time"], reservation_id
                ))
                next_status = current_status

            else:
                return Response({"error": "Invalid action"}, status=400)
            
            if action == 'approve' or action == 'cancel':
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


class TicketReportAPIView(APIView):
    def post(self, request):
        user_id = request.data.get("user_id")
        ticket_id = request.data.get("ticket_id")
        report_category = request.data.get("report_category")
        report_text = request.data.get("report_text")

        if not all([user_id, ticket_id, report_category, report_text]):
            return Response({"error": "All fields are required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_id FROM User WHERE user_id = %s", (user_id,))
            if not cursor.fetchone():
                return Response({"error": "User not found"}, status=404)

            cursor.execute("SELECT ticket_id FROM Ticket WHERE ticket_id = %s", (ticket_id,))
            if not cursor.fetchone():
                return Response({"error": "Ticket not found"}, status=404)

            cursor.execute("""
                INSERT INTO Report (user_id, ticket_id, report_category, report_text, status, report_time)
                VALUES (%s, %s, %s, %s, 'pending', %s)
            """, (
                user_id, ticket_id, report_category, report_text, datetime.now()
            ))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Report submitted successfully"}, status=201)

        except Exception as e:
            return Response({"error": str(e)}, status=500)


class AdminReviewReportAPIView(APIView):
    def post(self, request):
        report_id = request.data.get("report_id")
        admin_id = request.data.get("admin_id")
        response_text = request.data.get("response_text")

        if not report_id or not admin_id:
            return Response({"error": "report_id and admin_id are required"}, status=400)
        if not response_text:
            return Response({"error": "response_text is required"}, status=400)

        try:
            conn = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = conn.cursor()

            cursor.execute("SELECT user_type FROM User WHERE user_id = %s", (admin_id,))
            user_type_result = cursor.fetchone()
            if not user_type_result or user_type_result[0] != 'ADMIN':
                return Response({"error": "Only admins can review reports"}, status=403)

            cursor.execute("SELECT status FROM Report WHERE report_id = %s", (report_id,))
            report = cursor.fetchone()
            if not report:
                return Response({"error": "Report not found"}, status=404)
            if report[0] == 'reviewed':
                return Response({"error": "Report already reviewed"}, status=400)

            cursor.execute("""
                UPDATE Report
                SET status = 'reviewed',
                    response_text = %s
                WHERE report_id = %s
            """, (response_text, report_id))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Report reviewed and response saved"})

        except Exception as e:
            return Response({"error": str(e)}, status=500)


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


            