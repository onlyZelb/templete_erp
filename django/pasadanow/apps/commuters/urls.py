from django.urls import path
from .views import CommuterProfileView, RideReportView, debug_view

urlpatterns = [
    path('me/profile',              CommuterProfileView.as_view()),
    path('debug',                   debug_view),
]