import MySQLdb
import redis 
from rest_framework.views import APIView
from rest_framework.response import Response
import datetime


redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)


class TicketReportAPIView(APIView):
    def post(self, request):
        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        user_id = user_info.get('user_id')
        
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

        user_info = getattr(request, 'user_info', None)
        if not user_info:
            return Response({"error": "Authentication credentials were not provided."}, status=401)

        admin_id = user_info.get('user_id')

        report_id = request.data.get("report_id")
        response_text = request.data.get("report_response")

        if not report_id:
            return Response({"error": "report_id are required"}, status=400)
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
                    report_response = %s
                WHERE report_id = %s
            """, (response_text, report_id))

            conn.commit()
            cursor.close()
            conn.close()

            return Response({"message": "Report reviewed and response saved"})

        except Exception as e:
            return Response({"error": str(e)}, status=500)