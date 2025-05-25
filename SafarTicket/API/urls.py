from django.urls import path
from .views import CityListView, SendOtpAPIView, VerifyOtpAPIView


urlpatterns = [
    path('cities/', CityListView.as_view()),
    path('api/send-otp/', SendOtpAPIView.as_view()),
    path('api/verify-otp/', VerifyOtpAPIView.as_view()),
]