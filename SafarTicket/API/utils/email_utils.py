import smtplib
from email.mime.text import MIMEText
from django.conf import settings

import smtplib
from email.mime.text import MIMEText
from django.conf import settings

def send_otp_email(to_email, otp):
    subject = "Your Verification Code"
    frontend_url = getattr(settings, 'FRONTEND_BASE_URL', 'http://localhost:8000')
    verification_link = f"{frontend_url}/api/verify-otp/?email={to_email}&otp={otp}"

    body = f"""
    <html>
      <body>
        <p>Your verification code is: <b>{otp}</b></p>
        <p>This code will expire in 5 minutes.</p>
        <p>Alternatively, you can click the link below to verify your account:</p>
        <p><a href="{verification_link}">Verify Your Account</a></p>
        <p>If you did not request this code, please ignore this email.</p>
      </body>
    </html>
    """

    msg = MIMEText(body, 'html')
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