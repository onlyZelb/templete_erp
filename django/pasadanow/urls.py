from django.urls import path, include

urlpatterns = [
    path('api/drivers/',        include('pasadanow.apps.drivers.urls')),
    path('api/earnings/',       include('pasadanow.apps.earnings.urls')),
    path('api/admin/',          include('pasadanow.apps.admin_api.urls')),
    path('api/commuters/',      include('pasadanow.apps.commuters.urls')),
    path('api/',                include('pasadanow.apps.fare.urls')),

    # ── Rides ─────────────────────────────────────────────────────────────
    path('api/rides/<int:ride_id>/report',
         __import__('pasadanow.apps.commuters.views', fromlist=['RideReportView']).RideReportView.as_view()),
]