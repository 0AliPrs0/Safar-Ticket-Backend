from django.urls import path
from .views import CityListView

urlpatterns = [
    path('cities/', CityListView.as_view()),
]