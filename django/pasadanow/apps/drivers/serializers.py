from rest_framework import serializers
from .models import Driver, Ride


class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Driver
        fields = [
            'id', 'username', 'full_name', 'phone',
            'email', 'license_no', 'plate_no', 'toda_no',
            'profile_photo', 'is_online', 'verified_status',
            'created_at', 'updated_at'
        ]


class RideSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Ride
        fields = '__all__'