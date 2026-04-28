import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class RideRequest {
  final int id;
  final String passengerName;
  final LatLng pickup;
  final LatLng dropoff;
  final String pickupLabel;
  final String dropoffLabel;
  final double fare;
  final double distanceKm;

  const RideRequest({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.fare,
    required this.distanceKm,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    final pickupLat =
        (json['pickup_lat'] ?? json['pickup_latitude'] ?? 0.0) as num;
    final pickupLng =
        (json['pickup_lng'] ?? json['pickup_longitude'] ?? 0.0) as num;
    final dropoffLat =
        (json['dropoff_lat'] ?? json['dropoff_latitude'] ?? 0.0) as num;
    final dropoffLng =
        (json['dropoff_lng'] ?? json['dropoff_longitude'] ?? 0.0) as num;

    return RideRequest(
      id: (json['id'] as num).toInt(),
      passengerName: json['passenger_name']?.toString() ??
          json['commuter_name']?.toString() ??
          'Passenger',
      pickup: LatLng(pickupLat.toDouble(), pickupLng.toDouble()),
      dropoff: LatLng(dropoffLat.toDouble(), dropoffLng.toDouble()),
      pickupLabel: json['pickup_location']?.toString() ??
          json['pickup_label']?.toString() ??
          '',
      dropoffLabel: json['destination']?.toString() ??
          json['dropoff_label']?.toString() ??
          '',
      fare: (json['fare'] as num? ?? 0).toDouble(),
      distanceKm: (json['distance_km'] as num? ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isOnline = false;
  List _earnings = [];
  Map? _summary;
  bool _loading = false;
  int _tab = 0;

  // ── Map / Location ─────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  LatLng _driverLocation = const LatLng(14.5995, 120.9842);
  List<LatLng> _routePoints = [];
  RideRequest? _activeRide;
  RideRequest? _pendingRequest;
  bool _routeLoading = false;
  StreamSubscription<Position>? _locationSub;

  // GPS telemetry
  double? _gpsAccuracy;
  double? _gpsSpeed;
  double? _gpsHeading;

  // Commuter live location (received from backend during active ride)
  LatLng? _commuterLiveLocation;

  // ── Driver / Vehicle info ──────────────────────────────────────────────────
  Map<String, String> _vehicleInfo = {};
  final Map<String, String> _vehicleInfoEmojis = {
    'Plate Number': '🪪',
    'License No.': '📋',
    'Organization': '🏢',
    'Contact': '📞',
  };

  // ── Ride polling ───────────────────────────────────────────────────────────
  Timer? _ridePollingTimer;
  Timer? _locationPushTimer;

  // ── Fade animation ─────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color _bgDeep = Color(0xFF0B1B35);
  static const Color _bgCard = Color(0xFF102245);
  static const Color _accent = Color(0xFF3D7FD4);
  static const Color _green = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFE8863A);
  static const Color _red = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFE8EEF7);
  static const Color _textMuted = Color(0xFF8A9BC0);
  static const Color _border = Color(0xFF1E3A6E);

  static Color _o(Color c, double alpha) => c.withValues(alpha: alpha);

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadEarnings();
    _loadDriverProfile();
    _initGPS();
  }

  @override
  void dispose() {
    _animController.dispose();
    _locationSub?.cancel();
    _ridePollingTimer?.cancel();
    _locationPushTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initGPS() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _driverLocation = LatLng(pos.latitude, pos.longitude);
          _gpsAccuracy = pos.accuracy;
          _gpsSpeed = pos.speed;
          _gpsHeading = pos.heading;
        });
        _mapController.move(_driverLocation, 15);
      }
    } catch (_) {}

    _locationSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'PasadaNow Driver — GPS active',
          notificationTitle: 'Location Active',
          enableWakeLock: true,
        ),
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
        _gpsAccuracy = pos.accuracy;
        _gpsSpeed = pos.speed;
        _gpsHeading = pos.heading;
      });
      if (_activeRide == null) {
        _mapController.move(_driverLocation, _mapController.camera.zoom);
      }
    }, onError: (_) {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONLINE TOGGLE — FIX: calls PHP (drivers table lives there, not Django)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _toggleOnline() async {
    final next = !_isOnline;
    setState(() => _isOnline = next);

    if (next) {
      _startRidePolling();
      _startLocationPush();
    } else {
      _ridePollingTimer?.cancel();
      _locationPushTimer?.cancel();
      setState(() {
        _activeRide = null;
        _pendingRequest = null;
        _routePoints = [];
        _commuterLiveLocation = null;
      });
    }

    try {
      // FIX: phpBase — drivers table is in PHP's PostgreSQL, not Django
      final dio = ApiClient.build(ApiConstants.phpBase);
      await dio.patch('/drivers/me/status', data: {
        'is_online': next,
        'lat': _driverLocation.latitude,
        'lng': _driverLocation.longitude,
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUSH DRIVER LOCATION — FIX: live GPS → PHP, ride tracking → Django
  // ─────────────────────────────────────────────────────────────────────────

  void _startLocationPush() {
    _locationPushTimer?.cancel();
    _locationPushTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _pushLocation());
    _pushLocation();
  }

  Future<void> _pushLocation() async {
    if (!_isOnline) return;
    try {
      // Driver availability/location status → PHP
      final phpDio = ApiClient.build(ApiConstants.phpBase);
      await phpDio.patch('/drivers/me/location', data: {
        'lat': _driverLocation.latitude,
        'lng': _driverLocation.longitude,
      });

      // Ride-specific commuter tracking → Django
      if (_activeRide != null) {
        final djangoDio = ApiClient.build(ApiConstants.djangoBase);
        await djangoDio.post(
          '/api/drivers/rides/${_activeRide!.id}/driver-location',
          data: {
            'lat': _driverLocation.latitude,
            'lng': _driverLocation.longitude,
            'accuracy': _gpsAccuracy,
            'speed': _gpsSpeed,
            'heading': _gpsHeading,
          },
        );
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD DRIVER PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadDriverProfile() async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/api/drivers/me/profile');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _vehicleInfo = {
            'Plate Number': data['plate_number']?.toString() ?? '—',
            'License No.': data['license_number']?.toString() ?? '—',
            'Organization': data['organization']?.toString() ?? '—',
            'Contact': data['contact']?.toString() ?? '—',
          };
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OSRM ROUTING
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    setState(() => _routeLoading = true);
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = coords
              .map<LatLng>((c) =>
                  LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
        });
        if (_routePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitCamera(CameraFit.bounds(
              bounds: bounds, padding: const EdgeInsets.all(56)));
        }
      }
    } catch (_) {
      setState(() => _routePoints = [from, to]);
    } finally {
      setState(() => _routeLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIDE POLLING
  // ─────────────────────────────────────────────────────────────────────────

  void _startRidePolling() {
    _ridePollingTimer?.cancel();
    _ridePollingTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollPendingRide());
    _pollPendingRide();
  }

  Future<void> _pollPendingRide() async {
    if (!_isOnline || _activeRide != null || _pendingRequest != null) return;
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/api/drivers/rides/pending');
      final data = res.data;
      if (data != null && data is Map && data.isNotEmpty) {
        final req = RideRequest.fromJson(data as Map<String, dynamic>);
        if (mounted && _pendingRequest == null && _activeRide == null) {
          setState(() => _pendingRequest = req);
          _showRideRequestSheet(req);
        }
      }
    } catch (_) {}
  }

  void _startCommuterLocationPoll() {
    Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_activeRide == null) {
        t.cancel();
        return;
      }
      try {
        final dio = ApiClient.build(ApiConstants.djangoBase);
        final res = await dio
            .get('/api/drivers/rides/${_activeRide!.id}/commuter-location');
        final data = res.data as Map<String, dynamic>?;
        if (data != null &&
            data['lat'] != null &&
            data['lng'] != null &&
            mounted) {
          setState(() {
            _commuterLiveLocation = LatLng(
              (data['lat'] as num).toDouble(),
              (data['lng'] as num).toDouble(),
            );
          });
        }
      } catch (_) {}
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIDE ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _acceptRide(RideRequest req) async {
    Navigator.of(context).pop();
    setState(() {
      _activeRide = req;
      _pendingRequest = null;
    });

    await _fetchRoute(_driverLocation, req.pickup);
    _showSnack('✅ Ride accepted! Navigate to pickup point.', _green);
    _startCommuterLocationPoll();

    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/rides/${req.id}/accept', data: {
        'driver_lat': _driverLocation.latitude,
        'driver_lng': _driverLocation.longitude,
      });
    } catch (_) {}
  }

  Future<void> _completeRide() async {
    setState(() => _loading = true);
    final earned = _activeRide!.fare;
    final rideId = _activeRide!.id;

    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/rides/$rideId/complete', data: {
        'driver_lat': _driverLocation.latitude,
        'driver_lng': _driverLocation.longitude,
      });
      await _loadEarnings();
    } catch (_) {
    } finally {
      if (mounted) {
        _showSnack(
            '🎉 Ride completed! ₱${earned.toStringAsFixed(2)} earned.', _green);
        setState(() {
          _loading = false;
          _activeRide = null;
          _routePoints = [];
          _commuterLiveLocation = null;
        });
      }
    }
  }

  Future<void> _loadEarnings() async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final list = await dio.get('/api/earnings/list');
      final summary = await dio.get('/api/earnings/summary');
      if (mounted) {
        setState(() {
          _earnings = list.data;
          _summary = summary.data;
        });
      }
    } catch (_) {}
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showRideRequestSheet(RideRequest req) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _RideRequestSheet(
        req: req,
        onAccept: () => _acceptRide(req),
        onDecline: () {
          Navigator.of(context).pop();
          setState(() => _pendingRequest = null);
          _declineRideOnBackend(req.id);
        },
      ),
    );
  }

  Future<void> _declineRideOnBackend(int rideId) async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/rides/$rideId/decline');
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String get _gpsAccuracyLabel {
    if (_gpsAccuracy == null) return '—';
    if (_gpsAccuracy! < 5) return 'Excellent';
    if (_gpsAccuracy! < 15) return 'Good';
    if (_gpsAccuracy! < 40) return 'Fair';
    return 'Poor';
  }

  Color get _gpsAccuracyColor {
    if (_gpsAccuracy == null) return _textMuted;
    if (_gpsAccuracy! < 5) return _green;
    if (_gpsAccuracy! < 15) return _green;
    if (_gpsAccuracy! < 40) return _orange;
    return _red;
  }

  String get _gpsSpeedLabel {
    if (_gpsSpeed == null || _gpsSpeed! < 0.5) return '0 km/h';
    return '${(_gpsSpeed! * 3.6).toStringAsFixed(1)} km/h';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildAppBar(auth),
      bottomNavigationBar: _buildBottomNav(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _tab == 0
            ? _buildDashboardTab(auth)
            : _tab == 1
                ? _buildEarningsTab()
                : _buildProfileTab(auth),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AuthProvider auth) {
    return AppBar(
      backgroundColor: const Color(0xFF0D1A30),
      elevation: 0,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                LinearGradient(colors: [Color(0xFF2A5FC0), Color(0xFF1A3A80)]),
          ),
          child:
              const Center(child: Text('🛺', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            children: [
              TextSpan(text: 'Pasada', style: TextStyle(color: _textPrimary)),
              TextSpan(text: 'Now', style: TextStyle(color: _orange)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _border, borderRadius: BorderRadius.circular(4)),
          child: const Text('Driver Portal',
              style: TextStyle(
                  fontSize: 10,
                  color: _textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      actions: [
        GestureDetector(
          onTap: _initGPS,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _o(_gpsAccuracy != null ? _green : _orange, 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _o(_gpsAccuracy != null ? _green : _orange, 0.4)),
              ),
              child: Row(children: [
                _gpsAccuracy != null
                    ? _PulsingDot(color: _green)
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
                    Text(_gpsAccuracy != null ? 'LIVE' : 'GPS',
                        style: TextStyle(
                            color: _gpsAccuracy != null ? _green : _orange,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                    if (_gpsAccuracy != null)
                      Text('±${_gpsAccuracy!.toStringAsFixed(0)}m',
                          style:
                              TextStyle(color: _gpsAccuracyColor, fontSize: 7)),
                  ],
                ),
              ]),
            ),
          ),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Text('🔔', style: TextStyle(fontSize: 20)),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration:
                    const BoxDecoration(color: _accent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Text('🚪', style: TextStyle(fontSize: 20)),
          tooltip: 'Sign Out',
          onPressed: () async {
            if (_isOnline) await _toggleOnline();
            await auth.logout();
            if (context.mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM NAV
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A30),
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 1) _loadEarnings();
          if (i == 2) _loadDriverProfile();
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: _accent,
        unselectedItemColor: _textMuted,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
              icon: const Text('🗺️', style: TextStyle(fontSize: 22)),
              activeIcon: const Text('🗺️', style: TextStyle(fontSize: 22)),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: const Text('💰', style: TextStyle(fontSize: 22)),
              activeIcon: const Text('💰', style: TextStyle(fontSize: 22)),
              label: 'Earnings'),
          BottomNavigationBarItem(
              icon: const Text('👤', style: TextStyle(fontSize: 22)),
              activeIcon: const Text('👤', style: TextStyle(fontSize: 22)),
              label: 'My Profile'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDashboardTab(AuthProvider auth) {
    return Column(children: [
      Container(
        color: const Color(0xFF0D1A30),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          _buildGreeting(auth),
          const SizedBox(height: 10),
          _buildStatCards(),
          const SizedBox(height: 10),
          _buildStatusBanner(),
        ]),
      ),
      Expanded(child: _buildRealtimeMap()),
      if (_activeRide != null) _buildActiveRideBanner(),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REALTIME MAP
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRealtimeMap() {
    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _driverLocation,
          initialZoom: 15.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.pasadanow.driver',
            maxZoom: 19,
          ),
          if (_gpsAccuracy != null)
            CircleLayer(circles: [
              CircleMarker(
                point: _driverLocation,
                radius: _gpsAccuracy!,
                useRadiusInMeter: true,
                color: _o(_green, 0.07),
                borderColor: _o(_green, 0.2),
                borderStrokeWidth: 1.0,
              ),
            ]),
          if (_routePoints.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(
                points: _routePoints,
                color: _accent,
                strokeWidth: 5.0,
                borderColor: _o(_accent, 0.3),
                borderStrokeWidth: 10.0,
              ),
            ]),
          MarkerLayer(markers: [
            Marker(
              point: _driverLocation,
              width: 48,
              height: 48,
              child: _DriverMarker(isOnline: _isOnline),
            ),
            if (_commuterLiveLocation != null && _activeRide != null)
              Marker(
                point: _commuterLiveLocation!,
                width: 120,
                height: 56,
                alignment: Alignment.topCenter,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _PulsingDot(color: _accent),
                      const SizedBox(width: 4),
                      Text(
                        _activeRide!.passengerName.split(' ').first,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  const Text('👤', style: TextStyle(fontSize: 18)),
                ]),
              ),
            if (_activeRide != null)
              Marker(
                point: _activeRide!.pickup,
                width: 110,
                height: 56,
                alignment: Alignment.topCenter,
                child:
                    _RouteMarker(color: _green, emoji: '🟢', label: 'Pick up'),
              ),
            if (_activeRide != null)
              Marker(
                point: _activeRide!.dropoff,
                width: 120,
                height: 56,
                alignment: Alignment.topCenter,
                child:
                    _RouteMarker(color: _red, emoji: '📍', label: 'Drop off'),
              ),
          ]),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ]),
        ],
      ),
      if (_routeLoading)
        Container(
          color: Colors.black38,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _accent),
                ),
                SizedBox(width: 12),
                Text('Calculating route…',
                    style: TextStyle(color: _textPrimary, fontSize: 13)),
              ]),
            ),
          ),
        ),
      Positioned(
        top: 12,
        right: 12,
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
          _mapBtn('◎', () => _mapController.move(_driverLocation, 15)),
          if (_commuterLiveLocation != null) ...[
            const SizedBox(height: 4),
            _mapBtn('⛶', () {
              final bounds = LatLngBounds.fromPoints(
                  [_driverLocation, _commuterLiveLocation!]);
              _mapController.fitCamera(CameraFit.bounds(
                  bounds: bounds, padding: const EdgeInsets.all(60)));
            }),
          ],
        ]),
      ),
      if (_gpsAccuracy != null)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _o(const Color(0xFF0D1A30), 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _PulsingDot(color: _green),
                const SizedBox(width: 5),
                const Text('GPS LIVE',
                    style: TextStyle(
                        color: _green,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ]),
              Text('±${_gpsAccuracy!.toStringAsFixed(0)}m · $_gpsAccuracyLabel',
                  style: TextStyle(color: _gpsAccuracyColor, fontSize: 8)),
              Text(_gpsSpeedLabel,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      if (!_isOnline)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: _o(Colors.black, 0.45),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child:
                      const Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('📵', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text('Go online to start\naccepting rides',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _textMuted, fontSize: 13, height: 1.5)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      Positioned(
        right: 6,
        bottom: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text('© OpenStreetMap',
              style: TextStyle(fontSize: 8, color: Colors.black54)),
        ),
      ),
    ]);
  }

  Widget _mapBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: _o(Colors.black, 0.3), blurRadius: 6)],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE RIDE FOOTER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActiveRideBanner() {
    final ride = _activeRide!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A30),
        border: Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: _o(Colors.black, 0.4),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _statusBadge('🟢 Active Ride', _green),
          const Spacer(),
          _fareBadge(ride.fare),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _o(_accent, 0.2),
            child: Text(ride.passengerName[0],
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ride.passengerName,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  '${ride.distanceKm.toStringAsFixed(1)} km  ·  ₱${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
                if (_commuterLiveLocation != null) ...[
                  const SizedBox(width: 6),
                  _PulsingDot(color: _accent),
                  const SizedBox(width: 3),
                  const Text('Commuter live',
                      style: TextStyle(color: _accent, fontSize: 10)),
                ],
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        _routeLabel('🟢', _green, 'Pickup', ride.pickupLabel),
        const SizedBox(height: 4),
        _routeLabel('📍', _red, 'Dropoff', ride.dropoffLabel),
        const SizedBox(height: 12),
        Row(children: [
          if (_commuterLiveLocation != null)
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _o(_accent, 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _o(_accent, 0.3)),
                ),
                child: Column(children: [
                  const Text('Commuter',
                      style: TextStyle(color: _textMuted, fontSize: 9)),
                  _PulsingDot(color: _accent),
                  const Text('Tracking',
                      style: TextStyle(color: _accent, fontSize: 9)),
                ]),
              ),
            ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _loading ? null : _completeRide,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: _o(_green, 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('✅', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('Complete Ride',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _o(color, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _o(color, 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _fareBadge(double fare) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _o(_orange, 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _o(_orange, 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('💳', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text('₱${fare.toStringAsFixed(2)}',
            style: const TextStyle(
                color: _orange, fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }

  Widget _routeLabel(String emoji, Color color, String heading, String sub) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(color: _textPrimary, fontSize: 12)),
      ]),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGreeting(AuthProvider auth) {
    return Row(children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: _o(_accent, 0.2),
        child: Text((auth.username ?? 'D')[0].toUpperCase(),
            style: const TextStyle(
                color: _accent, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hi, ${auth.username ?? 'Driver'}',
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        Row(children: [
          Text(_isOnline ? '🟢' : '⚫', style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            _isOnline
                ? _activeRide != null
                    ? 'On a ride'
                    : 'Online — Accepting Rides'
                : 'Offline',
            style:
                TextStyle(color: _isOnline ? _green : _textMuted, fontSize: 11),
          ),
        ]),
      ]),
      const Spacer(),
      if (_gpsAccuracy != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _o(_green, 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _o(_green, 0.25)),
          ),
          child: Column(children: [
            Text(_gpsSpeedLabel,
                style: const TextStyle(
                    color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_gpsAccuracyLabel,
                style: TextStyle(color: _gpsAccuracyColor, fontSize: 8)),
          ]),
        ),
    ]);
  }

  Widget _buildStatCards() {
    final todayEarnings = _summary?['today'] ?? 0.0;
    final allTime = _summary?['all_time'] ?? 0.0;
    final trips = _summary?['total_trips'] ?? 0;

    return Row(children: [
      Expanded(
          child: _statCard(
              emoji: '💰',
              emojiColor: _green,
              emojiBg: _o(_green, 0.12),
              label: 'TOTAL',
              value: '₱${(allTime as num).toStringAsFixed(0)}')),
      const SizedBox(width: 8),
      Expanded(
          child: _statCard(
              emoji: '🛺',
              emojiColor: _accent,
              emojiBg: _o(_accent, 0.12),
              label: 'TRIPS',
              value: '$trips')),
      const SizedBox(width: 8),
      Expanded(
          child: _statCard(
              emoji: '📊',
              emojiColor: _orange,
              emojiBg: _o(_orange, 0.12),
              label: 'TODAY',
              value: '₱${(todayEarnings as num).toStringAsFixed(0)}')),
      const SizedBox(width: 8),
      Expanded(
          child: _statCard(
              emoji: _isOnline ? '📡' : '📴',
              emojiColor: _isOnline ? _green : _textMuted,
              emojiBg: _o(_isOnline ? _green : _textMuted, 0.12),
              label: 'STATUS',
              value: _isOnline ? 'ON' : 'OFF',
              valueColor: _isOnline ? _green : _textMuted)),
    ]);
  }

  Widget _statCard({
    required String emoji,
    required Color emojiColor,
    required Color emojiBg,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: emojiBg, borderRadius: BorderRadius.circular(7)),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: valueColor ?? _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: _textMuted, fontSize: 8, letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOnline ? _green : _textMuted,
            boxShadow: _isOnline
                ? [
                    BoxShadow(
                        color: _o(_green, 0.5), blurRadius: 8, spreadRadius: 2)
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isOnline
                ? _activeRide != null
                    ? 'On a ride — completing delivery'
                    : 'Online — Waiting for passenger requests…'
                : 'Go online to start accepting rides',
            style: const TextStyle(color: _textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _activeRide == null ? _toggleOnline : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _activeRide != null
                  ? _o(_textMuted, 0.2)
                  : _isOnline
                      ? _red
                      : _green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _activeRide == null
                  ? [
                      BoxShadow(
                          color: _o(_isOnline ? _red : _green, 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                _activeRide != null
                    ? '🛺'
                    : _isOnline
                        ? '📴'
                        : '📡',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 5),
              Text(
                _activeRide != null
                    ? 'On Ride'
                    : _isOnline
                        ? 'Go Offline'
                        : 'Go Online',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EARNINGS TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEarningsTab() {
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _bgCard,
      onRefresh: _loadEarnings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_summary != null) ...[
            Row(children: [
              Expanded(
                  child: _earningsStat('📅 Today',
                      '₱${(_summary!['today'] as num).toStringAsFixed(2)}')),
              const SizedBox(width: 12),
              Expanded(
                  child: _earningsStat('🏆 All-time',
                      '₱${(_summary!['all_time'] as num).toStringAsFixed(2)}')),
            ]),
            const SizedBox(height: 16),
          ],
          const Text('💸 Earnings & History',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_earnings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  const Text('🧾', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('No earnings yet.',
                      style: TextStyle(color: _textMuted, fontSize: 14)),
                ]),
              ),
            )
          else
            ..._earnings.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border, width: 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _o(_green, 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('💵', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₱${e['amount']}',
                                style: const TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text('Ride #${e['ride']} · ${e['date']}',
                                style: const TextStyle(
                                    color: _textMuted, fontSize: 12)),
                          ]),
                    ),
                    const Text('✅', style: TextStyle(fontSize: 16)),
                  ]),
                )),
        ],
      ),
    );
  }

  Widget _earningsStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: _green, fontSize: 22, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab(AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _o(_accent, 0.2),
              child: Text((auth.username ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 26)),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.username ?? 'Driver',
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _o(_green, 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _o(_green, 0.3), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isOnline ? '🟢' : '⚫',
                      style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 5),
                  Text(
                    _isOnline ? 'Online — Accepting Rides' : 'Offline',
                    style: TextStyle(
                        color: _isOnline ? _green : _textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (_gpsAccuracy != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _o(_green, 0.3), width: 1),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _PulsingDot(color: _green),
                const SizedBox(width: 8),
                const Text('Live GPS Status',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              _infoRow(
                '📡 Accuracy',
                '±${_gpsAccuracy!.toStringAsFixed(0)} m ($_gpsAccuracyLabel)',
                valueColor: _gpsAccuracyColor,
              ),
              _infoRow('🚀 Speed', _gpsSpeedLabel),
              _infoRow(
                '📍 Position',
                '${_driverLocation.latitude.toStringAsFixed(5)}, '
                    '${_driverLocation.longitude.toStringAsFixed(5)}',
              ),
              _infoRow(
                  '🔄 Push', _isOnline ? 'Broadcasting every 2s' : 'Offline'),
            ]),
          ),
        _vehicleInfo.isEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Center(
                  child: Text('Loading vehicle info…',
                      style: TextStyle(color: _textMuted, fontSize: 13)),
                ),
              )
            : _infoCard(
                dotColor: _orange,
                title: '🚗 Vehicle Info',
                child: Column(
                  children: _vehicleInfo.entries
                      .map((e) => _infoRow(
                            '${_vehicleInfoEmojis[e.key] ?? '📌'} ${e.key}',
                            e.value,
                          ))
                      .toList(),
                ),
              ),
        const SizedBox(height: 16),
        _infoCard(
          dotColor: _accent,
          title: '👤 Account Info',
          child: Column(children: [
            _infoRow('🙍 Username', auth.username ?? '—'),
            _infoRow('🏷️ Role', 'Driver'),
            _infoRow('📍 Organization', _vehicleInfo['Organization'] ?? '—'),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            if (_isOnline) await _toggleOnline();
            await auth.logout();
            if (context.mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _o(_red, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _o(_red, 0.3), width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🚪', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Sign Out',
                    style: TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required Color dotColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: dotColor)),
          const SizedBox(width: 7),
          Text(title,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIDE REQUEST BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _RideRequestSheet extends StatefulWidget {
  final RideRequest req;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RideRequestSheet({
    required this.req,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<_RideRequestSheet>
    with SingleTickerProviderStateMixin {
  static const Color _bgCard = Color(0xFF102245);
  static const Color _border = Color(0xFF1E3A6E);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFE8863A);
  static const Color _accent = Color(0xFF3D7FD4);
  static const Color _textPrimary = Color(0xFFE8EEF7);
  static const Color _textMuted = Color(0xFF8A9BC0);

  static Color _o(Color c, double a) => c.withValues(alpha: a);

  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1.5),
          boxShadow: [
            BoxShadow(color: _o(_green, 0.15), blurRadius: 30, spreadRadius: 4),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            _PulsingDot(color: _orange),
            const SizedBox(width: 10),
            const Text('🛺 New Ride Request!',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: _countdown / 30,
                  strokeWidth: 3,
                  backgroundColor: _border,
                  color: _countdown > 10 ? _green : _red,
                ),
                Text('$_countdown',
                    style: TextStyle(
                        color: _countdown > 10 ? _green : _red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _o(_accent, 0.2),
              child: Text(req.passengerName[0],
                  style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req.passengerName,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text('📏 ${req.distanceKm.toStringAsFixed(1)} km route',
                  style: const TextStyle(color: _textMuted, fontSize: 12)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _o(_green, 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _o(_green, 0.35)),
              ),
              child: Column(children: [
                Text('₱${req.fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const Text('💳 fare',
                    style: TextStyle(color: _textMuted, fontSize: 10)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(children: [
              _routeLine('🟢', _green, 'Pickup', req.pickupLabel),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: List.generate(
                      3,
                      (_) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            width: 1.5,
                            height: 5,
                            color: _border,
                          )),
                ),
              ),
              _routeLine('📍', _red, 'Dropoff', req.dropoffLabel),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onDecline,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _o(_red, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _o(_red, 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❌', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text('Decline',
                          style: TextStyle(
                              color: _red,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: widget.onAccept,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: _o(_green, 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✅', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text('Accept Ride',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _routeLine(String emoji, Color color, String label, String sub) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(color: _textPrimary, fontSize: 12)),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM MAP MARKERS
// ─────────────────────────────────────────────────────────────────────────────

class _DriverMarker extends StatefulWidget {
  final bool isOnline;
  const _DriverMarker({required this.isOnline});
  @override
  State<_DriverMarker> createState() => _DriverMarkerState();
}

class _DriverMarkerState extends State<_DriverMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const onlineColor = Color(0xFF22C55E);
    const offlineColor = Color(0xFF8A9BC0);
    final color = widget.isOnline ? onlineColor : offlineColor;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: widget.isOnline ? _pulse.value : 1.0,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Text('🛺', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  final Color color;
  final String emoji;
  final String label;

  const _RouteMarker({
    required this.color,
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 2),
      Text(emoji, style: const TextStyle(fontSize: 26)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING DOT
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 8 * _anim.value,
                spreadRadius: 2 * _anim.value),
          ],
        ),
      ),
    );
  }
}
