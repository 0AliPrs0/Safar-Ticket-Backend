import smtplib
from email.mime.text import MIMEText
from django.conf import settings
import smtplib
from email.mime.text import MIMEText
from django.conf import settings
import datetime


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

def send_payment_reminder_email(to_email, expiration_time, reservation_details):
    subject = "Payment Reminder for Your Ticket Reservation"
    frontend_url = getattr(settings, 'FRONTEND_BASE_URL', 'http://localhost:8000')
    verification_link = f"{frontend_url}/api/payment-ticket/"
    formatted_expiration_time = expiration_time.strftime('%H:%M:%S on %Y-%m-%d')

    body = f"""
    <html>
      <head>
        <style>
          body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; }}
          .container {{ padding: 20px; border: 1px solid #ddd; border-radius: 8px; max-width: 600px; margin: auto; }}
          .header {{ font-size: 24px; color: #0D47A1; text-align: center; margin-bottom: 20px; }}
          .details {{ margin: 20px 0; }}
          .details p {{ margin: 5px 0; }}
          .footer {{ font-size: 12px; color: #777; text-align: center; margin-top: 30px; }}
          .highlight {{ color: #D32F2F; font-weight: bold; }}
        </style>
      </head>
      <body>
        <div class="container">
          <h1 class="header">Payment Reminder</h1>
          <div class="details">
            <p>Hello,</p>
            <p>You have successfully reserved a ticket with the following details:</p>
            <ul>
              <li><strong>Reservation ID:</strong> {reservation_details.get('reservation_id')}</li>
              <li><strong>Travel:</strong> From {reservation_details.get('departure_city')} to {reservation_details.get('destination_city')}</li>
              <li><strong>Departure Time:</strong> {reservation_details.get('departure_time')}</li>
            </ul>
            <p>Please complete the payment for your reservation before it expires.</p>
            <p>Your reservation is held until <span class="highlight">{formatted_expiration_time}</span>.</p>
            <p><a href="{verification_link}">Pay Reservation</a></p>
            <p>If payment is not completed by this time, your reservation will be automatically cancelled.</p>
            <p>Thank you for choosing SafarTicket!</p>
          </div>
          <div class="footer">
            This is an automated message. Please do not reply to this email.
          </div>
        </div>
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