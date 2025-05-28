from django.urls import path
from .views import CityListView, SendOtpAPIView, VerifyOtpAPIView, SignupUserAPIView, TicketDetailAPIView, ProfileUserUpdateAPIView, SearchTicketsAPIView


urlpatterns = [
    path('cities/', CityListView.as_view()),
    path('send-otp/', SendOtpAPIView.as_view()),
    path('verify-otp/', VerifyOtpAPIView.as_view()),
    path('signup/', SignupUserAPIView.as_view()),
    path('ticket/<int:ticket_id>/', TicketDetailAPIView.as_view()),
    path('profile/update/', ProfileUserUpdateAPIView.as_view()),
    path('tickets/search/', SearchTicketsAPIView.as_view(), name='search-tickets'),
]