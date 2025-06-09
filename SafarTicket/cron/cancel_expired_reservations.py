import MySQLdb
from datetime import datetime

conn = None
try:
    conn = MySQLdb.connect(
        host="db",
        user="root",
        password="Aliprs2005",
        database="safarticket",
        port=3306
    )
    cursor = conn.cursor()
    now_str = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')

    conn.begin()

    cursor.execute("""
        SELECT ticket_id FROM Reservation
        WHERE status = 'reserved' AND expiration_time < %s
    """, (now_str,))
    
    expired_ticket_ids = tuple(item[0] for item in cursor.fetchall())

    expired_count = 0
    if expired_ticket_ids:
        cursor.execute("""
            UPDATE Travel t
            JOIN Ticket ti ON t.travel_id = ti.travel_id
            SET t.remaining_capacity = t.remaining_capacity + 1
            WHERE ti.ticket_id IN %s
        """, (expired_ticket_ids,))

        cursor.execute("""
            UPDATE Reservation
            SET status = 'canceled'
            WHERE ticket_id IN %s
        """, (expired_ticket_ids,))
        expired_count = cursor.rowcount

    cursor.execute("""
        SELECT ticket_id FROM Reservation
        WHERE status = 'reserved' AND user_id IN (
            SELECT user_id FROM User WHERE account_status = 'INACTIVE'
        )
    """)
    inactive_user_ticket_ids = tuple(item[0] for item in cursor.fetchall())
    
    inactive_user_count = 0
    if inactive_user_ticket_ids:
        cursor.execute("""
            UPDATE Travel t
            JOIN Ticket ti ON t.travel_id = ti.travel_id
            SET t.remaining_capacity = t.remaining_capacity + 1
            WHERE ti.ticket_id IN %s
        """, (inactive_user_ticket_ids,))

        cursor.execute("""
            UPDATE Reservation
            SET status = 'canceled'
            WHERE ticket_id IN %s
        """, (inactive_user_ticket_ids,))
        inactive_user_count = cursor.rowcount

    conn.commit()

    print(f"[{datetime.utcnow()}] {expired_count} reservations canceled due to expiration.")
    print(f"[{datetime.utcnow()}] {inactive_user_count} reservations canceled due to inactive users.")

except Exception as e:
    if conn:
        conn.rollback()
    print(f"[{datetime.utcnow()}] Error: {e}")
finally:
    if conn:
        cursor.close()
        conn.close()