import MySQLdb
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime
import redis
import json
from datetime import datetime, timedelta

redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)


class SearchTicketsAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        data = request.data
        origin_city_name = data.get('origin_city')
        destination_city_name = data.get('destination_city')
        travel_date_str = data.get('travel_date')

        transport_type = data.get('transport_type')
        min_price = data.get('min_price')
        max_price = data.get('max_price')
        company_name = data.get('company_name')
        travel_class = data.get('travel_class')

        if not all([origin_city_name, destination_city_name, travel_date_str]):
            return Response({'error': 'Origin city name, destination city name, and travel date are required in the request body.'}, status=400)

        try:
            datetime.strptime(travel_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({'error': 'Invalid travel_date format. Use YYYY-MM-DD.'}, status=400)

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

            cursor.execute("SELECT city_id FROM City WHERE city_name = %s", (origin_city_name,))
            origin_city_result = cursor.fetchone()
            if not origin_city_result:
                return Response({"error": f"Origin city '{origin_city_name}' not found"}, status=404)
            origin_city_id = origin_city_result["city_id"]

            cursor.execute("SELECT city_id FROM City WHERE city_name = %s", (destination_city_name,))
            destination_city_result = cursor.fetchone()
            if not destination_city_result:
                return Response({"error": f"Destination city '{destination_city_name}' not found"}, status=404)
            destination_city_id = destination_city_result["city_id"]

            transport_company_id = None
            if company_name:
                cursor.execute("SELECT transport_company_id FROM TransportCompany WHERE company_name = %s", (company_name,))
                company_result = cursor.fetchone()
                if not company_result:
                    return Response({"error": f"Transport company '{company_name}' not found"}, status=404)
                transport_company_id = company_result["transport_company_id"]

            cache_key_parts = [
                f"search_tickets_post",
                f"ocid_{origin_city_id}",
                f"dcid_{destination_city_id}",
                f"date_{travel_date_str}"
            ]
            if transport_type: cache_key_parts.append(f"tt_{transport_type}")
            if min_price is not None: cache_key_parts.append(f"minp_{min_price}")
            if max_price is not None: cache_key_parts.append(f"maxp_{max_price}")
            if transport_company_id: cache_key_parts.append(f"compid_{transport_company_id}")
            if travel_class: cache_key_parts.append(f"tc_{travel_class}")
            cache_key = ":".join(cache_key_parts)

            try:
                cached_results = redis_client.get(cache_key)
                if cached_results:
                    return Response(json.loads(cached_results), status=200)
            except redis.exceptions.RedisError:
                pass

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
            if transport_company_id:
                base_query += " AND tr.transport_company_id = %s"
                query_params.append(transport_company_id)
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
            if travel_class:
                base_query += " AND tr.travel_class = %s"
                query_params.append(travel_class)

            base_query += " GROUP BY tr.travel_id ORDER BY tr.departure_time ASC, demand_score DESC"

            cursor.execute(base_query, tuple(query_params))
            rows = cursor.fetchall()

            results = []
            for row in rows:
                row['departure_time'] = row['departure_time'].isoformat() if isinstance(row.get('departure_time'), datetime) else str(row.get('departure_time'))
                row['arrival_time'] = row['arrival_time'].isoformat() if isinstance(row.get('arrival_time'), datetime) else str(row.get('arrival_time'))
                results.append(row)

            try:
                redis_client.setex(cache_key, timedelta(minutes=15), json.dumps(results))
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