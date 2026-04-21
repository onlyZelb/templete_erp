from django.urls import path
from .views import (
    DriverMeView,
    DriverStatusView,
    AvailableDriversView,
    AcceptRideView,
    CompleteRideView,
)

urlpatterns = [
    path('me',                           DriverMeView.as_view()),
    path('me/status',                    DriverStatusView.as_view()),
    path('available',                    AvailableDriversView.as_view()),
    path('rides/<int:ride_id>/accept',   AcceptRideView.as_view()),
    path('rides/<int:ride_id>/complete', CompleteRideView.as_view()),
]
