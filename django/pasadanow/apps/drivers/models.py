from django.db import models


class Driver(models.Model):
    username        = models.CharField(max_length=50, unique=True)
    password        = models.CharField(max_length=255)
    full_name       = models.CharField(max_length=100, blank=True, null=True)
    phone           = models.CharField(max_length=20, blank=True, null=True)
    email           = models.CharField(max_length=100, blank=True, null=True)
    license_no      = models.CharField(max_length=50)
    plate_no        = models.CharField(max_length=30)
    toda_no         = models.CharField(max_length=50, blank=True, null=True)
    profile_photo   = models.TextField(blank=True, null=True)
    is_online       = models.BooleanField(default=False)
    verified_status = models.CharField(max_length=20, default='pending')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'drivers'
        managed  = False  # Flyway manages the table


class Ride(models.Model):
    commuter_id     = models.BigIntegerField()
    driver          = models.ForeignKey(
                        Driver, null=True, blank=True,
                        on_delete=models.SET_NULL,
                        db_column='driver_id')
    pickup_location = models.TextField()
    destination     = models.TextField()
    fare            = models.DecimalField(max_digits=8, decimal_places=2)
    status          = models.CharField(max_length=20, default='pending')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'rides'
        managed  = False