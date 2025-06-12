import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import redis
import json

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)


class TicketPaymentAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)
        
        user_id = user_info.get('user_id')
        reservation_id = request.data.get('reservation_id')
        payment_method = request.data.get('payment_method')

        if not all([reservation_id, payment_method]):
            return Response({"error": "Missing required fields"}, status=400)
        
        reservation_data = None
        redis_key = f"reservation_details:{reservation_id}"
        try:
            cached_data = redis_client.get(redis_key)
            if not cached_data:
                return Response({"error": "Reservation not found or has expired."}, status=404)
            reservation_data = json.loads(cached_data)
        except redis.exceptions.RedisError as e:
            return Response({"error": "Cache service is currently unavailable. Please try again later."}, status=503)

        if reservation_data.get('user_id') != user_id:
            return Response({"error": "This reservation does not belong to you."}, status=403)

        if reservation_data.get('status') != 'reserved':
            return Response({"error": "Reservation is not in a payable state."}, status=400)

        amount = reservation_data.get('price')
        
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

            if payment_method == 'wallet':
                cursor.execute("SELECT wallet FROM User WHERE user_id = %s FOR UPDATE", (user_id,))
                wallet_info = cursor.fetchone()
                if not wallet_info or wallet_info.get('wallet', 0) < amount:
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
                redis_client.delete(redis_key)
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