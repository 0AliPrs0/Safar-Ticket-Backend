from django.urls import path
from .views import CityListView, SendOtpAPIView, VerifyOtpAPIView


urlpatterns = [
    path('cities/', CityListView.as_view()),
    path('send-otp/', SendOtpAPIView.as_view()),
    path('verify-otp/', VerifyOtpAPIView.as_view()),
]