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
