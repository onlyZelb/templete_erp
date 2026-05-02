from django.urls import path
from .views import CommuterProfileView, debug_view

urlpatterns = [
    path('me/profile',  CommuterProfileView.as_view()),
    path('debug',       debug_view),               # ← add this
]