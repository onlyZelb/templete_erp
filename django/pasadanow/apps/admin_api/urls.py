from django.urls import path
from .views import AllUsersView, VerifyUserView, AllRidesView

urlpatterns = [
    path('users',            AllUsersView.as_view()),
    path('users/<int:user_id>/verify', VerifyUserView.as_view()),
    path('rides',            AllRidesView.as_view()),
]