from django.urls import path
from .views import CityListView, SendOtpAPIView, VerifyOtpAPIView, SignupUserAPIView, TicketDetailAPIView, ProfileUserUpdateAPIView, SearchTicketsAPIView, TicketPaymentAPIView, UserBookingsAPIView, TicketCancelAPIView, AdminManageReservationAPIView, TicketReportAPIView, AdminReviewReportAPIView, UserReservationsAPIView, ReserveTicketAPIView


urlpatterns = [
    path('cities/', CityListView.as_view()),
    path('send-otp/', SendOtpAPIView.as_view()),
    path('verify-otp/', VerifyOtpAPIView.as_view()),
    path('signup/', SignupUserAPIView.as_view()),
    path('ticket/<int:ticket_id>/', TicketDetailAPIView.as_view()),
    path('update-profile/', ProfileUserUpdateAPIView.as_view()),
    path('search-tickets/', SearchTicketsAPIView.as_view()), 
    path('payment-ticket/', TicketPaymentAPIView.as_view()),
    path('user-booking/', UserBookingsAPIView.as_view()),
    path('cancel-ticket/', TicketCancelAPIView.as_view()),
    path('ticket-management/', AdminManageReservationAPIView.as_view()),
    path('report-ticket/', TicketReportAPIView.as_view()),
    path('review-report/', AdminReviewReportAPIView.as_view()),
    path('reserve-ticket/', ReserveTicketAPIView.as_view()),
    path('reservation/', UserReservationsAPIView.as_view()),
]