from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework import status
from .models import Driver, Ride
from .serializers import DriverSerializer, RideSerializer


def get_driver(username):
    try:
        return Driver.objects.get(username=username)
    except Driver.DoesNotExist:
        raise NotFound('Driver not found')

def get_username(request):
    auth = request.auth
    if isinstance(auth, dict):
        return auth.get('sub')
    return None


class DriverMeView(APIView):
    def get(self, request):
        driver = get_driver(get_username(request))
        return Response(DriverSerializer(driver).data)


class DriverStatusView(APIView):
    def patch(self, request):
        driver    = get_driver(get_username(request))
        is_online = request.data.get('is_online')
        if is_online is None:
            return Response({'error': 'is_online field required'}, status=400)
        driver.is_online = is_online
        driver.save(update_fields=['is_online', 'updated_at'])
        return Response({'username': driver.username, 'is_online': driver.is_online})


class AvailableDriversView(APIView):
    def get(self, request):
        drivers = Driver.objects.filter(is_online=True, verified_status='verified')
        return Response(DriverSerializer(drivers, many=True).data)


class AcceptRideView(APIView):
    def patch(self, request, ride_id):
        driver = get_driver(get_username(request))
        if driver.verified_status != 'verified':
            raise PermissionDenied('Your account is not verified yet')
        try:
            ride = Ride.objects.get(id=ride_id, status='pending')
        except Ride.DoesNotExist:
            raise NotFound('Ride not found or already taken')
        ride.driver = driver
        ride.status = 'accepted'
        ride.save(update_fields=['driver_id', 'status', 'updated_at'])
        return Response(RideSerializer(ride).data)


class CompleteRideView(APIView):
    def patch(self, request, ride_id):
        driver = get_driver(get_username(request))
        try:
            ride = Ride.objects.get(id=ride_id, driver=driver, status='accepted')
        except Ride.DoesNotExist:
            raise NotFound('Ride not found or not yours')
        ride.status = 'completed'
        ride.save(update_fields=['status', 'updated_at'])
        from pasadanow.apps.earnings.models import Earning
        Earning.objects.create(driver=driver, ride=ride, amount=ride.fare)
        return Response(RideSerializer(ride).data)


class PendingRideView(APIView):
    """Driver polls this to get a ride request."""
    def get(self, request):
        username = get_username(request)
        driver   = get_driver(username)
        try:
            ride = Ride.objects.filter(
                status='pending', driver__isnull=True
            ).order_by('created_at').first()
            if not ride:
                return Response({})
            return Response(RideSerializer(ride).data)
        except Exception:
            return Response({})


class DriverLocationView(APIView):
    """Driver pushes GPS so commuter can see it."""
    def post(self, request):
        from django.db import connection
        username = get_username(request)
        driver   = get_driver(username)
        lat = request.data.get('lat')
        lng = request.data.get('lng')
        with connection.cursor() as cursor:
            cursor.execute("""
                UPDATE rides SET driver_lat = %s, driver_lng = %s,
                updated_at = NOW()
                WHERE driver_id = %s AND status IN ('accepted','ongoing')
            """, [lat, lng, driver.id])
        return Response({'status': 'ok'})


class CommuterLocationView(APIView):
    """Driver reads commuter GPS during active ride."""
    def get(self, request, ride_id):
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT commuter_lat, commuter_lng
                FROM rides WHERE id = %s
            """, [ride_id])
            row = cursor.fetchone()
            if not row or row[0] is None:
                return Response({})
        return Response({'lat': row[0], 'lng': row[1]})