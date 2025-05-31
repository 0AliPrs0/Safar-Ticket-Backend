import smtplib
from email.mime.text import MIMEText
from django.conf import settings

def send_otp_email(to_email, otp):
    subject = "Your OTP Code"
    body = f"Your OTP code is: {otp}. It will expire in 5 minutes."

    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = settings.EMAIL_HOST_USER
    msg['To'] = to_email

    with smtplib.SMTP(settings.EMAIL_HOST, settings.EMAIL_PORT) as server:
        server.starttls()
        server.login(settings.EMAIL_HOST_USER, settings.EMAIL_HOST_PASSWORD)
        server.send_message(msg)

def send_payment_reminder_email(to_email, expiration_time):
    subject = "Payment Reminder for Your Ticket Reservation"
    body = (
        f"You have successfully reserved your ticket.\n"
        f"Please complete the payment **before {expiration_time.strftime('%H:%M:%S')}**, "
        f"otherwise the reservation will be cancelled automatically."
    )

    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = settings.EMAIL_HOST_USER
    msg['To'] = to_email

    with smtplib.SMTP(settings.EMAIL_HOST, settings.EMAIL_PORT) as server:
        server.starttls()
        server.login(settings.EMAIL_HOST_USER, settings.EMAIL_HOST_PASSWORD)
        server.send_message(msg)