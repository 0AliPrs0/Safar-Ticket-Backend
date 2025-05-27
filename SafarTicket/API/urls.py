from django.urls import path
from .views import CityListView, SendOtpAPIView, VerifyOtpAPIView, SignupUserAPIView, TicketDetailAPIView


urlpatterns = [
    path('cities/', CityListView.as_view()),
    path('send-otp/', SendOtpAPIView.as_view()),
    path('verify-otp/', VerifyOtpAPIView.as_view()),
    path('signup/', SignupUserAPIView.as_view()),
    path('ticket/<int:ticket_id>/', TicketDetailAPIView.as_view()),
]