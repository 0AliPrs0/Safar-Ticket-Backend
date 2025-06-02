import MySQLdb
from django.http import JsonResponse
from django.views import View
import random
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
from ..utils.email_utils import send_otp_email, send_payment_reminder_email 
from ..serializers import UserSerializer 
import datetime
import hashlib 
from ..utils.jwt import generate_jwt 
from rest_framework.permissions import IsAuthenticated
import json
from datetime import datetime, timedelta 


redis_client = redis.Redis(host='redis', port=6379, db=0)




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