import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../login_screen.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────
const _navy = Color(0xFF0D1B2A);
const _navyLight = Color(0xFF132236);
const _card = Color(0xFF16293D);
const _cardBorder = Color(0xFF1E3650);
const _accent = Color(0xFF2D8CFF);
const _green = Color(0xFF1DBE74);
const _orange = Color(0xFFF4A620);
const _purple = Color(0xFFA855F7);
const _red = Color(0xFFEF4444);
const _textPrim = Color(0xFFE8EEF4);
const _textSub = Color(0xFF6B8BA4);
const _routeColor = Color(0xFF2D8CFF);

Color _o(Color c, double a) => c.withValues(alpha: a);

class CommuterHome extends StatefulWidget {
  const CommuterHome({super.key});
  @override
  State<CommuterHome> createState() => _CommuterHomeState();
}

class _CommuterHomeState extends State<CommuterHome>
    with WidgetsBindingObserver {
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _mapController = MapController();

  List _rides = [];
  String? _fare;
  bool _loading = false;
  int _tab = 0;
  String? _selectedDriver;
  String? _selectedDriverId;

  // ── Route / fare metrics ──────────────────────────────────────────────
  LatLng? _pickupLatLng;
  LatLng? _destLatLng;
  List<LatLng> _routePoints = [];
  double? _routeDistKm;
  double? _routeDurationMin;
  bool _routeLoading = false;

  // ── REAL-TIME GPS (matches driver implementation exactly) ─────────────
  LatLng? _myLocation;
  StreamSubscription<Position>? _locationStream;
  bool _isTracking = false;
  bool _gpsForced = false;
  Timer? _retryTimer;
  Timer? _debounce;

  // GPS telemetry — same fields as driver
  double? _gpsAccuracy;
  double? _gpsSpeed;
  double? _gpsHeading;
  DateTime? _lastGpsUpdate;

  // ── Active ride status polling ────────────────────────────────────────
  Timer? _rideStatusTimer;
  Map<String, dynamic>? _activeBooking;
  String? _activeBookingStatus;
  LatLng? _driverLiveLocation;

  // ── Nearby drivers ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _nearbyDrivers = [];
  bool _driversLoading = false;
  // FIX: faster 5-second refresh so newly-online drivers appear quickly
  Timer? _driversRefreshTimer;

  // ── Commuter profile ──────────────────────────────────────────────────
  String _profileContact = '—';
  String _profileLocation = '—';

  // ── Computed stats ────────────────────────────────────────────────────
  int get _totalBookings => _rides.length;
  int get _onlineDrivers => _nearbyDrivers.length;
  String get _lastFare =>
      _rides.isNotEmpty ? '₱${_rides.last['fare'] ?? '0'}' : '₱0.00';
  String get _totalSpent {
    final t = _rides.fold<double>(
        0, (s, r) => s + (double.tryParse(r['fare']?.toString() ?? '0') ?? 0));
    return '₱${t.toStringAsFixed(2)}';
  }

  String get _computedFare {
    if (_routeDistKm == null) return _fare ?? '—';
    final computed = 15.0 + (_routeDistKm! * 8.0);
    return '₱${computed.toStringAsFixed(2)}';
  }

  // ════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGPS(); // FIX: use driver-style GPS init
    _loadRides();
    _loadNearbyDrivers();
    _loadCommuterProfile();
    _pickup.addListener(_onFieldChanged);
    _destination.addListener(_onFieldChanged);

    // FIX: poll every 5 seconds (was 10) so new drivers appear quickly
    _driversRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadNearbyDrivers());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStream?.cancel();
    _retryTimer?.cancel();
    _debounce?.cancel();
    _rideStatusTimer?.cancel();
    _driversRefreshTimer?.cancel();
    _pickup.removeListener(_onFieldChanged);
    _destination.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isTracking) {
      _initGPS();
    }
  }

  void _onFieldChanged() {
    if (_pickup.text.trim().length > 3 && _destination.text.trim().length > 3) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        if (mounted) _fetchRoute();
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  GPS — mirrors driver_home.dart exactly
  //  • Last-known position for instant map response
  //  • One getCurrentPosition for precision
  //  • Continuous stream: bestForNavigation, 2 s / 3 m, foreground wake-lock
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _initGPS() async {
    await _locationStream?.cancel();
    _locationStream = null;

    // ── 1. Service check ──────────────────────────────────────────────────
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDisabledDialog();
      _scheduleGpsRetry();
      return;
    }

    // ── 2. Permission check ───────────────────────────────────────────────
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (permission == LocationPermission.deniedForever && mounted) {
        _showPermissionPermanentlyDeniedDialog();
      }
      _useFallback();
      return;
    }

    // ── 3. Last-known position (instant) ─────────────────────────────────
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        final loc = LatLng(last.latitude, last.longitude);
        setState(() {
          _myLocation = loc;
          _gpsAccuracy = last.accuracy;
          _gpsSpeed = last.speed;
          _gpsHeading = last.heading;
          _lastGpsUpdate = DateTime.now();
          _isTracking = true;
        });
        _mapController.move(loc, 16);
      }
    } catch (_) {}

    // ── 4. Precise one-shot position ─────────────────────────────────────
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _myLocation = loc;
          _gpsAccuracy = pos.accuracy;
          _gpsSpeed = pos.speed;
          _gpsHeading = pos.heading;
          _lastGpsUpdate = DateTime.now();
          _isTracking = true;
          _gpsForced = false;
        });
        _mapController.move(loc, 16);
      }
    } catch (_) {}

    // ── 5. Continuous stream — 2-second / 3-metre, foreground wake-lock ──
    _locationStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'PasadaNow is tracking your location',
          notificationTitle: 'Location Active',
          enableWakeLock: true,
        ),
      ),
    ).listen(
      (Position pos) {
        if (!mounted) return;
        final updated = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _myLocation = updated;
          _gpsAccuracy = pos.accuracy;
          _gpsSpeed = pos.speed;
          _gpsHeading = pos.heading;
          _lastGpsUpdate = DateTime.now();
          _isTracking = true;
        });
        // Auto-follow map when no route and no active ride
        if (_routePoints.isEmpty && _activeBooking == null) {
          _mapController.move(updated, _mapController.camera.zoom);
        }
        // Push commuter location to backend during an active ride
        if (_activeBooking != null) {
          _pushCommuterLocation(updated);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isTracking = false);
        _scheduleGpsRetry();
      },
    );

    _retryTimer?.cancel();
  }

  /// Push commuter's real-time GPS to the backend so the driver can see it.
  Future<void> _pushCommuterLocation(LatLng loc) async {
    if (_activeBooking == null) return;
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      await dio.post('/rides/${_activeBooking!['id']}/location', data: {
        'lat': loc.latitude,
        'lng': loc.longitude,
        'accuracy': _gpsAccuracy,
        'speed': _gpsSpeed,
        'heading': _gpsHeading,
      });
    } catch (_) {}
  }

  void _scheduleGpsRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final svc = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      if (svc &&
          perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        _retryTimer?.cancel();
        _initGPS();
      }
    });
  }

  void _useFallback() {
    const fallback = LatLng(14.5995, 120.9842);
    if (mounted) {
      setState(() {
        _myLocation = fallback;
        _isTracking = false;
      });
      _mapController.move(fallback, 15);
    }
  }

  // ── GPS helpers ───────────────────────────────────────────────────────
  String get _gpsAccuracyLabel {
    if (_gpsAccuracy == null) return '—';
    if (_gpsAccuracy! < 5) return 'Excellent';
    if (_gpsAccuracy! < 15) return 'Good';
    if (_gpsAccuracy! < 40) return 'Fair';
    return 'Poor';
  }

  Color get _gpsAccuracyColor {
    if (_gpsAccuracy == null) return _textSub;
    if (_gpsAccuracy! < 5) return _green;
    if (_gpsAccuracy! < 15) return _green;
    if (_gpsAccuracy! < 40) return _orange;
    return _red;
  }

  String get _gpsSpeedLabel {
    if (_gpsSpeed == null || _gpsSpeed! < 0.5) return '0 km/h';
    return '${(_gpsSpeed! * 3.6).toStringAsFixed(1)} km/h';
  }

  // ════════════════════════════════════════════════════════════════════════
  //  GPS DIALOGS
  // ════════════════════════════════════════════════════════════════════════

  void _showGpsDisabledDialog() {
    if (!mounted || _gpsForced) return;
    setState(() => _gpsForced = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('📍', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text('GPS is Off', style: TextStyle(color: _textPrim, fontSize: 16)),
        ]),
        content: const Text(
          'PasadaNow needs your GPS to show your live location and '
          'calculate accurate fares.\n\nPlease turn on Location Services.',
          style: TextStyle(color: _textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _gpsForced = false);
            },
            child: const Text('Later', style: TextStyle(color: _textSub)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Text('⚙️', style: TextStyle(fontSize: 13)),
            label: const Text('Open Settings'),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _gpsForced = false);
              await Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('🚫', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text('Permission Denied',
              style: TextStyle(color: _textPrim, fontSize: 16)),
        ]),
        content: const Text(
          'Location permission is permanently denied.\n\n'
          'Please open App Settings → Permissions → Location → Allow.',
          style: TextStyle(color: _textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textSub)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Text('⚙️', style: TextStyle(fontSize: 13)),
            label: const Text('App Settings'),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  GEOCODING & ROUTING
  // ════════════════════════════════════════════════════════════════════════

  Future<LatLng?> _geocode(String address) async {
    try {
      final bias = _myLocation != null
          ? '&viewbox=${_myLocation!.longitude - 0.5},${_myLocation!.latitude + 0.5},'
              '${_myLocation!.longitude + 0.5},${_myLocation!.latitude - 0.5}&bounded=1'
          : '';
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(address)}&format=json&limit=1$bias',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'PasadaNow/1.0'});
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return null;
      return LatLng(
        double.parse(data[0]['lat'] as String),
        double.parse(data[0]['lon'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickup.text.isEmpty || _destination.text.isEmpty) return;
    if (_routeLoading) return;
    setState(() {
      _routeLoading = true;
      _routePoints = [];
    });

    try {
      final a = await _geocode(_pickup.text.trim());
      final b = await _geocode(_destination.text.trim());
      if (a == null || b == null) {
        if (mounted)
          _showSnack('Could not find one of the locations.', _orange);
        setState(() => _routeLoading = false);
        return;
      }

      setState(() {
        _pickupLatLng = a;
        _destLatLng = b;
      });

      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving'
        '/${a.longitude},${a.latitude};${b.longitude},${b.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res =
          await http.get(osrmUri, headers: {'Accept': 'application/json'});
      final json = jsonDecode(res.body);

      if (json['code'] != 'Ok') {
        setState(() => _routeLoading = false);
        if (mounted) _showSnack('No route found between locations.', _orange);
        return;
      }

      final route = json['routes'][0];
      final distM = (route['distance'] as num).toDouble();
      final durS = (route['duration'] as num).toDouble();
      final coords = route['geometry']['coordinates'] as List;

      final points = coords
          .map<LatLng>(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      setState(() {
        _routePoints = points;
        _routeDistKm = distM / 1000;
        _routeDurationMin = durS / 60;
        _fare = _computedFare;
        _routeLoading = false;
      });

      if (points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 60)));
      }
    } catch (_) {
      setState(() => _routeLoading = false);
      if (mounted)
        _showSnack('Route fetch failed. Check connection.', Colors.redAccent);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  API CALLS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _loadRides() async {
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/rides');
      if (mounted) setState(() => _rides = res.data);
    } catch (_) {}
  }

  // FIX: validate selected driver still online after each refresh
  Future<void> _loadNearbyDrivers() async {
    if (!mounted) return;
    if (_driversLoading) return;
    setState(() => _driversLoading = true);
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/drivers/online');
      if (mounted) {
        final fetched = List<Map<String, dynamic>>.from(
          (res.data as List).map((d) {
            final name = d['name']?.toString() ?? '';
            final initials = name.length >= 2
                ? name.substring(0, 2).toUpperCase()
                : name.toUpperCase().padRight(2, 'D');
            return {
              'id': d['id']?.toString() ?? '',
              'initials': initials,
              'name': name,
              'plate':
                  '${d['plate_number'] ?? d['plate'] ?? '—'} · ${d['vehicle_type'] ?? 'Vehicle'}',
              'rating': d['rating']?.toString() ?? '—',
              'trips': d['total_trips']?.toString() ?? '—',
            };
          }),
        );

        // FIX: clear the dropdown selection if the chosen driver went offline
        final stillOnline = fetched.any((d) => d['id'] == _selectedDriverId);
        setState(() {
          _nearbyDrivers = fetched;
          _driversLoading = false;
          if (!stillOnline) {
            _selectedDriverId = null;
            _selectedDriver = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _driversLoading = false);
    }
  }

  Future<void> _loadCommuterProfile() async {
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/commuters/me/profile');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _profileContact = data['contact']?.toString() ?? '—';
          _profileLocation = data['location']?.toString() ?? '—';
        });
      }
    } catch (_) {}
  }

  Future<void> _estimateFare() async => _fetchRoute();

  // ════════════════════════════════════════════════════════════════════════
  //  BOOK RIDE
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _bookRide() async {
    if (_routePoints.isEmpty) await _fetchRoute();
    setState(() => _loading = true);
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      final response = await dio.post('/rides', data: {
        'pickup_location': _pickup.text,
        'destination': _destination.text,
        'driver_id': _selectedDriverId,
        'driver': _selectedDriver,
        'fare': _routeDistKm != null
            ? (15.0 + _routeDistKm! * 8.0).toStringAsFixed(2)
            : '0',
        'distance_km': _routeDistKm?.toStringAsFixed(2) ?? '0',
        'pickup_lat': _pickupLatLng?.latitude,
        'pickup_lng': _pickupLatLng?.longitude,
        'dropoff_lat': _destLatLng?.latitude,
        'dropoff_lng': _destLatLng?.longitude,
      });

      final rideData = response.data;
      setState(() {
        _activeBooking =
            rideData is Map ? Map<String, dynamic>.from(rideData) : null;
        _activeBookingStatus = 'pending';
      });

      _pickup.clear();
      _destination.clear();
      setState(() {
        _fare = null;
        _selectedDriver = null;
        _selectedDriverId = null;
        _routePoints = [];
        _pickupLatLng = null;
        _destLatLng = null;
        _routeDistKm = null;
        _routeDurationMin = null;
      });

      await _loadRides();
      if (mounted) {
        _showSnack('Ride booked! Waiting for driver to accept…', _accent);
        setState(() => _tab = 1);
        _startRideStatusPolling();
      }
    } catch (_) {
      if (mounted)
        _showSnack('Booking failed. Please try again.', Colors.redAccent);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  RIDE STATUS POLLING
  // ════════════════════════════════════════════════════════════════════════

  void _startRideStatusPolling() {
    _rideStatusTimer?.cancel();
    _rideStatusTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollRideStatus());
  }

  Future<void> _pollRideStatus() async {
    if (_activeBooking == null) {
      _rideStatusTimer?.cancel();
      return;
    }
    try {
      final rideId = _activeBooking!['id'];
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/rides/$rideId/status');
      final data = res.data as Map<String, dynamic>;

      final newStatus = data['status']?.toString() ?? 'pending';
      final prevStatus = _activeBookingStatus;

      if (mounted) {
        setState(() {
          _activeBookingStatus = newStatus;
          _activeBooking = {
            ..._activeBooking!,
            ...data,
          };
          if (data['driver_lat'] != null && data['driver_lng'] != null) {
            _driverLiveLocation = LatLng(
              (data['driver_lat'] as num).toDouble(),
              (data['driver_lng'] as num).toDouble(),
            );
          }
        });

        if (prevStatus != newStatus) {
          if (newStatus == 'accepted' || newStatus == 'ongoing') {
            _showSnack('🛺 Driver accepted your ride! On the way…', _green);
            if (_myLocation != null && _driverLiveLocation != null) {
              final bounds =
                  LatLngBounds.fromPoints([_myLocation!, _driverLiveLocation!]);
              _mapController.fitCamera(CameraFit.bounds(
                  bounds: bounds, padding: const EdgeInsets.all(60)));
            }
          } else if (newStatus == 'completed') {
            _showSnack('✅ Ride completed! Thank you for riding with PasadaNow.',
                _green);
            _rideStatusTimer?.cancel();
            await _loadRides();
            setState(() {
              _activeBooking = null;
              _activeBookingStatus = null;
              _driverLiveLocation = null;
            });
          } else if (newStatus == 'cancelled') {
            _showSnack('❌ Ride was cancelled.', _red);
            _rideStatusTimer?.cancel();
            setState(() {
              _activeBooking = null;
              _activeBookingStatus = null;
              _driverLiveLocation = null;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _cancelActiveRide() async {
    if (_activeBooking == null) return;
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      await dio.patch('/rides/${_activeBooking!['id']}/cancel');
    } catch (_) {}
    _rideStatusTimer?.cancel();
    setState(() {
      _activeBooking = null;
      _activeBookingStatus = null;
      _driverLiveLocation = null;
    });
    _showSnack('Ride cancelled.', _orange);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: _navy,
      appBar: _buildAppBar(auth),
      bottomNavigationBar: _buildBottomNav(),
      body: switch (_tab) {
        0 => _buildDashboard(auth),
        1 => _buildHistoryTab(),
        2 => _buildProfileTab(auth),
        _ => _buildDashboard(auth),
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  APP BAR
  // ════════════════════════════════════════════════════════════════════════

  AppBar _buildAppBar(AuthProvider auth) => AppBar(
        backgroundColor: _navyLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(children: [
          _logoBadge(),
          const SizedBox(width: 8),
          const Text('PasadaNow',
              style: TextStyle(
                  color: _textPrim,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _o(_accent, 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _o(_accent, 0.3)),
            ),
            child: const Text('Commuter Portal',
                style: TextStyle(
                    color: _accent, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ]),
        actions: [
          // FIX: tap to re-run _initGPS (matches driver tap-to-reinit)
          GestureDetector(
            onTap: _initGPS,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _o(_isTracking ? _green : _orange, 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _o(_isTracking ? _green : _orange, 0.4)),
                ),
                child: Row(children: [
                  _isTracking
                      ? _PulseDot(color: _green)
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: _orange, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isTracking ? 'LIVE' : 'GPS OFF',
                          style: TextStyle(
                              color: _isTracking ? _green : _orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                      if (_isTracking && _gpsAccuracy != null)
                        Text('±${_gpsAccuracy!.toStringAsFixed(0)}m',
                            style: TextStyle(
                                color: _gpsAccuracyColor, fontSize: 7)),
                    ],
                  ),
                ]),
              ),
            ),
          ),
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.notifications_outlined, color: _textSub),
              Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _accent, shape: BoxShape.circle),
                  )),
            ]),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _avatarWidget(auth.username ?? 'C'),
          ),
        ],
      );

  Widget _logoBadge() => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _o(_accent, 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _o(_accent, 0.3)),
        ),
        child: const Center(child: Text('🛺', style: TextStyle(fontSize: 16))),
      );

  Widget _avatarWidget(String name) => CircleAvatar(
        radius: 15,
        backgroundColor: _o(_accent, 0.2),
        child: Text(name[0].toUpperCase(),
            style: const TextStyle(
                color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() => Container(
        decoration: const BoxDecoration(
          color: _navyLight,
          border: Border(top: BorderSide(color: _cardBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) {
            setState(() => _tab = i);
            if (i == 1) _loadRides();
            // FIX: immediate driver refresh when switching to Overview
            if (i == 0) _loadNearbyDrivers();
            if (i == 2) _loadCommuterProfile();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _accent,
          unselectedItemColor: _textSub,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
                icon: const Text('🗺️', style: TextStyle(fontSize: 22)),
                label: 'Overview'),
            BottomNavigationBarItem(
                icon: Stack(children: [
                  const Text('🧾', style: TextStyle(fontSize: 22)),
                  if (_activeBooking != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle),
                      ),
                    ),
                ]),
                label: 'Trip Records'),
            const BottomNavigationBarItem(
                icon: Text('👤', style: TextStyle(fontSize: 22)),
                label: 'My Profile'),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 0 — DASHBOARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDashboard(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_activeBooking != null) _buildActiveRideBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            _avatarWidget(auth.username ?? 'C'),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi, ${auth.username ?? 'Commuter'}',
                  style: const TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(
                  _driversLoading
                      ? 'Checking drivers…'
                      : _nearbyDrivers.isEmpty
                          ? 'No drivers online'
                          : '${_nearbyDrivers.length} driver${_nearbyDrivers.length == 1 ? '' : 's'} online nearby',
                  style: const TextStyle(color: _textSub, fontSize: 11),
                ),
              ]),
            ]),
            const Spacer(),
            if (_isTracking) _gpsInfoBadge(),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _statCard(
                '🧾', 'TOTAL\nBOOKINGS', _totalBookings.toString(), _accent),
            const SizedBox(width: 8),
            _statCard(
                '🛺', 'ONLINE\nDRIVERS', _onlineDrivers.toString(), _green),
            const SizedBox(width: 8),
            _statCard('💸', 'LAST\nFARE', _lastFare, _orange),
            const SizedBox(width: 8),
            _statCard('👛', 'TOTAL\nSPENT', _totalSpent, _purple),
          ]),
        ),
        _mapSection(),
        if (_routeDistKm != null) _fareMetricsPanel(),
        if (_activeBooking == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _bookingCard(),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _activeRideDetailCard(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: _nearestDriversCard(),
        ),
      ]),
    );
  }

  // ── GPS info badge (header) ───────────────────────────────────────────
  Widget _gpsInfoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          _PulseDot(color: _green),
          const SizedBox(width: 4),
          const Text('GPS LIVE',
              style: TextStyle(
                  color: _green, fontSize: 8, fontWeight: FontWeight.w700)),
        ]),
        Text(_gpsSpeedLabel,
            style: const TextStyle(
                color: _textPrim, fontSize: 11, fontWeight: FontWeight.w700)),
        Text(_gpsAccuracyLabel,
            style: TextStyle(color: _gpsAccuracyColor, fontSize: 8)),
      ]),
    );
  }

  // ── Active ride top banner ────────────────────────────────────────────
  Widget _buildActiveRideBanner() {
    final status = _activeBookingStatus ?? 'pending';
    Color statusColor;
    String statusText;
    String statusEmoji;

    switch (status) {
      case 'accepted':
      case 'ongoing':
        statusColor = _green;
        statusText = 'Driver on the way!';
        statusEmoji = '🛺';
        break;
      case 'completed':
        statusColor = _accent;
        statusText = 'Ride completed';
        statusEmoji = '✅';
        break;
      default:
        statusColor = _orange;
        statusText = 'Waiting for driver…';
        statusEmoji = '⏳';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _o(statusColor, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _o(statusColor, 0.4)),
      ),
      child: Row(children: [
        Text(statusEmoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            if (_activeBooking?['driver'] != null)
              Text('Driver: ${_activeBooking!['driver']}',
                  style: const TextStyle(color: _textSub, fontSize: 11)),
          ]),
        ),
        if (status == 'pending')
          GestureDetector(
            onTap: _cancelActiveRide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _o(_red, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _o(_red, 0.3)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: _red, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        if (status == 'accepted' || status == 'ongoing')
          _PulseDot(color: _green),
      ]),
    );
  }

  // ── Active ride detail card ───────────────────────────────────────────
  Widget _activeRideDetailCard() {
    final b = _activeBooking!;
    final status = _activeBookingStatus ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _o(_green, 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PulseDot(color: _green),
          const SizedBox(width: 8),
          const Text('Active Ride',
              style: TextStyle(
                  color: _textPrim, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        _detailRow('📍', 'From', b['pickup_location']?.toString() ?? '—'),
        const SizedBox(height: 8),
        _detailRow('🚩', 'To', b['destination']?.toString() ?? '—'),
        const SizedBox(height: 8),
        _detailRow('💳', 'Fare', '₱${b['fare'] ?? '—'}'),
        if (b['driver'] != null) ...[
          const SizedBox(height: 8),
          _detailRow('🛺', 'Driver', b['driver'].toString()),
        ],
        const SizedBox(height: 14),
        _rideStatusProgress(status),
        if (status == 'pending') ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelActiveRide,
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              icon: const Text('❌', style: TextStyle(fontSize: 14)),
              label: const Text('Cancel Ride',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _detailRow(String emoji, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: _textSub, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: _textPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ],
      );

  Widget _rideStatusProgress(String status) {
    final steps = ['pending', 'accepted', 'ongoing', 'completed'];
    final idx = steps.indexOf(status).clamp(0, steps.length - 1);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = i ~/ 2 < idx;
          return Expanded(
              child:
                  Container(height: 2, color: filled ? _green : _cardBorder));
        }
        final stepIdx = i ~/ 2;
        final done = stepIdx <= idx;
        final labels = ['Booked', 'Accepted', 'On Way', 'Done'];
        return Column(children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _green : _cardBorder,
              border: Border.all(
                  color: done ? _green : _o(_textSub, 0.3), width: 2),
            ),
          ),
          const SizedBox(height: 4),
          Text(labels[stepIdx],
              style: TextStyle(
                  color: done ? _green : _textSub,
                  fontSize: 8,
                  fontWeight: done ? FontWeight.w700 : FontWeight.normal)),
        ]);
      }),
    );
  }

  Widget _statCard(String emoji, String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: _textPrim,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: _textSub,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
              maxLines: 2),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  MAP SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _mapSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _myLocation ?? const LatLng(14.5995, 120.9842),
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pasadanow.app',
                  maxNativeZoom: 19,
                  maxZoom: 20,
                ),

                // GPS accuracy circle — same as driver
                if (_myLocation != null && _gpsAccuracy != null && _isTracking)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _myLocation!,
                      radius: _gpsAccuracy!,
                      useRadiusInMeter: true,
                      color: _o(_green, 0.07),
                      borderColor: _o(_green, 0.2),
                      borderStrokeWidth: 1.0,
                    ),
                  ]),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer<Object>(polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 7.0,
                      color: _o(Colors.black, 0.25),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: _routeColor,
                    ),
                  ]),

                MarkerLayer(markers: [
                  // Commuter live marker
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 140,
                      height: 64,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _isTracking
                                ? _PulseDot(color: _green)
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        color: _orange,
                                        shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              _isTracking ? 'You • $_gpsSpeedLabel' : 'You',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87),
                            ),
                          ]),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _isTracking ? _green : _orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4)
                            ],
                          ),
                        ),
                      ]),
                    ),

                  // Driver live location during active ride
                  if (_driverLiveLocation != null)
                    Marker(
                      point: _driverLiveLocation!,
                      width: 120,
                      height: 64,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4)
                            ],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _PulseDot(color: Colors.white),
                            const SizedBox(width: 4),
                            const Text('Driver',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                        const Text('🛺', style: TextStyle(fontSize: 22)),
                      ]),
                    ),

                  // Pickup marker
                  if (_pickupLatLng != null)
                    Marker(
                      point: _pickupLatLng!,
                      width: 110,
                      height: 56,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('A · Pickup',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        const Icon(Icons.location_on, color: _green, size: 22),
                      ]),
                    ),

                  // Destination marker
                  if (_destLatLng != null)
                    Marker(
                      point: _destLatLng!,
                      width: 120,
                      height: 56,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('B · Destination',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        const Icon(Icons.flag, color: _orange, size: 22),
                      ]),
                    ),
                ]),
              ],
            ),

            // Map controls
            Positioned(
              left: 10,
              top: 10,
              child: Column(children: [
                _mapBtn(
                    '+',
                    () => _mapController.move(_mapController.camera.center,
                        _mapController.camera.zoom + 1)),
                const SizedBox(height: 4),
                _mapBtn(
                    '−',
                    () => _mapController.move(_mapController.camera.center,
                        _mapController.camera.zoom - 1)),
                const SizedBox(height: 4),
                _mapBtn('◎', () {
                  if (_myLocation != null) {
                    _mapController.move(_myLocation!, 16);
                  } else {
                    _initGPS();
                  }
                }),
                if (_driverLiveLocation != null && _myLocation != null) ...[
                  const SizedBox(height: 4),
                  _mapBtn('⛶', () {
                    final bounds = LatLngBounds.fromPoints(
                        [_myLocation!, _driverLiveLocation!]);
                    _mapController.fitCamera(CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(60)));
                  }),
                ] else if (_routePoints.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _mapBtn('⛶', () {
                    final bounds = LatLngBounds.fromPoints(_routePoints);
                    _mapController.fitCamera(CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(50)));
                  }),
                ],
              ]),
            ),

            // GPS telemetry overlay (top right) — mirrors driver layout
            if (_isTracking && _gpsAccuracy != null)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _o(_navyLight, 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _PulseDot(color: _green),
                        const SizedBox(width: 5),
                        const Text('GPS LIVE',
                            style: TextStyle(
                                color: _green,
                                fontSize: 8,
                                fontWeight: FontWeight.w700)),
                      ]),
                      Text(
                          '±${_gpsAccuracy!.toStringAsFixed(0)}m · $_gpsAccuracyLabel',
                          style:
                              TextStyle(color: _gpsAccuracyColor, fontSize: 8)),
                      Text(_gpsSpeedLabel,
                          style: const TextStyle(
                              color: _textPrim,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),

            // GPS off banner
            if (!_isTracking)
              Positioned(
                bottom: 30,
                left: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _initGPS,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _o(_orange, 0.93),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6)
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📍', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text('GPS is off — tap to enable',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),

            if (_routeLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                    SizedBox(height: 8),
                    Text('Calculating route…',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ]),
                ),
              ),

            Positioned(
              right: 6,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _o(Colors.white, 0.75),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('© OpenStreetMap',
                    style: TextStyle(fontSize: 8, color: Colors.black54)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mapBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _o(_navyLight, 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _cardBorder),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: _textPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );

  // ── Fare metrics panel ────────────────────────────────────────────────
  Widget _fareMetricsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _o(_accent, 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _accent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('Route & Fare Details',
                style: TextStyle(
                    color: _textPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _metricChip('📏', '${_routeDistKm!.toStringAsFixed(2)} km',
                'Distance', _accent),
            const SizedBox(width: 8),
            _metricChip('⏱️', '${_routeDurationMin!.toStringAsFixed(0)} min',
                'Est. Time', _purple),
            const SizedBox(width: 8),
            _metricChip('💳', _computedFare, 'Fare', _green),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _o(_green, 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _o(_green, 0.2)),
            ),
            child: Column(children: [
              _fareBreakdownRow('Flag-down rate', '₱15.00'),
              _fareBreakdownRow(
                  'Distance (${_routeDistKm!.toStringAsFixed(2)} km × ₱8.00)',
                  '₱${(_routeDistKm! * 8.0).toStringAsFixed(2)}'),
              const Divider(color: Colors.white12, height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL FARE',
                    style: TextStyle(
                        color: _textPrim,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                Text(_computedFare,
                    style: const TextStyle(
                        color: _green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _metricChip(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: _o(color, 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _o(color, 0.25)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: _textSub, fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _fareBreakdownRow(String label, String amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _textSub, fontSize: 11)),
          Text(amount,
              style: const TextStyle(
                  color: _textPrim, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── Booking card ──────────────────────────────────────────────────────
  Widget _bookingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: _accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('Book a Ride',
              style: TextStyle(
                  color: _textPrim, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_routeLoading)
            const Row(children: [
              SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      color: _accent, strokeWidth: 2)),
              SizedBox(width: 6),
              Text('Finding route…',
                  style: TextStyle(color: _accent, fontSize: 10)),
            ])
          else if (_routeDistKm != null)
            Row(children: [
              const Text('✅', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('${_routeDistKm!.toStringAsFixed(1)} km · $_computedFare',
                  style: const TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ]),
        ]),

        // Use live GPS as pickup
        if (_isTracking && _myLocation != null && _pickup.text.isEmpty)
          GestureDetector(
            onTap: () {
              setState(() {
                _pickup.text = 'My current location';
                _pickupLatLng = _myLocation;
              });
              if (_destination.text.isNotEmpty) _fetchRoute();
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _o(_green, 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _o(_green, 0.25)),
              ),
              child: Row(children: [
                _PulseDot(color: _green),
                const SizedBox(width: 8),
                const Text('Use my live GPS location as pickup',
                    style: TextStyle(color: _green, fontSize: 11)),
                const Spacer(),
                const Text('Tap →',
                    style: TextStyle(color: _green, fontSize: 10)),
              ]),
            ),
          ),

        const SizedBox(height: 18),
        _fieldLabel('PICKUP POINT (A)'),
        const SizedBox(height: 6),
        _inputField(_pickup, 'Your pickup location...', '📍', _green),
        const SizedBox(height: 12),
        _fieldLabel('DESTINATION (B)'),
        const SizedBox(height: 6),
        _inputField(_destination, 'Enter destination...', '🚩', _orange),
        const SizedBox(height: 4),
        const Text('Route & fare auto-calculates as you type',
            style: TextStyle(
                color: _textSub, fontSize: 10, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        _fieldLabel('SELECT DRIVER (ONLINE ONLY)'),
        const SizedBox(height: 6),
        _driverDropdown(),
        if (_fare != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _o(_green, 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _o(_green, 0.25)),
            ),
            child: Row(children: [
              const Text('💳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Estimated fare: $_computedFare',
                  style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (_routeDistKm != null) ...[
                const Spacer(),
                Text('${_routeDistKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(color: _textSub, fontSize: 11)),
              ]
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _routeLoading ? null : _estimateFare,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              icon: _routeLoading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          color: _accent, strokeWidth: 2))
                  : const Text('🗺️', style: TextStyle(fontSize: 14)),
              label: const Text('Show Route', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _bookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _o(_accent, 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('🛺', style: TextStyle(fontSize: 14)),
              label: const Text('Book Ride →',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          color: _textSub,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8));

  Widget _inputField(TextEditingController ctrl, String hint, String emoji,
      Color accentColor) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: _textPrim, fontSize: 13),
      onSubmitted: (_) => _fetchRoute(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _o(_textSub, 0.6), fontSize: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: _navyLight,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _cardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentColor)),
      ),
    );
  }

  // FIX: driver dropdown — shows live count, auto-clears stale selection
  Widget _driverDropdown() {
    if (_driversLoading && _nearbyDrivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _navyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: const Row(children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Loading online drivers…',
              style: TextStyle(color: _textSub, fontSize: 12)),
        ]),
      );
    }

    if (_nearbyDrivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _navyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(children: [
          const Text('📴', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('No drivers online — check back soon',
                style: TextStyle(color: _textSub, fontSize: 12)),
          ),
          // FIX: manual refresh button so commuter can check immediately
          GestureDetector(
            onTap: _loadNearbyDrivers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _o(_accent, 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _o(_accent, 0.3)),
              ),
              child: const Text('🔄 Refresh',
                  style: TextStyle(color: _accent, fontSize: 10)),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _navyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDriverId,
          isExpanded: true,
          dropdownColor: _navyLight,
          style: const TextStyle(color: _textPrim, fontSize: 13),
          hint: Text(
            '— ${_nearbyDrivers.length} driver${_nearbyDrivers.length == 1 ? '' : 's'} online — choose one —',
            style: TextStyle(color: _o(_textSub, 0.7), fontSize: 12),
          ),
          items: _nearbyDrivers
              .map((d) => DropdownMenuItem<String>(
                    value: d['id'] as String,
                    child: Row(children: [
                      _driverAvatar(d['initials'] as String),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(d['name'] as String,
                                    style: const TextStyle(
                                        color: _textPrim, fontSize: 12)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _o(_green, 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('● Online',
                                      style: TextStyle(
                                          color: _green, fontSize: 8)),
                                ),
                              ]),
                              Text(d['plate'] as String,
                                  style: const TextStyle(
                                      color: _textSub, fontSize: 10)),
                            ]),
                      ),
                    ]),
                  ))
              .toList(),
          onChanged: (v) {
            final driver = _nearbyDrivers.firstWhere((d) => d['id'] == v,
                orElse: () => {});
            setState(() {
              _selectedDriverId = v;
              _selectedDriver = driver['name'] as String?;
            });
          },
        ),
      ),
    );
  }

  // ── Nearest drivers card ──────────────────────────────────────────────
  Widget _nearestDriversCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: _green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('Nearest Drivers',
              style: TextStyle(
                  color: _textPrim, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: _loadNearbyDrivers,
            child: const Text('🔄', style: TextStyle(fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 14),
        if (_driversLoading && _nearbyDrivers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child:
                    CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          )
        else if (_nearbyDrivers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(children: [
                Text('🛺', style: TextStyle(fontSize: 32)),
                SizedBox(height: 8),
                Text('No drivers online right now',
                    style: TextStyle(color: _textSub, fontSize: 13)),
              ]),
            ),
          )
        else
          ..._nearbyDrivers.map((d) => _driverRow(d)),
        const Divider(color: _cardBorder, height: 24),
        const Text('FLEET SUMMARY',
            style: TextStyle(
                color: _textSub,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _fleetRow('Online Drivers', _onlineDrivers.toString(), _textPrim),
        _fleetRow('Your Total Bookings', _totalBookings.toString(), _textPrim),
        _fleetRow('Last Fare Paid', _lastFare, _green),
        if (_isTracking && _gpsAccuracy != null) ...[
          const Divider(color: _cardBorder, height: 20),
          _fleetRow(
              'GPS Accuracy',
              '±${_gpsAccuracy!.toStringAsFixed(0)} m ($_gpsAccuracyLabel)',
              _gpsAccuracyColor),
          _fleetRow('Current Speed', _gpsSpeedLabel, _accent),
        ],
        if (_routeDistKm != null) ...[
          const Divider(color: _cardBorder, height: 20),
          _fleetRow('Route Distance', '${_routeDistKm!.toStringAsFixed(2)} km',
              _accent),
          _fleetRow('Est. Travel Time',
              '${_routeDurationMin!.toStringAsFixed(0)} min', _purple),
          _fleetRow('Computed Fare', _computedFare, _green),
        ],
      ]),
    );
  }

  Widget _driverRow(Map<String, dynamic> d) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          _driverAvatar(d['initials'] as String),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(d['name'] as String,
                    style: const TextStyle(
                        color: _textPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(d['plate'] as String,
                    style: const TextStyle(color: _textSub, fontSize: 11)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _o(_green, 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _o(_green, 0.3)),
            ),
            child: const Text('● Online',
                style: TextStyle(
                    color: _green, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _driverAvatar(String initials) => CircleAvatar(
        radius: 17,
        backgroundColor: _o(_accent, 0.15),
        child: Text(initials,
            style: const TextStyle(
                color: _accent, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _fleetRow(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TRIP RECORDS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        color: _navyLight,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Trip Records',
              style: TextStyle(
                  color: _textPrim, fontSize: 20, fontWeight: FontWeight.w800)),
          if (_activeBooking != null) ...[
            const SizedBox(height: 8),
            _buildActiveRideBanner(),
          ],
        ]),
      ),
      Expanded(
        child: _rides.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🧾', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 12),
                      const Text('No trips yet',
                          style: TextStyle(color: _textSub, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('Book your first ride from Overview',
                          style: TextStyle(color: _textSub, fontSize: 12)),
                    ]),
              )
            : RefreshIndicator(
                onRefresh: _loadRides,
                color: _accent,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rides.length,
                  itemBuilder: (_, i) {
                    final r = _rides[_rides.length - 1 - i];
                    return _historyCard(r);
                  },
                ),
              ),
      ),
    ]);
  }

  Widget _historyCard(dynamic r) {
    final status = r['status']?.toString() ?? 'pending';
    final isActive = status == 'accepted' || status == 'ongoing';
    final statusColor = isActive
        ? _green
        : status == 'completed'
            ? _accent
            : _textSub;
    final distKm = r['distance_km']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? _o(_green, 0.3) : _cardBorder),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _o(_accent, 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Center(child: Text('🛺', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r['pickup_location']} → ${r['destination']}',
              style: const TextStyle(
                  color: _textPrim, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Text('₱${r['fare']}',
                style: const TextStyle(
                    color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
            if (distKm != null && distKm != 'null') ...[
              const SizedBox(width: 6),
              Text('$distKm km',
                  style: const TextStyle(color: _textSub, fontSize: 10)),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _o(statusColor, 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              _PulseDot(color: _green),
            ],
          ]),
        ])),
        Text(r['created_at']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(color: _textSub, fontSize: 10)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 2 — PROFILE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
          color: _navyLight,
          child: Column(children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: _o(_accent, 0.2),
              child: Text((auth.username ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            Text(auth.username ?? 'Commuter',
                style: const TextStyle(
                    color: _textPrim,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _o(_accent, 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _o(_accent, 0.25)),
              ),
              child: const Text('Commuter',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _profileStatBox('Total Trips', _totalBookings.toString(), _accent),
            const SizedBox(width: 10),
            _profileStatBox('Total Spent', _totalSpent, _green),
            const SizedBox(width: 10),
            _profileStatBox('Last Fare', _lastFare, _orange),
          ]),
        ),

        // Live GPS card — same layout as driver profile
        if (_isTracking)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _o(_green, 0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _PulseDot(color: _green),
                      const SizedBox(width: 8),
                      const Text('Live GPS Status',
                          style: TextStyle(
                              color: _textPrim,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    _profileGpsRow(
                        '📡 Accuracy',
                        '±${_gpsAccuracy?.toStringAsFixed(0) ?? '—'} m ($_gpsAccuracyLabel)',
                        _gpsAccuracyColor),
                    _profileGpsRow('🚀 Speed', _gpsSpeedLabel, _accent),
                    if (_myLocation != null)
                      _profileGpsRow(
                          '📍 Position',
                          '${_myLocation!.latitude.toStringAsFixed(5)}, '
                              '${_myLocation!.longitude.toStringAsFixed(5)}',
                          _textSub),
                    _profileGpsRow(
                        '🔄 Push',
                        _activeBooking != null
                            ? 'Broadcasting'
                            : 'On ride only',
                        _green),
                  ]),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            _profileItem('👤', 'Username', auth.username ?? '—'),
            _profileItem('🏷️', 'Role', 'Commuter'),
            _profileItem('📞', 'Contact', _profileContact),
            _profileItem('📍', 'Location', _profileLocation),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Text('🚪', style: TextStyle(fontSize: 16)),
              label: const Text('Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _profileGpsRow(String label, String value, Color valueColor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _profileStatBox(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: _textSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _profileItem(String emoji, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(color: _textSub, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _textPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PULSING DOT  (same animation contract as driver)
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _anim.value),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 6 * _anim.value,
                  spreadRadius: 1.5 * _anim.value),
            ],
          ),
        ),
      );
}
