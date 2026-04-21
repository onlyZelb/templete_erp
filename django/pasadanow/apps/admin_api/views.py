from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from pasadanow.apps.drivers.models import Driver, Ride
from pasadanow.apps.drivers.serializers import DriverSerializer, RideSerializer


class AllUsersView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id, username, full_name, phone, email,
                       'commuter' as role, verified_status, created_at
                FROM commuters
                UNION ALL
                SELECT id, username, full_name, phone, email,
                       'driver' as role, verified_status, created_at
                FROM drivers
                ORDER BY created_at DESC
            """)
            columns = [col[0] for col in cursor.description]
            users   = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return Response(users)


class VerifyUserView(APIView):
    permission_classes = [AllowAny]

    def patch(self, request, user_id):
        role   = request.data.get('role')
        action = request.data.get('action')

        if action not in ['verified', 'rejected']:
            return Response(
                {'error': 'action must be verified or rejected'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with __import__('django').db.connection.cursor() as cursor:
            if role == 'driver':
                cursor.execute("""
                    UPDATE drivers SET verified_status = %s
                    WHERE id = %s RETURNING id, username, verified_status
                """, [action, user_id])
            elif role == 'commuter':
                cursor.execute("""
                    UPDATE commuters SET verified_status = %s
                    WHERE id = %s RETURNING id, username, verified_status
                """, [action, user_id])
            else:
                return Response(
                    {'error': 'role must be commuter or driver'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            row = cursor.fetchone()
            if not row:
                return Response({'error': 'User not found'}, status=404)

        return Response({
            'id':              row[0],
            'username':        row[1],
            'verified_status': row[2]
        })


class AllRidesView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        rides = Ride.objects.all().order_by('-created_at')
        return Response(RideSerializer(rides, many=True).data)