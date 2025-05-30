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
    conn.commit()
    print(f"{cursor.rowcount} reservations canceled at {now}")  
    cursor.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")  
