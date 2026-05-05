import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

class _IC {
  static const person = Icons.person_outline_rounded;
  static const badge = Icons.badge_outlined;
  static const role = Icons.verified_user_outlined;
  static const phone = Icons.phone_outlined;
  static const email = Icons.email_outlined;
  static const location = Icons.location_on_outlined;
  static const age = Icons.cake_outlined;
  static const tricycle = Icons.electric_rickshaw_outlined;
  static const pickup = Icons.my_location_outlined;
  static const destination = Icons.flag_outlined;
  static const route = Icons.route_outlined;
  static const fare = Icons.credit_card_outlined;
  static const distance = Icons.straighten_outlined;
  static const time = Icons.timer_outlined;
  static const gpsOn = Icons.gps_fixed;
  static const gpsOff = Icons.gps_off;
  static const speed = Icons.speed_outlined;
  static const accuracy = Icons.radar_outlined;
  static const dashboard = Icons.map_outlined;
  static const history = Icons.receipt_long_outlined;
  static const profile = Icons.account_circle_outlined;
  static const notification = Icons.notifications_outlined;
  static const refresh = Icons.refresh_rounded;
  static const cancel = Icons.cancel_outlined;
  static const signOut = Icons.logout_rounded;
  static const settings = Icons.settings_outlined;
  static const lock = Icons.lock_outline_rounded;
  static const search = Icons.search_rounded;
  static const book = Icons.rocket_launch_outlined;
  static const driver = Icons.drive_eta_outlined;
  static const online = Icons.circle;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const receipt = Icons.receipt_outlined;
  static const total = Icons.bar_chart_outlined;
  static const flag = Icons.flag_circle_outlined;
  static const warning = Icons.warning_amber_rounded;
  static const check = Icons.check_circle_outline_rounded;
  static const camera = Icons.camera_alt_rounded;
  static const edit = Icons.edit_outlined;
  static const save = Icons.save_outlined;
  static const chat = Icons.chat_bubble_outline_rounded;
  static const send = Icons.send_rounded;
  static const star = Icons.star_rounded;
  static const starOutline = Icons.star_outline_rounded;
  static const tripCount = Icons.directions_car_outlined;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class ChatWidget extends StatefulWidget {
  final String rideId;
  final String username;
  final String role;

  const ChatWidget({
    super.key,
    required this.rideId,
    required this.username,
    required this.role,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final dio = ApiClient.build(ApiConstants.springBase);
      final res = await dio.get('/api/chat/${widget.rideId}');
      final data = res.data as List;
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgController.clear();
    try {
      final dio = ApiClient.build(ApiConstants.springBase);
      await dio.post('/api/chat/${widget.rideId}', data: {
        'sender': widget.username,
        'role': widget.role,
        'content': text,
      });
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to send message.'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _o(_accent, 0.3)),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _o(_accent, 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            border: Border(bottom: BorderSide(color: _cardBorder)),
          ),
          child: Row(children: [
            Icon(_IC.chat, color: _accent, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Ride Chat',
              style: TextStyle(
                  color: _textPrim, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            _PulseDot(color: _green),
            const Spacer(),
            Text(
              '${_messages.length} msg${_messages.length == 1 ? '' : 's'}',
              style: const TextStyle(color: _textSub, fontSize: 10),
            ),
          ]),
        ),
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_IC.chat, color: _o(_textSub, 0.4), size: 28),
                    const SizedBox(height: 6),
                    const Text(
                      'No messages yet.\nSay hello to your rider!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: _textSub, fontSize: 11, height: 1.5),
                    ),
                  ]),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final isMine =
                        msg['sender']?.toString() == widget.username ||
                            msg['role']?.toString() == widget.role;
                    return _ChatBubble(
                      message: msg['content']?.toString() ??
                          msg['message']?.toString() ??
                          '',
                      sender: msg['sender']?.toString() ?? '',
                      isMine: isMine,
                      time: msg['timestamp']?.toString() ??
                          msg['created_at']?.toString() ??
                          '',
                    );
                  },
                ),
        ),
        // Input row
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _cardBorder)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _navyLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _cardBorder),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: _textPrim, fontSize: 13),
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle:
                        TextStyle(color: _o(_textSub, 0.6), fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _sending ? _o(_accent, 0.4) : _accent,
                  shape: BoxShape.circle,
                  boxShadow: _sending
                      ? null
                      : [
                          BoxShadow(
                              color: _o(_accent, 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                ),
                child: _sending
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : const Icon(_IC.send, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final String sender;
  final bool isMine;
  final String time;

  const _ChatBubble({
    required this.message,
    required this.sender,
    required this.isMine,
    required this.time,
  });

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  sender,
                  style: const TextStyle(
                      color: _textSub,
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isMine ? _accent : _navyLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _o(isMine ? _accent : Colors.black, 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMine ? Colors.white : _textPrim,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(
                  _formatTime(time),
                  style: const TextStyle(color: _textSub, fontSize: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUTER PROFILE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class CommuterProfile {
  final String username;
  final String fullName;
  final String age;
  final String phone;
  final String email;
  final String address;
  final String? profilePhotoUrl;

  const CommuterProfile({
    required this.username,
    required this.fullName,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    this.profilePhotoUrl,
  });

  factory CommuterProfile.fromJson(Map<String, dynamic> json) {
    return CommuterProfile(
      username: json['username']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['contact']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address:
          json['address']?.toString() ?? json['location']?.toString() ?? '',
      profilePhotoUrl:
          json['profile_photo']?.toString() ?? json['profilePhoto']?.toString(),
    );
  }

  CommuterProfile copyWith({
    String? fullName,
    String? age,
    String? phone,
    String? email,
    String? address,
    String? profilePhotoUrl,
  }) =>
      CommuterProfile(
        username: username,
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT FIELD helper
// ─────────────────────────────────────────────────────────────────────────────

class _EditField {
  final String label;
  final String key;
  final String initialValue;
  final TextInputType keyboardType;
  const _EditField(this.label, this.key, this.initialValue,
      {this.keyboardType = TextInputType.text});
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

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

  LatLng? _pickupLatLng;
  LatLng? _destLatLng;
  List<LatLng> _routePoints = [];
  double? _routeDistKm;
  double? _routeDurationMin;
  bool _routeLoading = false;

  LatLng? _myLocation;
  StreamSubscription<Position>? _locationStream;
  bool _isTracking = false;
  bool _gpsForced = false;
  Timer? _retryTimer;
  Timer? _debounce;

  double? _gpsAccuracy;
  double? _gpsSpeed;
  double? _gpsHeading;
  DateTime? _lastGpsUpdate;

  Timer? _rideStatusTimer;
  Map<String, dynamic>? _activeBooking;
  String? _activeBookingStatus;
  LatLng? _driverLiveLocation;

  bool _showCompletionCard = false;
  Map<String, dynamic>? _completedRideSnapshot;

  List<Map<String, dynamic>> _nearbyDrivers = [];
  bool _driversLoading = false;
  Timer? _driversRefreshTimer;

  CommuterProfile? _profile;
  bool _profileLoading = false;
  Timer? _profileRefreshTimer;

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

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ══════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGPS();
    _loadRides();
    _loadNearbyDrivers();
    _loadCommuterProfile();
    _pickup.addListener(_onFieldChanged);
    _destination.addListener(_onFieldChanged);
    _driversRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadNearbyDrivers());
    _profileRefreshTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _loadCommuterProfile());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStream?.cancel();
    _retryTimer?.cancel();
    _debounce?.cancel();
    _rideStatusTimer?.cancel();
    _driversRefreshTimer?.cancel();
    _profileRefreshTimer?.cancel();
    _pickup.removeListener(_onFieldChanged);
    _destination.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isTracking) _initGPS();
  }

  void _onFieldChanged() {
    if (_pickup.text.trim().length > 3 && _destination.text.trim().length > 3) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        if (mounted) _fetchRoute();
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  GPS
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _initGPS() async {
    await _locationStream?.cancel();
    _locationStream = null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDisabledDialog();
      _scheduleGpsRetry();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (permission == LocationPermission.deniedForever && mounted)
        _showPermissionPermanentlyDeniedDialog();
      _useFallback();
      return;
    }

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

    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
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
        if (_routePoints.isEmpty && _activeBooking == null)
          _mapController.move(updated, _mapController.camera.zoom);
        if (_activeBooking != null) _pushCommuterLocation(updated);
      },
      onError: (_) {
        if (mounted) setState(() => _isTracking = false);
        _scheduleGpsRetry();
      },
    );
    _retryTimer?.cancel();
  }

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

  // ══════════════════════════════════════════════════════════════════════
  //  GPS DIALOGS
  // ══════════════════════════════════════════════════════════════════════

  void _showGpsDisabledDialog() {
    if (!mounted || _gpsForced) return;
    setState(() => _gpsForced = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(_IC.gpsOff, color: _orange, size: 20),
          const SizedBox(width: 10),
          const Text('GPS is Off',
              style: TextStyle(color: _textPrim, fontSize: 16)),
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
            icon: Icon(_IC.settings, size: 14, color: Colors.white),
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
        title: Row(children: [
          Icon(_IC.warning, color: _red, size: 20),
          const SizedBox(width: 10),
          const Text('Permission Denied',
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
            icon: Icon(_IC.settings, size: 14, color: Colors.white),
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

  // ══════════════════════════════════════════════════════════════════════
  //  GEOCODING & ROUTING
  // ══════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════
  //  API CALLS
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _loadRides() async {
    try {
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/rides');
      if (mounted) setState(() => _rides = res.data);
    } catch (_) {}
  }

  Future<void> _loadNearbyDrivers() async {
    if (!mounted || _driversLoading) return;
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
    if (_profileLoading) return;
    setState(() => _profileLoading = true);
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/commuters/me/profile');
      final data = res.data as Map<String, dynamic>;
      if (mounted) setState(() => _profile = CommuterProfile.fromJson(data));
    } catch (_) {}
    if (mounted) setState(() => _profileLoading = false);
  }

  Future<bool> _updateProfile(Map<String, dynamic> updates) async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/commuters/me/profile', data: updates);
      await _loadCommuterProfile();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);
    final success = await _updateProfile({'profilePhoto': base64Str});
    if (mounted) {
      _showSnack(
        success ? 'Profile photo updated!' : 'Failed to update photo.',
        success ? _green : _red,
      );
    }
  }

  Future<void> _estimateFare() async => _fetchRoute();

  // ══════════════════════════════════════════════════════════════════════
  //  BOOK RIDE
  // ══════════════════════════════════════════════════════════════════════

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
        _showCompletionCard = false;
        _completedRideSnapshot = null;
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

  // ══════════════════════════════════════════════════════════════════════
  //  RIDE STATUS POLLING
  // ══════════════════════════════════════════════════════════════════════

  void _startRideStatusPolling() {
    _rideStatusTimer?.cancel();
    _rideStatusTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollRideStatus());
  }

  void _clearActiveRide() {
    _rideStatusTimer?.cancel();
    _rideStatusTimer = null;
    if (!mounted) return;
    setState(() {
      _activeBooking = null;
      _activeBookingStatus = null;
      _driverLiveLocation = null;
      _tab = 0;
    });
  }

  Future<void> _pollRideStatus() async {
    if (_activeBooking == null || _showCompletionCard) {
      _rideStatusTimer?.cancel();
      _rideStatusTimer = null;
      return;
    }

    try {
      final rideId = _activeBooking!['id'];
      final dio = ApiClient.build(ApiConstants.phpBase);
      final res = await dio.get('/rides/$rideId/status');
      final data = res.data as Map<String, dynamic>;
      final newStatus = data['status']?.toString() ?? 'pending';
      final prevStatus = _activeBookingStatus;

      if (!mounted) return;
      if (_activeBooking == null) return;

      setState(() {
        _activeBookingStatus = newStatus;
        _activeBooking = {..._activeBooking!, ...data};
        if (data['driver_lat'] != null && data['driver_lng'] != null) {
          _driverLiveLocation = LatLng(
            (data['driver_lat'] as num).toDouble(),
            (data['driver_lng'] as num).toDouble(),
          );
        }
      });

      if (prevStatus != newStatus) {
        if (newStatus == 'accepted' || newStatus == 'ongoing') {
          _showSnack('Driver accepted your ride! On the way…', _green);
          if (_myLocation != null && _driverLiveLocation != null) {
            final bounds =
                LatLngBounds.fromPoints([_myLocation!, _driverLiveLocation!]);
            _mapController.fitCamera(CameraFit.bounds(
                bounds: bounds, padding: const EdgeInsets.all(60)));
          }
        } else if (newStatus == 'completed') {
          _rideStatusTimer?.cancel();
          _rideStatusTimer = null;

          final snapshot = Map<String, dynamic>.from(_activeBooking!);

          setState(() {
            _activeBooking = null;
            _activeBookingStatus = null;
            _driverLiveLocation = null;
            _showCompletionCard = true;
            _completedRideSnapshot = snapshot;
            _tab = 0;
          });

          _loadRides();
          _showSnack(
              'Ride completed! Thank you for riding with PasadaNow.', _green);
          return;
        } else if (newStatus == 'cancelled') {
          _rideStatusTimer?.cancel();
          _rideStatusTimer = null;

          _showSnack('Ride was cancelled.', _red);

          Future.delayed(const Duration(milliseconds: 400), () {
            _clearActiveRide();
          });
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
    _showSnack('Ride cancelled.', _orange);
    _clearActiveRide();
  }

  // ── FIX: Dismiss completion card and fully reset to booking form ──
  void _dismissCompletionCard() {
    _rideStatusTimer?.cancel();
    _rideStatusTimer = null;
    setState(() {
      _showCompletionCard = false;      
      _completedRideSnapshot = null;
      _routePoints = [];
      _pickupLatLng = null;
      _destLatLng = null;
      _routeDistKm = null;
      _routeDurationMin = null;
      _fare = null;
      _selectedDriver = null;
      _selectedDriverId = null;
      _activeBookingStatus = null; 
      _activeBooking = null;
      _driverLiveLocation = null;
      _tab = 0;
    });
    _loadNearbyDrivers();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════
  //  APP BAR
  // ══════════════════════════════════════════════════════════════════════

  AppBar _buildAppBar(AuthProvider auth) {
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName.split(' ').first
        : auth.username ?? 'Commuter';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A1628),
              _navyLight,
              const Color(0xFF0D1F35),
            ],
          ),
          border: const Border(
            bottom: BorderSide(color: _cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _o(_accent, 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _o(_accent, 0.35), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(_IC.tricycle, color: _accent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'Pasada',
                      style: TextStyle(
                        color: _textPrim,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: 'Now',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _o(_accent, 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _o(_accent, 0.35)),
                  ),
                  child: const Text(
                    'COMMUTER',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Text(
                  '$_timeGreeting, ',
                  style: const TextStyle(
                    color: _textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: _textPrim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(' 👋', style: TextStyle(fontSize: 12)),
              ]),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _initGPS,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _o(_isTracking ? _green : _orange, 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _o(_isTracking ? _green : _orange, 0.45),
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                _isTracking
                    ? _PulseDot(color: _green)
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: _orange, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTracking ? 'LIVE' : 'GPS OFF',
                      style: TextStyle(
                        color: _isTracking ? _green : _orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (_isTracking && _gpsAccuracy != null)
                      Text(
                        '±${_gpsAccuracy!.toStringAsFixed(0)}m',
                        style: TextStyle(color: _gpsAccuracyColor, fontSize: 7),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(_IC.notification, color: _textSub, size: 22),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _navyLight, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => setState(() => _tab = 2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _o(_accent, 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _o(_accent, 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _buildAppBarAvatar(auth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAvatar(AuthProvider auth) {
    final photoUrl = _profile?.profilePhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isBase64 = !photoUrl.startsWith('http');
      return CircleAvatar(
        radius: 17,
        backgroundColor: _o(_accent, 0.2),
        backgroundImage: isBase64
            ? MemoryImage(base64Decode(photoUrl))
            : NetworkImage(photoUrl) as ImageProvider,
        onBackgroundImageError: (_, __) {},
      );
    }
    final initial = (auth.username ?? 'C')[0].toUpperCase();
    return CircleAvatar(
      radius: 17,
      backgroundColor: _o(_accent, 0.2),
      child: Text(initial,
          style: const TextStyle(
              color: _accent, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAvatarWidget(
      {required double radius, required double fontSize}) {
    final photoUrl = _profile?.profilePhotoUrl;
    final initial = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName[0].toUpperCase()
        : 'C';
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isBase64 = !photoUrl.startsWith('http');
      return CircleAvatar(
        radius: radius,
        backgroundColor: _o(_accent, 0.2),
        backgroundImage: isBase64
            ? MemoryImage(base64Decode(photoUrl))
            : NetworkImage(photoUrl) as ImageProvider,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _o(_accent, 0.2),
      child: Text(initial,
          style: TextStyle(
              color: _accent, fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ══════════════════════════════════════════════════════════════════════

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
                icon: Icon(_IC.dashboard), label: 'Overview'),
            BottomNavigationBarItem(
                icon: Stack(children: [
                  Icon(_IC.history),
                  if (_activeBooking != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: _green, shape: BoxShape.circle)),
                    ),
                ]),
                label: 'Trip Records'),
            BottomNavigationBarItem(
                icon: Icon(_IC.profile), label: 'My Profile'),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════
  //  TAB 0 — DASHBOARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDashboard(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_activeBooking != null && !_showCompletionCard)
          _buildActiveRideBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _nearbyDrivers.isEmpty ? _textSub : _green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _driversLoading
                  ? 'Checking drivers…'
                  : _nearbyDrivers.isEmpty
                      ? 'No drivers online right now'
                      : '${_nearbyDrivers.length} driver${_nearbyDrivers.length == 1 ? '' : 's'} online nearby',
              style: const TextStyle(color: _textSub, fontSize: 12),
            ),
            const Spacer(),
            if (_isTracking) _gpsInfoBadge(),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            _statCard(_IC.receipt, 'TOTAL\nBOOKINGS', _totalBookings.toString(),
                _accent),
            const SizedBox(width: 8),
            _statCard(_IC.tricycle, 'ONLINE\nDRIVERS',
                _onlineDrivers.toString(), _green),
            const SizedBox(width: 8),
            _statCard(_IC.fare, 'LAST\nFARE', _lastFare, _orange),
            const SizedBox(width: 8),
            _statCard(_IC.wallet, 'TOTAL\nSPENT', _totalSpent, _purple),
          ]),
        ),
        _mapSection(),
        if (_routeDistKm != null &&
            !_showCompletionCard &&
            _activeBooking == null)
          _fareMetricsPanel(),
        if (_showCompletionCard && _completedRideSnapshot != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _rideCompletionCard(_completedRideSnapshot!),
          )
        else if (_activeBooking != null && !_showCompletionCard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _activeRideDetailCard(auth),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _bookingCard(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: _nearestDriversCard(),
        ),
      ]),
    );
  }

  Widget _gpsInfoBadge() => Container(
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

  Widget _buildActiveRideBanner() {
    final status = _activeBookingStatus ?? 'pending';
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
      case 'ongoing':
        statusColor = _green;
        statusText = 'Driver on the way!';
        statusIcon = _IC.tricycle;
        break;
      case 'completed':
        statusColor = _accent;
        statusText = 'Ride completed';
        statusIcon = _IC.check;
        break;
      default:
        statusColor = _orange;
        statusText = 'Waiting for driver…';
        statusIcon = Icons.hourglass_top_rounded;
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
        Icon(statusIcon, color: statusColor, size: 22),
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_IC.cancel, color: _red, size: 14),
                const SizedBox(width: 4),
                const Text('Cancel',
                    style: TextStyle(
                        color: _red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        if (status == 'accepted' || status == 'ongoing')
          _PulseDot(color: _green),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  RIDE COMPLETION CARD  ← FIX IS HERE
  // ══════════════════════════════════════════════════════════════════════

  Widget _rideCompletionCard(Map<String, dynamic> ride) {
    final fareStr = '₱${ride['fare'] ?? '—'}';
    final from = ride['pickup_location']?.toString() ?? '—';
    final to = ride['destination']?.toString() ?? '—';
    final driver = ride['driver']?.toString();
    final distKm = ride['distance_km']?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _o(_green, 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _o(_green, 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _o(_green, 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _o(_green, 0.4), width: 1.5),
            ),
            child: const Icon(_IC.check, color: _green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Ride Completed!',
                style: TextStyle(
                  color: _green,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Thank you for riding with PasadaNow',
                style: TextStyle(color: _textSub, fontSize: 11),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        const Divider(color: _cardBorder, height: 1),
        const SizedBox(height: 16),
        _detailRow(_IC.pickup, 'From', from),
        const SizedBox(height: 10),
        _detailRow(_IC.destination, 'To', to),
        const SizedBox(height: 10),
        _detailRow(_IC.fare, 'Fare Paid', fareStr),
        if (driver != null && driver != 'null') ...[
          const SizedBox(height: 10),
          _detailRow(_IC.driver, 'Driver', driver),
        ],
        if (distKm != null && distKm != 'null') ...[
          const SizedBox(height: 10),
          _detailRow(_IC.distance, 'Distance', '$distKm km'),
        ],
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_o(_green, 0.18), _o(_green, 0.08)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _o(_green, 0.35)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_IC.wallet, color: _green, size: 18),
            const SizedBox(width: 10),
            Text(
              fareStr,
              style: const TextStyle(
                color: _green,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'total fare',
              style: TextStyle(color: _textSub, fontSize: 12),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── PRIMARY: Book Another Ride → resets everything, goes to booking form ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _dismissCompletionCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(_IC.book, size: 16),
            label: const Text(
              'Book Another Ride',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── SECONDARY: View Trip History ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _dismissCompletionCard();
              setState(() => _tab = 1);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _textSub,
              side: BorderSide(color: _o(_textSub, 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(_IC.history, size: 16),
            label: const Text(
              'View Trip History',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  ACTIVE RIDE DETAIL CARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _activeRideDetailCard(AuthProvider auth) {
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
        _detailRow(_IC.pickup, 'From', b['pickup_location']?.toString() ?? '—'),
        const SizedBox(height: 8),
        _detailRow(_IC.destination, 'To', b['destination']?.toString() ?? '—'),
        const SizedBox(height: 8),
        _detailRow(_IC.fare, 'Fare', '₱${b['fare'] ?? '—'}'),
        if (b['driver'] != null) ...[
          const SizedBox(height: 8),
          _detailRow(_IC.driver, 'Driver', b['driver'].toString()),
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
              icon: Icon(_IC.cancel, size: 16),
              label: const Text('Cancel Ride',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ChatWidget(
            rideId: _activeBooking!['id'].toString(),
            username: auth.username ?? 'commuter',
            role: 'commuter',
          ),
        ),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _textSub, size: 16),
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
    final labels = ['Booked', 'Accepted', 'On Way', 'Done'];
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

  Widget _statCard(IconData icon, String label, String value, Color accent) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: _textPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: _textSub,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600),
                maxLines: 2),
          ]),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════
  //  MAP SECTION
  // ══════════════════════════════════════════════════════════════════════

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
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pasadanow.app',
                  maxNativeZoom: 19,
                  maxZoom: 20,
                ),
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
                if (_routePoints.isNotEmpty)
                  PolylineLayer<Object>(polylines: [
                    Polyline(
                        points: _routePoints,
                        strokeWidth: 7.0,
                        color: _o(Colors.black, 0.25)),
                    Polyline(
                        points: _routePoints,
                        strokeWidth: 4.5,
                        color: _routeColor),
                  ]),
                MarkerLayer(markers: [
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
                        Icon(_IC.tricycle, color: _green, size: 22),
                      ]),
                    ),
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
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('A · Pickup',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        Icon(_IC.location, color: _green, size: 22),
                      ]),
                    ),
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
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('B · Destination',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        Icon(_IC.destination, color: _orange, size: 22),
                      ]),
                    ),
                ]),
              ],
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Column(children: [
                _mapBtn(
                    Icons.add,
                    () => _mapController.move(_mapController.camera.center,
                        _mapController.camera.zoom + 1)),
                const SizedBox(height: 4),
                _mapBtn(
                    Icons.remove,
                    () => _mapController.move(_mapController.camera.center,
                        _mapController.camera.zoom - 1)),
                const SizedBox(height: 4),
                _mapBtn(_IC.gpsOn, () {
                  if (_myLocation != null)
                    _mapController.move(_myLocation!, 16);
                  else
                    _initGPS();
                }),
                if (_driverLiveLocation != null && _myLocation != null) ...[
                  const SizedBox(height: 4),
                  _mapBtn(Icons.fit_screen_outlined, () {
                    final bounds = LatLngBounds.fromPoints(
                        [_myLocation!, _driverLiveLocation!]);
                    _mapController.fitCamera(CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(60)));
                  }),
                ] else if (_routePoints.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _mapBtn(Icons.fit_screen_outlined, () {
                    final bounds = LatLngBounds.fromPoints(_routePoints);
                    _mapController.fitCamera(CameraFit.bounds(
                        bounds: bounds, padding: const EdgeInsets.all(50)));
                  }),
                ],
              ]),
            ),
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
                            style: TextStyle(
                                color: _gpsAccuracyColor, fontSize: 8)),
                        Text(_gpsSpeedLabel,
                            style: const TextStyle(
                                color: _textPrim,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
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
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_IC.gpsOff, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          const Text('GPS is off — tap to enable',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ]),
                  ),
                ),
              ),
            if (_routeLoading)
              Container(
                color: Colors.black45,
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(
                      color: _accent, strokeWidth: 2.5),
                  const SizedBox(height: 8),
                  const Text('Calculating route…',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ])),
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

  Widget _mapBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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
          child: Center(child: Icon(icon, color: _textPrim, size: 16)),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════
  //  FARE METRICS PANEL
  // ══════════════════════════════════════════════════════════════════════

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
            _metricChip(_IC.distance, '${_routeDistKm!.toStringAsFixed(2)} km',
                'Distance', _accent),
            const SizedBox(width: 8),
            _metricChip(
                _IC.time,
                '${_routeDurationMin!.toStringAsFixed(0)} min',
                'Est. Time',
                _purple),
            const SizedBox(width: 8),
            _metricChip(_IC.fare, _computedFare, 'Fare', _green),
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

  Widget _metricChip(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: _o(color, 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _o(color, 0.25)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 16),
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

  // ══════════════════════════════════════════════════════════════════════
  //  BOOKING CARD
  // ══════════════════════════════════════════════════════════════════════

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
            Row(children: [
              const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      color: _accent, strokeWidth: 2)),
              const SizedBox(width: 6),
              const Text('Finding route…',
                  style: TextStyle(color: _accent, fontSize: 10)),
            ])
          else if (_routeDistKm != null)
            Row(children: [
              Icon(_IC.check, color: _green, size: 14),
              const SizedBox(width: 4),
              Text('${_routeDistKm!.toStringAsFixed(1)} km · $_computedFare',
                  style: const TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ]),
        ]),
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
                Icon(_IC.pickup, color: _green, size: 14),
              ]),
            ),
          ),
        const SizedBox(height: 18),
        _fieldLabel('PICKUP POINT (A)'),
        const SizedBox(height: 6),
        _inputField(_pickup, 'Your pickup location...', _IC.pickup, _green),
        const SizedBox(height: 12),
        _fieldLabel('DESTINATION (B)'),
        const SizedBox(height: 6),
        _inputField(
            _destination, 'Enter destination...', _IC.destination, _orange),
        const SizedBox(height: 4),
        const Text('Route & fare auto-calculates as you type',
            style: TextStyle(
                color: _textSub, fontSize: 10, fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        _driverSelectorSection(),
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
              Icon(_IC.fare, color: _green, size: 18),
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
                  : Icon(_IC.route, size: 16),
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
                  : Icon(_IC.tricycle, size: 16),
              label: const Text('Book Ride →',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DRIVER SELECTOR
  // ══════════════════════════════════════════════════════════════════════

  Widget _driverSelectorSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'SELECT DRIVER',
          style: TextStyle(
            color: _textSub,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _o(_green, 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _o(_green, 0.25)),
          ),
          child: const Text(
            'ONLINE ONLY',
            style: TextStyle(
              color: _green,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _loadNearbyDrivers,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _o(_accent, 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _o(_accent, 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _IC.refresh,
                color: _driversLoading ? _textSub : _accent,
                size: 11,
              ),
              const SizedBox(width: 4),
              Text(
                _driversLoading ? 'Loading…' : 'Refresh',
                style: TextStyle(
                  color: _driversLoading ? _textSub : _accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (_selectedDriverId != null) ...[
        _selectedDriverBanner(),
        const SizedBox(height: 8),
      ],
      _driverListBody(),
    ]);
  }

  Widget _selectedDriverBanner() {
    final d = _nearbyDrivers.firstWhere(
      (d) => d['id'] == _selectedDriverId,
      orElse: () => {},
    );
    if (d.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_o(_accent, 0.15), _o(_green, 0.08)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _o(_accent, 0.5), width: 1.5),
      ),
      child: Row(children: [
        Icon(_IC.check, color: _green, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              const TextSpan(
                text: 'Selected: ',
                style: TextStyle(color: _textSub, fontSize: 11),
              ),
              TextSpan(
                text: d['name'] as String? ?? '',
                style: const TextStyle(
                  color: _textPrim,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _selectedDriverId = null;
            _selectedDriver = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _o(_red, 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _o(_red, 0.25)),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                  color: _red, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _driverListBody() {
    if (_driversLoading && _nearbyDrivers.isEmpty) {
      return Column(
          children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 68,
          decoration: BoxDecoration(
            color: _navyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _o(_accent, 0.06),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 100,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _o(_textSub, 0.15),
                      borderRadius: BorderRadius.circular(4),
                    )),
                const SizedBox(height: 6),
                Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _o(_textSub, 0.08),
                      borderRadius: BorderRadius.circular(4),
                    )),
              ],
            ),
          ]),
        ),
      ));
    }

    if (_nearbyDrivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _navyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _o(_textSub, 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_IC.tricycle, color: _o(_textSub, 0.5), size: 22),
          ),
          const SizedBox(height: 10),
          const Text(
            'No drivers online',
            style: TextStyle(
                color: _textPrim, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pull to refresh or wait a moment',
            style: TextStyle(color: _textSub, fontSize: 11),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loadNearbyDrivers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _o(_accent, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _o(_accent, 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_IC.refresh, color: _accent, size: 13),
                const SizedBox(width: 6),
                const Text('Check Again',
                    style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      );
    }

    return Column(
      children: _nearbyDrivers.map((d) => _driverCard(d)).toList(),
    );
  }

  Widget _driverCard(Map<String, dynamic> d) {
    final id = d['id'] as String;
    final isSelected = _selectedDriverId == id;
    final name = d['name'] as String? ?? '';
    final plate = d['plate'] as String? ?? '';
    final rating = d['rating'] as String? ?? '—';
    final trips = d['trips'] as String? ?? '—';
    final initials = d['initials'] as String? ?? 'DR';

    final ratingVal = double.tryParse(rating) ?? 0.0;
    final fullStars = ratingVal.floor().clamp(0, 5);

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedDriverId = null;
          _selectedDriver = null;
        } else {
          _selectedDriverId = id;
          _selectedDriver = name;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? _o(_accent, 0.08) : _navyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _accent : _cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _o(_accent, 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Stack(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [_o(_accent, 0.35), _o(_accent, 0.15)]
                        : [_o(_accent, 0.18), _o(_accent, 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isSelected ? _o(_accent, 0.6) : _o(_accent, 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isSelected ? _accent : _o(_accent, 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _navyLight, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _o(_green, 0.5),
                          blurRadius: 4,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: _textPrim,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _o(_accent, 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _o(_accent, 0.4)),
                        ),
                        child: const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(_IC.tricycle, color: _textSub, size: 11),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        plate,
                        style: const TextStyle(color: _textSub, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < fullStars ? _IC.star : _IC.starOutline,
                        color: i < fullStars ? _orange : _o(_textSub, 0.4),
                        size: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating != '—' ? rating : 'No rating',
                      style: TextStyle(
                        color: rating != '—' ? _orange : _textSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (trips != '—') ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: _textSub,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(_IC.tripCount, color: _textSub, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        '$trips trips',
                        style: const TextStyle(color: _textSub, fontSize: 10),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _accent : _o(_textSub, 0.35),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _o(_accent, 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          color: _textSub,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8));

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
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
          child: Icon(icon, color: _textSub, size: 18),
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
              child: Icon(_IC.refresh, color: _textSub, size: 18)),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Column(children: [
              Icon(_IC.tricycle, color: _textSub, size: 32),
              const SizedBox(height: 8),
              const Text('No drivers online right now',
                  style: TextStyle(color: _textSub, fontSize: 13)),
            ])),
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('Online',
                  style: TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
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

  // ══════════════════════════════════════════════════════════════════════
  //  TAB 1 — TRIP RECORDS
  // ══════════════════════════════════════════════════════════════════════

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
                    Icon(_IC.history, color: _textSub, size: 52),
                    const SizedBox(height: 12),
                    const Text('No trips yet',
                        style: TextStyle(color: _textSub, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Book your first ride from Overview',
                        style: TextStyle(color: _textSub, fontSize: 12)),
                  ]))
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
              color: _o(_accent, 0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Icon(_IC.tricycle, color: _accent, size: 20)),
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
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              _PulseDot(color: _green)
            ],
          ]),
        ])),
        Text(r['created_at']?.toString().substring(0, 10) ?? '',
            style: const TextStyle(color: _textSub, fontSize: 10)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TAB 2 — PROFILE
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab(AuthProvider auth) {
    final profile = _profile;

    if (_profileLoading && profile == null) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      onRefresh: _loadCommuterProfile,
      color: _accent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            color: _navyLight,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
            child: Column(children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildAvatarWidget(radius: 44, fontSize: 34),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadProfilePhoto,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: _navyLight, width: 2),
                        ),
                        child: const Icon(_IC.camera,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : auth.username ?? 'Commuter',
                style: const TextStyle(
                    color: _textPrim,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text('@${auth.username ?? ''}',
                  style: const TextStyle(color: _textSub, fontSize: 12)),
              const SizedBox(height: 8),
              if (profile?.phone.isNotEmpty == true)
                Text(profile!.phone,
                    style: const TextStyle(color: _textSub, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _o(_accent, 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _o(_accent, 0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_IC.role, color: _accent, size: 12),
                  const SizedBox(width: 5),
                  const Text('Commuter',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _profileStatBox(
                  'Total Trips', _totalBookings.toString(), _accent),
              const SizedBox(width: 10),
              _profileStatBox('Total Spent', _totalSpent, _green),
              const SizedBox(width: 10),
              _profileStatBox('Last Fare', _lastFare, _orange),
            ]),
          ),
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
                      _profileInfoRow(_IC.accuracy, 'Accuracy',
                          '±${_gpsAccuracy?.toStringAsFixed(0) ?? '—'} m ($_gpsAccuracyLabel)',
                          valueColor: _gpsAccuracyColor),
                      _profileInfoRow(_IC.speed, 'Speed', _gpsSpeedLabel),
                      if (_myLocation != null)
                        _profileInfoRow(_IC.location, 'Position',
                            '${_myLocation!.latitude.toStringAsFixed(5)}, ${_myLocation!.longitude.toStringAsFixed(5)}'),
                      _profileInfoRow(
                          _IC.gpsOn,
                          'Broadcast',
                          _activeBooking != null
                              ? 'Broadcasting'
                              : 'On ride only'),
                    ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildEditableSection(
              title: 'Personal Information',
              icon: _IC.badge,
              accentColor: _accent,
              onEdit: () => _showEditDialog(
                title: 'Edit Personal Info',
                fields: [
                  _EditField('Full Name', 'fullName', profile?.fullName ?? ''),
                  _EditField('Age', 'age', profile?.age ?? '',
                      keyboardType: TextInputType.number),
                  _EditField('Phone Number', 'phone', profile?.phone ?? '',
                      keyboardType: TextInputType.phone),
                  _EditField('Email Address', 'email', profile?.email ?? '',
                      keyboardType: TextInputType.emailAddress),
                  _EditField('Address', 'address', profile?.address ?? ''),
                ],
              ),
              child: Column(children: [
                _profileInfoRow(
                    _IC.badge,
                    'Full Name',
                    profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : '—'),
                _profileInfoRow(_IC.age, 'Age',
                    profile?.age.isNotEmpty == true ? profile!.age : '—'),
                _profileInfoRow(_IC.phone, 'Phone Number',
                    profile?.phone.isNotEmpty == true ? profile!.phone : '—'),
                _profileInfoRow(_IC.email, 'Email Address',
                    profile?.email.isNotEmpty == true ? profile!.email : '—'),
                _profileInfoRow(
                    _IC.location,
                    'Address',
                    profile?.address.isNotEmpty == true
                        ? profile!.address
                        : '—'),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_IC.lock, color: _purple, size: 16),
                      const SizedBox(width: 7),
                      const Text('Account',
                          style: TextStyle(
                              color: _textPrim,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    _profileInfoRow(
                        _IC.person, 'Username', auth.username ?? '—'),
                    _profileInfoRow(_IC.lock, 'Password', '••••••••'),
                    _profileInfoRow(_IC.role, 'Role', 'Commuter'),
                  ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () => _showChangePasswordDialog(),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _o(_purple, 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _o(_purple, 0.3)),
                ),
                child: Row(children: [
                  Icon(_IC.lock, color: _purple, size: 18),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Password',
                              style: TextStyle(
                                  color: _textPrim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('Update your account password',
                              style: TextStyle(color: _textSub, fontSize: 11)),
                        ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _textSub, size: 20),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GestureDetector(
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _o(_red, 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _o(_red, 0.3)),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_IC.signOut, color: _red, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out',
                          style: TextStyle(
                              color: _red,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 7),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: _textPrim,
                      fontSize: 13,
                      fontWeight: FontWeight.w700))),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _o(accentColor, 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _o(accentColor, 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_IC.edit, color: accentColor, size: 12),
                const SizedBox(width: 4),
                Text('Edit',
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value,
          {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(icon, color: _textSub, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
          ]),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? _textPrim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
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

  void _showEditDialog(
      {required String title, required List<_EditField> fields}) {
    final controllers = {
      for (final f in fields) f.key: TextEditingController(text: f.initialValue)
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _navyLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorder, width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(_IC.edit, color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          color: _textPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: _textSub, size: 20),
                  ),
                ]),
                const SizedBox(height: 20),
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: const TextStyle(
                                    color: _textSub,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: _navy,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: TextField(
                                controller: controllers[f.key],
                                keyboardType: f.keyboardType,
                                style: const TextStyle(
                                    color: _textPrim, fontSize: 13),
                                cursorColor: _accent,
                                decoration: InputDecoration(
                                  hintText: f.label,
                                  hintStyle: TextStyle(
                                      color: _o(_textSub, 0.6), fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                ),
                              ),
                            ),
                          ]),
                    )),
                const SizedBox(height: 6),
                StatefulBuilder(builder: (ctx2, setSt) {
                  bool saving = false;
                  return GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            setSt(() => saving = true);
                            final updates = {
                              for (final f in fields)
                                f.key: controllers[f.key]!.text.trim()
                            };
                            final ok = await _updateProfile(updates);
                            if (ctx2.mounted) Navigator.pop(ctx2);
                            _showSnack(
                                ok
                                    ? 'Profile updated!'
                                    : 'Failed to save changes.',
                                ok ? _green : _red);
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _o(_accent, 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_IC.save, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ]),
                    ),
                  );
                }),
              ]),
            ),
          ),
        );
      },
    ).whenComplete(() {
      for (final c in controllers.values) c.dispose();
    });
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _navyLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorder, width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(_IC.lock, color: _purple, size: 18),
                  const SizedBox(width: 8),
                  const Text('Change Password',
                      style: TextStyle(
                          color: _textPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child:
                          const Icon(Icons.close, color: _textSub, size: 20)),
                ]),
                const SizedBox(height: 20),
                _pwdField(currentCtrl, 'Current Password'),
                const SizedBox(height: 12),
                _pwdField(newCtrl, 'New Password'),
                const SizedBox(height: 12),
                _pwdField(confirmCtrl, 'Confirm New Password'),
                const SizedBox(height: 20),
                StatefulBuilder(builder: (ctx2, setSt) {
                  bool saving = false;
                  return GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            if (newCtrl.text != confirmCtrl.text) {
                              _showSnack('Passwords do not match.', _red);
                              return;
                            }
                            setSt(() => saving = true);
                            final ok = await _updateProfile({
                              'current_password': currentCtrl.text,
                              'new_password': newCtrl.text,
                            });
                            if (ctx2.mounted) Navigator.pop(ctx2);
                            _showSnack(
                                ok
                                    ? 'Password changed!'
                                    : 'Failed to change password.',
                                ok ? _green : _red);
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _o(_purple, 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_IC.save, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Update Password',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ]),
                    ),
                  );
                }),
              ]),
            ),
          ),
        );
      },
    ).whenComplete(() {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Widget _pwdField(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        style: const TextStyle(color: _textPrim, fontSize: 13),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _o(_textSub, 0.6), fontSize: 13),
          prefixIcon: Icon(_IC.lock, color: _textSub, size: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PULSING DOT
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
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
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
