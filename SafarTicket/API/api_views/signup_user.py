import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
import hashlib
from ..utils.jwt import generate_access_token, generate_refresh_token, verify_jwt

class SignupUserAPIView(APIView):
    def post(self, request):
        data = request.data
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        email = data.get('email')
        phone_number = data.get('phone_number')
        password = data.get('password')
        city_name = data.get('city_name')

        if not all([first_name, last_name, email, phone_number, password]):
            return Response({'error': 'All main fields (first_name, last_name, email, phone_number, password) are required'}, status=400)

        password_hash = hashlib.sha256(password.encode()).hexdigest()
        registration_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        db = None
        cursor = None
        try:
            db = MySQLdb.connect(
                host="db",
                user="root",
                password="Aliprs2005",
                database="safarticket",
                port=3306
            )
            cursor = db.cursor()

            city_id = 1
            if city_name:
                cursor.execute("SELECT city_id FROM City WHERE city_name = %s", (city_name,))
                city_result = cursor.fetchone()
                if city_result:
                    city_id = city_result[0]
                else:
                    return Response({"error": f"City '{city_name}' not found. Please provide a valid city name."}, status=404)

            cursor.execute("SELECT user_id FROM User WHERE email = %s", (email,))
            if cursor.fetchone():
                return Response({'error': 'User with this email already exists'}, status=400)

            cursor.execute("""
                INSERT INTO User (first_name, last_name, email, phone_number, password_hash, user_type, city_id, registration_date, account_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (first_name, last_name, email, phone_number, password_hash, "CUSTOMER", city_id, registration_date, "ACTIVE"))

            db.commit()
            user_id = cursor.lastrowid
            
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
                    'user_type': 'CUSTOMER',
                    'city_id': city_id,
                    'registration_date': registration_date,
                    'account_status': 'ACTIVE'
                }
            }, status=201)

        except MySQLdb.Error as e:
            return Response({'error': f"Database error: {str(e)}"}, status=500)
        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            if cursor:
                cursor.close()
            if db:
                db.close()