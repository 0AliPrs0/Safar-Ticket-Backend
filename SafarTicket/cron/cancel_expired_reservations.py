import MySQLdb
from datetime import datetime

try:
    conn = MySQLdb.connect(
        host="db",
        user="root",
        password="Aliprs2005",
        database="safarticket",
        port=3306
    )
    cursor = conn.cursor()
    now = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')

    cursor.execute("""
        UPDATE Reservation
        SET status = 'canceled'
        WHERE status = 'reserved' AND expiration_time < %s
    """, (now,))
    expired_count = cursor.rowcount

    cursor.execute("""
        UPDATE Reservation
        SET status = 'canceled'
        WHERE status = 'reserved' AND user_id IN (
            SELECT user_id FROM User WHERE account_status = 'INACTIVE'
        )
    """)
    inactive_user_count = cursor.rowcount

    conn.commit()

    print(f"{expired_count} reservations canceled due to expiration at {now}")
    print(f"{inactive_user_count} reservations canceled due to inactive users")

    cursor.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")