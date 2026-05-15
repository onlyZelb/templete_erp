import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../widgets/chat_widget.dart';
import '../login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _Responsive {
  static bool isCompact(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 400;

  static double appBarHeight(BuildContext ctx) =>
      isCompact(ctx) ? 60 : 72;

  static double avatarRadius(BuildContext ctx) =>
      isCompact(ctx) ? 14 : 16;

  static double logoSize(BuildContext ctx) =>
      isCompact(ctx) ? 34 : 40;

  static double titleFontSize(BuildContext ctx) =>
      isCompact(ctx) ? 16 : 19;

  static double subtitleFontSize(BuildContext ctx) =>
      isCompact(ctx) ? 9.5 : 11;
}

Color _o(Color c, double a) => c.withValues(alpha: a);

class _IC {
  static const person = Icons.person_outline_rounded;
  static const badge = Icons.badge_outlined;
  static const role = Icons.verified_user_outlined;
  static const phone = Icons.phone_outlined;
  static const email = Icons.email_outlined;
  static const location = Icons.location_on_outlined;
  static const age = Icons.cake_outlined;
  static const car = Icons.directions_car_outlined;
  static const gpsOn = Icons.gps_fixed;
  static const gpsOff = Icons.gps_off;
  static const speed = Icons.speed_outlined;
  static const accuracy = Icons.radar_outlined;
  static const dashboard = Icons.map_outlined;
  static const earnings = Icons.account_balance_wallet_outlined;
  static const profile = Icons.account_circle_outlined;
  static const notification = Icons.notifications_outlined;
  static const refresh = Icons.refresh_rounded;
  static const cancel = Icons.cancel_outlined;
  static const signOut = Icons.logout_rounded;
  static const settings = Icons.settings_outlined;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const receipt = Icons.receipt_outlined;
  static const check = Icons.check_circle_outline_rounded;
  static const camera = Icons.camera_alt_rounded;
  static const edit = Icons.edit_outlined;
  static const save = Icons.save_outlined;
  static const online = Icons.wifi_outlined;
  static const offline = Icons.wifi_off_outlined;
  static const plate = Icons.pin_outlined;
  static const license = Icons.credit_card_outlined;
  static const org = Icons.store_outlined;
  static const flag = Icons.flag_outlined;
  static const bolt = Icons.bolt;
  static const priceChange = Icons.price_change_outlined;
  static const tripCount = Icons.route_outlined;
  static const totalEarnings = Icons.bar_chart_outlined;
  static const todayEarnings = Icons.today_outlined;
  static const folder = Icons.folder_outlined;
  static const lock = Icons.lock_outline_rounded;
  static const manage = Icons.manage_accounts_outlined;
  static const pickup = Icons.radio_button_checked;
  static const dropoff = Icons.location_on;
  static const chat = Icons.chat_bubble_outline_rounded;
  static const send = Icons.send_rounded;
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────

class DriverThemeColors {
  final Color bgDeep;
  final Color bgLight;
  final Color card;
  final Color border;
  final Color accent;
  final Color green;
  final Color orange;
  final Color red;
  final Color purple;
  final Color textPrimary;
  final Color textMuted;
  final Color appBarBg;
  final Color mapOverlayBg;

  const DriverThemeColors({
    required this.bgDeep,
    required this.bgLight,
    required this.card,
    required this.border,
    required this.accent,
    required this.green,
    required this.orange,
    required this.red,
    required this.purple,
    required this.textPrimary,
    required this.textMuted,
    required this.appBarBg,
    required this.mapOverlayBg,
  });

  static const dark = DriverThemeColors(
    bgDeep: Color(0xFF0B1B35),
    bgLight: Color(0xFF0D1E35),
    card: Color(0xFF102245),
    border: Color(0xFF1E3A6E),
    accent: Color(0xFF3D7FD4),
    green: Color(0xFF1DBE74),
    orange: Color(0xFFF4A620),
    red: Color(0xFFEF4444),
    purple: Color(0xFFA855F7),
    textPrimary: Color(0xFFE8EEF7),
    textMuted: Color(0xFF6B8BA4),
    appBarBg: Color(0xFF081422),
    mapOverlayBg: Color(0xFF0D1A30),
  );

  static const light = DriverThemeColors(
    bgDeep: Color(0xFFF0F4FA),
    bgLight: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFCBD5E1),
    accent: Color(0xFF2563EB),
    green: Color(0xFF16A34A),
    orange: Color(0xFFD97706),
    red: Color(0xFFDC2626),
    purple: Color(0xFF9333EA),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    appBarBg: Color(0xFFFFFFFF),
    mapOverlayBg: Color(0xFFFFFFFF),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class DriverThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;
  DriverThemeColors get colors =>
      _isDark ? DriverThemeColors.dark : DriverThemeColors.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SYSTEM
// ─────────────────────────────────────────────────────────────────────────────

enum NotifType {
  info,
  rideRequest,
  rideAccepted,
  rideDeclined,
  rideCompleted,
  rideEarned,
  gpsLost,
  surgeActive,
  driverOnline,
  driverOffline,
}

class AppNotification {
  final NotifType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;

  AppNotification({
    required this.type,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.read = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.driverOnline() => AppNotification(
        type: NotifType.driverOnline,
        title: 'You\'re Online 🟢',
        body: 'You\'re now visible to commuters. Waiting for ride requests.',
      );

  factory AppNotification.driverOffline() => AppNotification(
        type: NotifType.driverOffline,
        title: 'You\'re Offline',
        body: 'You won\'t receive ride requests while offline.',
      );

  factory AppNotification.newRideRequest(
          String passenger, String pickup, String fare) =>
      AppNotification(
        type: NotifType.rideRequest,
        title: 'New Ride Request! 🚗',
        body: '$passenger needs a ride from $pickup · Est. $fare',
      );

  factory AppNotification.rideEarned(String amount) => AppNotification(
        type: NotifType.rideEarned,
        title: 'Earnings Updated 💰',
        body: 'You earned $amount from this ride. Keep it up!',
      );

  IconData get icon {
    switch (type) {
      case NotifType.rideRequest:
        return Icons.directions_car_outlined;
      case NotifType.rideAccepted:
        return Icons.check_circle_outline_rounded;
      case NotifType.rideDeclined:
        return Icons.cancel_outlined;
      case NotifType.rideCompleted:
        return Icons.flag_circle_outlined;
      case NotifType.rideEarned:
        return Icons.account_balance_wallet_outlined;
      case NotifType.gpsLost:
        return Icons.gps_off;
      case NotifType.surgeActive:
        return Icons.bolt;
      case NotifType.driverOnline:
        return Icons.wifi_outlined;
      case NotifType.driverOffline:
        return Icons.wifi_off_outlined;
      case NotifType.info:
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotifType.rideRequest:
        return const Color(0xFF3D7FD4);
      case NotifType.rideAccepted:
        return const Color(0xFF1DBE74);
      case NotifType.rideDeclined:
        return const Color(0xFFEF4444);
      case NotifType.rideCompleted:
        return const Color(0xFF1DBE74);
      case NotifType.rideEarned:
        return const Color(0xFF1DBE74);
      case NotifType.gpsLost:
        return const Color(0xFFF4A620);
      case NotifType.surgeActive:
        return const Color(0xFFF4A620);
      case NotifType.driverOnline:
        return const Color(0xFF1DBE74);
      case NotifType.driverOffline:
        return const Color(0xFF6B8BA4);
      case NotifType.info:
      default:
        return const Color(0xFF3D7FD4);
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationService extends ChangeNotifier {
  final List<AppNotification> _items = [];

  List<AppNotification> get all =>
      List.unmodifiable(_items.reversed.toList());
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  void add(AppNotification notif) {
    _items.add(notif);
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) n.read = true;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void remove(AppNotification notif) {
    _items.remove(notif);
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION BELL
// ─────────────────────────────────────────────────────────────────────────────

class NotificationBell extends StatelessWidget {
  final NotificationService service;
  final Color iconColor;
  final Color badgeColor;
  final DriverThemeColors themeColors;

  const NotificationBell({
    super.key,
    required this.service,
    required this.iconColor,
    required this.badgeColor,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (_, __) {
        final count = service.unreadCount;
        return GestureDetector(
          onTap: () => _showPanel(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(_IC.notification, color: iconColor, size: 20),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: themeColors.bgLight, width: 1.5),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPanel(BuildContext context) {
    service.markAllRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _NotificationPanel(service: service, themeColors: themeColors),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationPanel extends StatelessWidget {
  final NotificationService service;
  final DriverThemeColors themeColors;
  const _NotificationPanel(
      {required this.service, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final t = themeColors;
    return AnimatedBuilder(
      animation: service,
      builder: (_, __) {
        final notifs = service.all;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: t.bgLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: t.border, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _o(t.textMuted, 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(_IC.notification, color: t.accent, size: 18),
                      const SizedBox(width: 8),
                      Text('Notifications',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                      if (notifs.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _o(t.accent, 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: _o(t.accent, 0.3)),
                          ),
                          child: Text('${notifs.length}',
                              style: TextStyle(
                                  color: t.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const Spacer(),
                      if (notifs.isNotEmpty)
                        GestureDetector(
                          onTap: service.clear,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _o(t.red, 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _o(t.red, 0.25)),
                            ),
                            child: Text('Clear all',
                                style: TextStyle(
                                    color: t.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close,
                            color: t.textMuted, size: 20),
                      ),
                    ],
                  ),
                ),
                Divider(color: t.border, height: 1),
                Expanded(
                  child: notifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_IC.notification,
                                  color: _o(t.textMuted, 0.35),
                                  size: 44),
                              const SizedBox(height: 10),
                              Text('No notifications yet',
                                  style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Ride updates will appear here',
                                  style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          itemCount: notifs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _NotifTile(
                              notif: notifs[i],
                              service: service,
                              themeColors: t),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final NotificationService service;
  final DriverThemeColors themeColors;

  const _NotifTile(
      {required this.notif,
      required this.service,
      required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final t = themeColors;
    final color = notif.color;
    return Dismissible(
      key: ValueKey(notif.timestamp),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _o(t.red, 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            Icon(Icons.delete_outline_rounded, color: t.red, size: 20),
      ),
      onDismissed: (_) => service.remove(notif),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.read ? t.card : _o(color, 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.read ? t.border : _o(color, 0.35),
            width: notif.read ? 1.0 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _o(color, 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _o(color, 0.3)),
              ),
              child: Icon(notif.icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notif.title,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 12,
                            fontWeight: notif.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          )),
                    ),
                    if (!notif.read)
                      Container(
                        width: 7,
                        height: 7,
                        margin:
                            const EdgeInsets.only(left: 6, top: 2),
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: TextStyle(
                          color: t.textMuted, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(notif.timeAgo,
                      style: TextStyle(
                          color: _o(t.textMuted, 0.6),
                          fontSize: 9,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FARE CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class FareConfig {
  final double baseFare;
  final double perKmRate;
  final double minimumFare;
  final double bookingFee;
  final double surgeMultiplier;
  final bool surgeEnabled;

  const FareConfig({
    required this.baseFare,
    required this.perKmRate,
    required this.minimumFare,
    required this.bookingFee,
    required this.surgeMultiplier,
    required this.surgeEnabled,
  });

  factory FareConfig.defaults() => const FareConfig(
        baseFare: 15.0,
        perKmRate: 8.0,
        minimumFare: 15.0,
        bookingFee: 0.0,
        surgeMultiplier: 1.0,
        surgeEnabled: false,
      );

  factory FareConfig.fromJson(Map<String, dynamic> json) {
    double d(dynamic v, double fallback) =>
        v == null ? fallback : (double.tryParse(v.toString()) ?? fallback);
    return FareConfig(
      baseFare: d(json['base_fare'], 15.0),
      perKmRate: d(json['per_km_rate'], 8.0),
      minimumFare: d(json['minimum_fare'], 15.0),
      bookingFee: d(json['booking_fee'], 0.0),
      surgeMultiplier: d(json['surge_multiplier'], 1.0),
      surgeEnabled:
          json['surge_enabled'] == true || json['surge_enabled'] == 1,
    );
  }

  double computeFare(double distanceKm) {
    final multiplier = surgeEnabled ? surgeMultiplier : 1.0;
    final computed =
        (baseFare + perKmRate * distanceKm) * multiplier + bookingFee;
    return computed < minimumFare ? minimumFare : computed;
  }

  String computeFareString(double distanceKm) =>
      '₱${computeFare(distanceKm).toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
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

    final fareRaw = json['fare'];
    final double fare = fareRaw is num
        ? fareRaw.toDouble()
        : double.tryParse(fareRaw?.toString() ?? '0') ?? 0.0;

    final passengerName =
        json['passenger_name']?.toString().isNotEmpty == true
            ? json['passenger_name'].toString()
            : json['commuter_name']?.toString().isNotEmpty == true
                ? json['commuter_name'].toString()
                : json['name']?.toString().isNotEmpty == true
                    ? json['name'].toString()
                    : json['username']?.toString().isNotEmpty == true
                        ? json['username'].toString()
                        : json['full_name']?.toString().isNotEmpty == true
                            ? json['full_name'].toString()
                            : 'Passenger';

    final distRaw = json['distance_km'] ??
        json['distance'] ??
        json['dist_km'] ??
        json['km'] ??
        json['route_distance'];
    final double distanceKm = distRaw is num
        ? distRaw.toDouble()
        : double.tryParse(distRaw?.toString() ?? '0') ?? 0.0;

    final pickupLabel =
        json['pickup_location']?.toString().isNotEmpty == true
            ? json['pickup_location'].toString()
            : json['pickup_label']?.toString().isNotEmpty == true
                ? json['pickup_label'].toString()
                : json['pickup']?.toString().isNotEmpty == true
                    ? json['pickup'].toString()
                    : json['from']?.toString() ?? '';

    final dropoffLabel =
        json['destination']?.toString().isNotEmpty == true
            ? json['destination'].toString()
            : json['dropoff_label']?.toString().isNotEmpty == true
                ? json['dropoff_label'].toString()
                : json['dropoff']?.toString().isNotEmpty == true
                    ? json['dropoff'].toString()
                    : json['to']?.toString() ?? '';

    return RideRequest(
      id: (json['id'] as num).toInt(),
      passengerName: passengerName,
      pickup: LatLng(pickupLat.toDouble(), pickupLng.toDouble()),
      dropoff: LatLng(dropoffLat.toDouble(), dropoffLng.toDouble()),
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      fare: fare,
      distanceKm: distanceKm,
    );
  }

  bool get hasValidPickup => pickup.latitude != 0 || pickup.longitude != 0;
  bool get hasValidDropoff => dropoff.latitude != 0 || dropoff.longitude != 0;
}

class DriverProfile {
  final String username;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String age;
  final String plateNumber;
  final String licenseNumber;
  final String organization;
  final String contact;
  final String? profilePhotoUrl;
  final String? licensePhotoUrl;
  final String? vehiclePhotoUrl;
  final String? todaPhotoUrl;

  const DriverProfile({
    required this.username,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.age,
    required this.plateNumber,
    required this.licenseNumber,
    required this.organization,
    required this.contact,
    this.profilePhotoUrl,
    this.licensePhotoUrl,
    this.vehiclePhotoUrl,
    this.todaPhotoUrl,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ??
          json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['contact']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      licenseNumber: json['license_number']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      contact: json['contact']?.toString() ??
          json['phone']?.toString() ?? '',
      profilePhotoUrl: json['profile_photo']?.toString() ??
          json['profilePhoto']?.toString(),
      licensePhotoUrl: json['photo_license']?.toString() ??
          json['licensePhoto']?.toString(),
      vehiclePhotoUrl: json['photo_plate']?.toString() ??
          json['vehiclePhoto']?.toString(),
      todaPhotoUrl: json['photo_toda']?.toString() ??
          json['todaPhoto']?.toString(),
    );
  }

  DriverProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? age,
    String? plateNumber,
    String? licenseNumber,
    String? organization,
    String? contact,
    String? profilePhotoUrl,
    String? licensePhotoUrl,
    String? vehiclePhotoUrl,
    String? todaPhotoUrl,
  }) {
    return DriverProfile(
      username: username,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      age: age ?? this.age,
      plateNumber: plateNumber ?? this.plateNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      organization: organization ?? this.organization,
      contact: contact ?? this.contact,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      licensePhotoUrl: licensePhotoUrl ?? this.licensePhotoUrl,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      todaPhotoUrl: todaPhotoUrl ?? this.todaPhotoUrl,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR BADGE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarBadgeDot {
  final Color color;
  final bool pulsing;
  _AppBarBadgeDot._({required this.color, required this.pulsing});
  factory _AppBarBadgeDot.pulsing(Color c) =>
      _AppBarBadgeDot._(color: c, pulsing: true);
  factory _AppBarBadgeDot.static(Color c) =>
      _AppBarBadgeDot._(color: c, pulsing: false);
}

class _AppBarBadge extends StatelessWidget {
  final DriverThemeColors themeColors;
  final _AppBarBadgeDot? dot;
  final String topLabel;
  final Color topLabelColor;
  final String? bottomLabel;
  final Color? bottomLabelColor;
  final Color borderColor;
  final bool surgeActive;
  final bool compact;

  const _AppBarBadge({
    required this.themeColors,
    this.dot,
    required this.topLabel,
    required this.topLabelColor,
    this.bottomLabel,
    this.bottomLabelColor,
    required this.borderColor,
    this.surgeActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor.withValues(alpha: 0.15),
            borderColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: borderColor.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 6,
              spreadRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (dot != null) ...[
            dot!.pulsing
                ? _PulsingDot(color: dot!.color)
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: dot!.color, shape: BoxShape.circle),
                  ),
            const SizedBox(width: 3),
          ],
          if (surgeActive) ...[
            Icon(_IC.bolt, color: topLabelColor, size: 9),
            const SizedBox(width: 1),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topLabel,
                  style: TextStyle(
                      color: topLabelColor,
                      fontSize: compact ? 8 : 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1.1)),
              if (bottomLabel != null && !compact)
                Text(bottomLabel!,
                    style: TextStyle(
                        color: bottomLabelColor ??
                            topLabelColor.withValues(alpha: 0.65),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final Widget child;
  final DriverThemeColors themeColors;
  const _AppBarIconButton(
      {required this.child, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Center(child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT FIELD HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _EditField {
  final String label;
  final String key;
  final String initialValue;
  final TextInputType keyboardType;
  const _EditField(this.label, this.key, this.initialValue,
      {this.keyboardType = TextInputType.text});
}

enum _DocSlot { license, vehicle, toda }

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
  final DriverThemeProvider _themeProvider = DriverThemeProvider();
  DriverThemeColors get _t => _themeProvider.colors;

  bool _isOnline = false;
  List _earnings = [];
  Map? _summary;
  bool _loading = false;
  int _tab = 0;

  final MapController _mapController = MapController();
  LatLng _driverLocation = const LatLng(14.5995, 120.9842);
  List<LatLng> _routePoints = [];
  RideRequest? _activeRide;
  RideRequest? _pendingRequest;
  bool _routeLoading = false;
  StreamSubscription<Position>? _locationSub;

  double? _gpsAccuracy;
  double? _gpsSpeed;
  double? _gpsHeading;
  bool _isTracking = false;

  LatLng? _commuterLiveLocation;

  DriverProfile? _driverProfile;
  bool _profileLoading = false;

  FareConfig _fareConfig = FareConfig.defaults();
  bool _fareConfigLoading = false;
  Timer? _fareConfigRefreshTimer;

  Timer? _ridePollingTimer;
  Timer? _locationPushTimer;
  Timer? _profileRefreshTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final NotificationService _notif = NotificationService();

  String get _gpsAccuracyLabel {
    if (_gpsAccuracy == null) return '—';
    if (_gpsAccuracy! < 5) return 'Excellent';
    if (_gpsAccuracy! < 15) return 'Good';
    if (_gpsAccuracy! < 40) return 'Fair';
    return 'Poor';
  }

  Color get _gpsAccuracyColor {
    if (_gpsAccuracy == null) return _t.textMuted;
    if (_gpsAccuracy! < 5) return _t.green;
    if (_gpsAccuracy! < 15) return _t.green;
    if (_gpsAccuracy! < 40) return _t.orange;
    return _t.red;
  }

  String get _gpsSpeedLabel {
    if (_gpsSpeed == null || _gpsSpeed! < 0.5) return '0 km/h';
    return '${(_gpsSpeed! * 3.6).toStringAsFixed(1)} km/h';
  }

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadEarnings();
    _loadDriverProfile();
    _loadFareConfig();
    _initGPS();
    _profileRefreshTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _loadDriverProfile());
    _fareConfigRefreshTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => _loadFareConfig());
  }

  @override
  void dispose() {
    _animController.dispose();
    _locationSub?.cancel();
    _ridePollingTimer?.cancel();
    _locationPushTimer?.cancel();
    _profileRefreshTimer?.cancel();
    _fareConfigRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFareConfig() async {
    if (_fareConfigLoading) return;
    setState(() => _fareConfigLoading = true);
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/api/fare-config');
      final data = res.data;
      if (data != null && data is Map<String, dynamic> && mounted) {
        final oldSurge = _fareConfig.surgeEnabled;
        final newConfig = FareConfig.fromJson(data);
        if (!oldSurge && newConfig.surgeEnabled) {
          _notif.add(AppNotification(
            type: NotifType.surgeActive,
            title: 'Surge Pricing Active 🔥',
            body:
                'Surge ×${newConfig.surgeMultiplier.toStringAsFixed(1)} is now active. Earn more per ride!',
          ));
        }
        setState(() => _fareConfig = newConfig);
      }
    } catch (_) {}
    if (mounted) setState(() => _fareConfigLoading = false);
  }

  Future<void> _initGPS() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _notif.add(AppNotification(
        type: NotifType.gpsLost,
        title: 'GPS Disabled',
        body: 'Please enable location services to go online.',
      ));
      return;
    }

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
          _isTracking = true;
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
        _isTracking = true;
      });
      if (_activeRide == null) {
        _mapController.move(
            _driverLocation, _mapController.camera.zoom);
      }
    }, onError: (_) {
      if (mounted) setState(() => _isTracking = false);
      _notif.add(AppNotification(
        type: NotifType.gpsLost,
        title: 'GPS Signal Lost',
        body: 'Location tracking interrupted. Tap to retry.',
      ));
    });
  }

  Future<void> _toggleOnline() async {
    final next = !_isOnline;
    setState(() => _isOnline = next);

    if (next) {
      _startRidePolling();
      _startLocationPush();
      _notif.add(AppNotification.driverOnline());
    } else {
      _ridePollingTimer?.cancel();
      _locationPushTimer?.cancel();
      _notif.add(AppNotification.driverOffline());
      setState(() {
        _activeRide = null;
        _pendingRequest = null;
        _routePoints = [];
        _commuterLiveLocation = null;
      });
    }

    try {
      // ── FIX: status toggle goes to PHP, not Django ─────────────────
      final dio = ApiClient.build(ApiConstants.phpBase);
      await dio.patch('/api/drivers/me/status', data: {
        'is_online': next,
        'lat': _driverLocation.latitude,
        'lng': _driverLocation.longitude,
      });
    } catch (_) {}
  }

  void _startLocationPush() {
    _locationPushTimer?.cancel();
    _locationPushTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => _pushLocation());
    _pushLocation();
  }

  Future<void> _pushLocation() async {
    if (!_isOnline) return;
    try {
      // ── FIX: location push goes to PHP ─────────────────────────────
      final dio = ApiClient.build(ApiConstants.phpBase);
      await dio.patch('/api/drivers/me/location', data: {
        'lat': _driverLocation.latitude,
        'lng': _driverLocation.longitude,
      });

      // ── FIX: driver-location-on-active-ride also goes to PHP ───────
      if (_activeRide != null) {
        await dio.post(
          '/api/rides/${_activeRide!.id}/location',
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

  Future<void> _loadDriverProfile() async {
    if (_profileLoading) return;
    setState(() => _profileLoading = true);
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/api/drivers/me/profile');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() => _driverProfile = DriverProfile.fromJson(data));
      }
    } catch (_) {}
    if (mounted) setState(() => _profileLoading = false);
  }

  Future<bool> _updateProfile(Map<String, dynamic> updates) async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/me/profile', data: updates);
      await _loadDriverProfile();
      _notif.add(AppNotification(
        type: NotifType.info,
        title: 'Profile Updated',
        body: 'Your profile changes have been saved.',
      ));
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
        success ? _t.green : _t.red,
      );
    }
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if ((from.latitude == 0 && from.longitude == 0) ||
        (to.latitude == 0 && to.longitude == 0)) return;

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
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = coords
              .map<LatLng>((c) => LatLng(
                  (c[1] as num).toDouble(), (c[0] as num).toDouble()))
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

  void _startRidePolling() {
    _ridePollingTimer?.cancel();
    _ridePollingTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _pollPendingRide());
    _pollPendingRide();
  }

  Future<void> _pollPendingRide() async {
    if (!_isOnline || _activeRide != null || _pendingRequest != null)
      return;
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      final res = await dio.get('/api/drivers/rides/pending');
      final data = res.data;
      if (data != null && data is Map && data.isNotEmpty) {
        final req =
            RideRequest.fromJson(data as Map<String, dynamic>);
        if (mounted && _pendingRequest == null && _activeRide == null) {
          setState(() => _pendingRequest = req);
          _notif.add(AppNotification.newRideRequest(
            req.passengerName,
            req.pickupLabel.isNotEmpty
                ? req.pickupLabel
                : 'Unknown pickup',
            _fareConfig.computeFareString(req.distanceKm),
          ));
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
        final res = await dio.get(
            '/api/drivers/rides/${_activeRide!.id}/commuter-location');
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

  Future<void> _acceptRide(RideRequest req) async {
    Navigator.of(context).pop();
    setState(() {
      _activeRide = req;
      _pendingRequest = null;
    });

    if (req.hasValidPickup && req.hasValidDropoff) {
      await _fetchRoute(_driverLocation, req.pickup);
    } else {
      if (mounted)
        _showSnack(
            'Warning: ride has missing location data.', _t.orange);
    }

    _notif.add(AppNotification(
      type: NotifType.rideAccepted,
      title: 'Ride Accepted',
      body:
          'You accepted ${req.passengerName}\'s ride. Navigate to pickup point.',
    ));

    if (mounted)
      _showSnack(
          'Ride accepted! Navigate to pickup point.', _t.green);
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
    final passengerName = _activeRide!.passengerName;
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/rides/$rideId/complete', data: {
        'driver_lat': _driverLocation.latitude,
        'driver_lng': _driverLocation.longitude,
      });
      await _loadEarnings();
      _notif
          .add(AppNotification.rideEarned('₱${earned.toStringAsFixed(2)}'));
      _notif.add(AppNotification(
        type: NotifType.rideCompleted,
        title: 'Ride Completed',
        body:
            'You completed $passengerName\'s ride and earned ₱${earned.toStringAsFixed(2)}.',
      ));
    } catch (_) {} finally {
      if (mounted) {
        _showSnack(
            'Ride completed! ₱${earned.toStringAsFixed(2)} earned.',
            _t.green);
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

  Future<void> _declineRideOnBackend(int rideId) async {
    try {
      final dio = ApiClient.build(ApiConstants.djangoBase);
      await dio.patch('/api/drivers/rides/$rideId/decline');
    } catch (_) {}
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
        left: 16,
        right: 16,
      ),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showRideRequestSheet(RideRequest req) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RideRequestSheet(
        req: req,
        fareConfig: _fareConfig,
        themeColors: _t,
        onAccept: () => _acceptRide(req),
        onDecline: () {
          Navigator.of(context).pop();
          setState(() => _pendingRequest = null);
          _notif.add(AppNotification(
            type: NotifType.rideDeclined,
            title: 'Ride Declined',
            body:
                'You declined ${req.passengerName}\'s ride request.',
          ));
          _declineRideOnBackend(req.id);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _t.bgDeep,
          appBar: _buildAppBar(context, auth),
          bottomNavigationBar: _buildBottomNav(),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: switch (_tab) {
              0 => _buildDashboardTab(auth),
              1 => _buildEarningsTab(),
              2 => _buildProfileTab(auth),
              _ => _buildDashboardTab(auth),
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthProvider auth) {
    final compact = _Responsive.isCompact(context);
    final barH = _Responsive.appBarHeight(context);
    final logoSz = _Responsive.logoSize(context);
    final titleFz = _Responsive.titleFontSize(context);
    final subFz = _Responsive.subtitleFontSize(context);
    final avatarR = _Responsive.avatarRadius(context);
    final showFareBadge = !compact;

    final displayName = _driverProfile?.fullName.isNotEmpty == true
        ? _driverProfile!.fullName.split(' ').first
        : auth.username ?? 'Driver';

    return AppBar(
      backgroundColor:
          _themeProvider.isDark ? Colors.transparent : _t.bgLight,
      elevation: 0,
      toolbarHeight: barH,
      flexibleSpace: _themeProvider.isDark
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF060F1C),
                    Color(0xFF081422),
                    Color(0xFF0A1929),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  top: -18,
                  right: 60,
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Container(
                      width: 3,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _o(_t.accent, 0.0),
                            _o(_t.accent, 0.18),
                            _o(_t.accent, 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _o(_t.accent, 0.0),
                        _o(_t.accent, 0.45),
                        _o(_t.orange, 0.25),
                        _o(_t.accent, 0.0),
                      ]),
                    ),
                  ),
                ),
              ]),
            )
          : Container(
              decoration: BoxDecoration(
                color: _t.bgLight,
                border: Border(
                    bottom: BorderSide(color: _t.border, width: 1)),
              ),
            ),
      automaticallyImplyLeading: false,
      titleSpacing: compact ? 10 : 14,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: logoSz + 8,
              height: logoSz + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _o(_t.accent, 0.25),
                  _o(_t.accent, 0.0),
                ]),
              ),
            ),
            Container(
              width: logoSz,
              height: logoSz,
              decoration: BoxDecoration(
                color: _o(_t.accent, 0.1),
                borderRadius: BorderRadius.circular(logoSz * 0.3),
                border:
                    Border.all(color: _o(_t.accent, 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: _o(_t.accent, 0.25),
                      blurRadius: 12,
                      spreadRadius: 0),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(logoSz * 0.28),
                child: Image.asset(
                  'assets/logo.png',
                  width: logoSz,
                  height: logoSz,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(_IC.car,
                      color: _t.accent, size: logoSz * 0.5),
                ),
              ),
            ),
          ]),
          SizedBox(width: compact ? 8 : 11),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'Pasada',
                            style: TextStyle(
                              color: _t.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: titleFz,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Now',
                            style: TextStyle(
                              color: _t.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: titleFz,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            _o(_t.accent, 0.25),
                            _o(_t.accent, 0.12),
                          ]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _o(_t.accent, 0.5), width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: _o(_t.accent, 0.2),
                                blurRadius: 6,
                                spreadRadius: 0),
                          ],
                        ),
                        child: Text(
                          'DRIVER',
                          style: TextStyle(
                            color: _t.accent,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$_timeGreeting, $displayName 👋',
                        style: TextStyle(
                          color: _o(_t.textMuted, 0.9),
                          fontSize: subFz,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _initGPS,
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: compact ? 14 : 18, horizontal: 2),
            child: _AppBarBadge(
              themeColors: _t,
              compact: compact,
              dot: _isTracking
                  ? _AppBarBadgeDot.pulsing(_t.green)
                  : _AppBarBadgeDot.static(_t.orange),
              topLabel: _isTracking ? 'LIVE' : 'GPS',
              topLabelColor: _isTracking ? _t.green : _t.orange,
              bottomLabel: _isTracking && _gpsAccuracy != null
                  ? '±${_gpsAccuracy!.toStringAsFixed(0)}m'
                  : null,
              bottomLabelColor: _gpsAccuracyColor,
              borderColor: _isTracking ? _t.green : _t.orange,
            ),
          ),
        ),
        if (showFareBadge)
          GestureDetector(
            onTap: _loadFareConfig,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 18, horizontal: 2),
              child: _AppBarBadge(
                themeColors: _t,
                compact: compact,
                topLabel:
                    '₱${_fareConfig.baseFare.toStringAsFixed(0)}+',
                topLabelColor: _fareConfig.surgeEnabled
                    ? _t.orange
                    : _t.accent,
                bottomLabel:
                    '${_fareConfig.perKmRate.toStringAsFixed(0)}/km',
                bottomLabelColor: _fareConfig.surgeEnabled
                    ? _t.orange
                    : _t.textMuted,
                borderColor: _fareConfig.surgeEnabled
                    ? _t.orange
                    : _t.accent,
                surgeActive: _fareConfig.surgeEnabled,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 18, horizontal: 2),
          child: _AppBarIconButton(
            themeColors: _t,
            child: NotificationBell(
              service: _notif,
              iconColor: _o(_t.textPrimary, 0.85),
              badgeColor: _t.accent,
              themeColors: _t,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _themeProvider.toggle()),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: compact ? 20 : 20, horizontal: 2),
            child: compact
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _themeProvider.isDark
                          ? _o(_t.accent, 0.2)
                          : _o(_t.orange, 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _themeProvider.isDark
                            ? _o(_t.accent, 0.45)
                            : _o(_t.orange, 0.45),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _themeProvider.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: _themeProvider.isDark
                          ? _t.accent
                          : _t.orange,
                      size: 14,
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 42,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _themeProvider.isDark
                          ? _o(_t.accent, 0.25)
                          : _o(_t.orange, 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _themeProvider.isDark
                            ? _o(_t.accent, 0.5)
                            : _o(_t.orange, 0.5),
                        width: 1,
                      ),
                    ),
                    child: Stack(children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _themeProvider.isDark
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _themeProvider.isDark
                                ? _t.accent
                                : _t.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _themeProvider.isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ]),
                  ),
          ),
        ),
        Padding(
          padding:
              EdgeInsets.only(right: compact ? 8 : 12, left: 1),
          child: GestureDetector(
            onTap: () => setState(() => _tab = 2),
            child: _buildAppBarAvatar(auth, avatarR),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAvatar(AuthProvider auth, double radius) {
    final photoUrl = _driverProfile?.profilePhotoUrl;
    Widget avatarChild;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isBase64 = !photoUrl.startsWith('http');
      avatarChild = CircleAvatar(
        radius: radius,
        backgroundColor: _o(_t.accent, 0.2),
        backgroundImage: isBase64
            ? MemoryImage(base64Decode(photoUrl))
            : NetworkImage(photoUrl) as ImageProvider,
        onBackgroundImageError: (_, __) {},
      );
    } else {
      final initial = (auth.username ?? 'D')[0].toUpperCase();
      avatarChild = CircleAvatar(
        radius: radius,
        backgroundColor: _o(_t.accent, 0.2),
        child: Text(initial,
            style: TextStyle(
                color: _t.accent,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w800)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _o(_t.accent, 0.55), width: 2),
        boxShadow: [
          BoxShadow(
              color: _o(_t.accent, 0.3),
              blurRadius: 10,
              spreadRadius: 0),
        ],
      ),
      child: avatarChild,
    );
  }

  Widget _buildAvatarWidget(
      {required double radius, required double fontSize}) {
    final photoUrl = _driverProfile?.profilePhotoUrl;
    final initial = _driverProfile?.fullName.isNotEmpty == true
        ? _driverProfile!.fullName[0].toUpperCase()
        : 'D';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isBase64 = !photoUrl.startsWith('http');
      return CircleAvatar(
        radius: radius,
        backgroundColor: _o(_t.accent, 0.2),
        backgroundImage: isBase64
            ? MemoryImage(base64Decode(photoUrl))
            : NetworkImage(photoUrl) as ImageProvider,
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _o(_t.accent, 0.2),
      child: Text(initial,
          style: TextStyle(
              color: _t.accent,
              fontWeight: FontWeight.w800,
              fontSize: fontSize)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _t.bgLight,
        border: Border(top: BorderSide(color: _t.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) {
            setState(() => _tab = i);
            if (i == 1) _loadEarnings();
            if (i == 2) _loadDriverProfile();
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: _t.accent,
          unselectedItemColor: _t.textMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            BottomNavigationBarItem(
                icon: Icon(_IC.dashboard, size: 22),
                activeIcon: Icon(Icons.map, size: 22),
                label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Stack(children: [
                  Icon(_IC.earnings, size: 22),
                  if (_activeRide != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _t.green,
                              shape: BoxShape.circle)),
                    ),
                ]),
                activeIcon:
                    Icon(Icons.account_balance_wallet, size: 22),
                label: 'Earnings'),
            BottomNavigationBarItem(
                icon: Icon(_IC.profile, size: 22),
                activeIcon: Icon(Icons.person, size: 22),
                label: 'My Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(AuthProvider auth) {
    return Column(children: [
      Container(
        color: _t.bgLight,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          _buildStatRow(),
          const SizedBox(height: 8),
          _buildStatusBanner(),
        ]),
      ),
      Expanded(child: _buildMap()),
      if (_activeRide != null)
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.48,
          ),
          child: _buildActiveRideBanner(auth),
        ),
    ]);
  }

  Widget _buildStatRow() {
    final todayEarnings = _summary?['today'] ?? 0.0;
    final allTime = _summary?['all_time'] ?? 0.0;
    final trips = _summary?['total_trips'] ?? 0;

    return Row(children: [
      Expanded(
          child: _statCard(
              icon: _IC.earnings,
              iconColor: _t.green,
              iconBg: _o(_t.green, 0.12),
              label: 'TOTAL',
              value:
                  '₱${(allTime as num).toStringAsFixed(2)}')),
      const SizedBox(width: 6),
      Expanded(
          child: _statCard(
              icon: _IC.tripCount,
              iconColor: _t.accent,
              iconBg: _o(_t.accent, 0.12),
              label: 'TRIPS',
              value: '$trips')),
      const SizedBox(width: 6),
      Expanded(
          child: _statCard(
              icon: _IC.todayEarnings,
              iconColor: _t.orange,
              iconBg: _o(_t.orange, 0.12),
              label: 'TODAY',
              value:
                  '₱${(todayEarnings as num).toStringAsFixed(2)}')),
      const SizedBox(width: 6),
      Expanded(
          child: _statCard(
              icon: _isOnline ? _IC.online : _IC.offline,
              iconColor:
                  _isOnline ? _t.green : _t.textMuted,
              iconBg: _o(
                  _isOnline ? _t.green : _t.textMuted, 0.12),
              label: 'STATUS',
              value: _isOnline ? 'ON' : 'OFF',
              valueColor:
                  _isOnline ? _t.green : _t.textMuted)),
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _t.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _t.border, width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7)),
          child:
              Center(child: Icon(icon, color: iconColor, size: 14)),
        ),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                color: valueColor ?? _t.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: TextStyle(
                color: _t.textMuted,
                fontSize: 7,
                letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _t.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _t.border, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOnline ? _t.green : _t.textMuted,
            boxShadow: _isOnline
                ? [
                    BoxShadow(
                        color: _o(_t.green, 0.5),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isOnline
                ? _activeRide != null
                    ? 'On a ride — completing delivery'
                    : 'Online — Waiting for requests…'
                : 'Go online to start accepting rides',
            style: TextStyle(color: _t.textMuted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _activeRide == null ? _toggleOnline : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _activeRide != null
                  ? _o(_t.textMuted, 0.2)
                  : _isOnline
                      ? _t.red
                      : _t.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _activeRide == null
                  ? [
                      BoxShadow(
                          color: _o(
                              _isOnline ? _t.red : _t.green, 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _activeRide != null
                    ? _IC.car
                    : _isOnline
                        ? _IC.offline
                        : _IC.online,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                _activeRide != null
                    ? 'On Ride'
                    : _isOnline
                        ? 'Go Offline'
                        : 'Go Online',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMap() {
    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _driverLocation,
          initialZoom: 15.0,
          interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.pasadanow.driver',
            maxZoom: 19,
          ),
          if (_gpsAccuracy != null)
            CircleLayer(circles: [
              CircleMarker(
                point: _driverLocation,
                radius: _gpsAccuracy!,
                useRadiusInMeter: true,
                color: _o(_t.green, 0.07),
                borderColor: _o(_t.green, 0.2),
                borderStrokeWidth: 1.0,
              ),
            ]),
          if (_routePoints.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(
                points: _routePoints,
                color: _o(Colors.black, 0.2),
                strokeWidth: 6.0,
              ),
              Polyline(
                points: _routePoints,
                color: _t.accent,
                strokeWidth: 4.0,
              ),
            ]),
          MarkerLayer(markers: [
            Marker(
              point: _driverLocation,
              width: 44,
              height: 44,
              child: _DriverMarker(
                  isOnline: _isOnline,
                  onlineColor: _t.green,
                  offlineColor: _t.textMuted),
            ),
            if (_commuterLiveLocation != null && _activeRide != null)
              Marker(
                point: _commuterLiveLocation!,
                width: 110,
                height: 52,
                alignment: Alignment.topCenter,
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _t.accent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      _PulsingDot(color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _activeRide!.passengerName.split(' ').first,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.person_pin_circle,
                      color: _t.accent, size: 22),
                ]),
              ),
            if (_activeRide != null && _activeRide!.hasValidPickup)
              Marker(
                point: _activeRide!.pickup,
                width: 100,
                height: 52,
                alignment: Alignment.topCenter,
                child: _RouteMarker(
                    color: _t.green,
                    icon: _IC.pickup,
                    label: 'Pick up'),
              ),
            if (_activeRide != null && _activeRide!.hasValidDropoff)
              Marker(
                point: _activeRide!.dropoff,
                width: 110,
                height: 52,
                alignment: Alignment.topCenter,
                child: _RouteMarker(
                    color: _t.red,
                    icon: _IC.dropoff,
                    label: 'Drop off'),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _t.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _t.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _t.accent),
                ),
                const SizedBox(width: 10),
                Text('Calculating route…',
                    style: TextStyle(
                        color: _t.textPrimary, fontSize: 12)),
              ]),
            ),
          ),
        ),
      Positioned(
        left: 10,
        top: 10,
        child: Column(children: [
          _mapBtn(
              Icons.add,
              () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1)),
          const SizedBox(height: 4),
          _mapBtn(
              Icons.remove,
              () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1)),
          const SizedBox(height: 4),
          _mapBtn(_IC.gpsOn,
              () => _mapController.move(_driverLocation, 15)),
          if (_commuterLiveLocation != null) ...[
            const SizedBox(height: 4),
            _mapBtn(Icons.fit_screen, () {
              final bounds = LatLngBounds.fromPoints(
                  [_driverLocation, _commuterLiveLocation!]);
              _mapController.fitCamera(CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60)));
            }),
          ] else if (_routePoints.isNotEmpty) ...[
            const SizedBox(height: 4),
            _mapBtn(Icons.fit_screen_outlined, () {
              final bounds =
                  LatLngBounds.fromPoints(_routePoints);
              _mapController.fitCamera(CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50)));
            }),
          ],
        ]),
      ),
      if (_isTracking && _gpsAccuracy != null)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _o(_t.mapOverlayBg, 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _t.border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _PulsingDot(color: _t.green),
                const SizedBox(width: 5),
                Text('GPS LIVE',
                    style: TextStyle(
                        color: _t.green,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ]),
              Text(
                  '±${_gpsAccuracy!.toStringAsFixed(0)}m · $_gpsAccuracyLabel',
                  style: TextStyle(
                      color: _gpsAccuracyColor, fontSize: 8)),
              Text(_gpsSpeedLabel,
                  style: TextStyle(
                      color: _t.textPrimary,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: _t.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _t.border),
                  ),
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_IC.offline,
                        color: _t.textMuted, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Go online to start\naccepting rides',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _t.textMuted,
                          fontSize: 12,
                          height: 1.5),
                    ),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text('© OpenStreetMap',
              style: TextStyle(fontSize: 7, color: Colors.black54)),
        ),
      ),
    ]);
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _o(_t.mapOverlayBg, 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _t.border),
          boxShadow: [
            BoxShadow(
                color: _o(Colors.black, 0.25), blurRadius: 4)
          ],
        ),
        child: Center(
            child: Icon(icon, color: _t.textPrimary, size: 16)),
      ),
    );
  }

  Widget _buildActiveRideBanner(AuthProvider auth) {
    final ride = _activeRide!;
    return Container(
      decoration: BoxDecoration(
        color: _t.bgLight,
        border: Border(top: BorderSide(color: _t.border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: _o(Colors.black, 0.4),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          MediaQuery.of(context).padding.bottom + 10,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            _statusPill(
                Icons.radio_button_checked, 'Active Ride', _t.green),
            const Spacer(),
            _farePill(ride.fare),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _o(_t.accent, 0.2),
              child: Text(ride.passengerName[0],
                  style: TextStyle(
                      color: _t.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(ride.passengerName,
                    style: TextStyle(
                        color: _t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Row(children: [
                  Text(
                    '${ride.distanceKm.toStringAsFixed(1)} km · ₱${ride.fare.toStringAsFixed(2)}',
                    style:
                        TextStyle(color: _t.textMuted, fontSize: 11),
                  ),
                  if (_commuterLiveLocation != null) ...[
                    const SizedBox(width: 5),
                    _PulsingDot(color: _t.accent),
                    const SizedBox(width: 3),
                    Text('Live',
                        style: TextStyle(
                            color: _t.accent, fontSize: 10)),
                  ],
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          _routeRow(_IC.pickup, _t.green, 'Pickup', ride.pickupLabel),
          const SizedBox(height: 4),
          _routeRow(
              _IC.dropoff, _t.red, 'Dropoff', ride.dropoffLabel),
          const SizedBox(height: 8),
          _fareBreakdownCard(ride),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ChatWidget(
              rideId: ride.id.toString(),
              username: auth.username ?? 'driver',
              role: 'driver',
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            if (_commuterLiveLocation != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _o(_t.accent, 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _o(_t.accent, 0.3)),
                ),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Commuter',
                      style: TextStyle(
                          color: _t.textMuted, fontSize: 9)),
                  _PulsingDot(color: _t.accent),
                  Text('Live',
                      style:
                          TextStyle(color: _t.accent, fontSize: 9)),
                ]),
              ),
            ],
            Expanded(
              child: GestureDetector(
                onTap: _loading ? null : _completeRide,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _t.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: _o(_t.green, 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2)))
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(_IC.check,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Complete Ride',
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

  Widget _fareBreakdownCard(RideRequest ride) {
    final cfg = _fareConfig;
    final multiplier = cfg.surgeEnabled ? cfg.surgeMultiplier : 1.0;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _o(_t.orange, 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _o(_t.orange, 0.2)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        _fareRow('Base fare',
            '₱${cfg.baseFare.toStringAsFixed(2)}'),
        _fareRow(
            '${ride.distanceKm.toStringAsFixed(1)} km × ₱${cfg.perKmRate.toStringAsFixed(2)}',
            '₱${(ride.distanceKm * cfg.perKmRate).toStringAsFixed(2)}'),
        if (cfg.surgeEnabled)
          _fareRow(
              'Surge (×${multiplier.toStringAsFixed(1)})',
              '+${((multiplier - 1) * 100).toStringAsFixed(0)}%',
              valueColor: _t.orange),
        if (cfg.bookingFee > 0)
          _fareRow('Booking fee',
              '₱${cfg.bookingFee.toStringAsFixed(2)}'),
      ]),
    );
  }

  Widget _fareRow(String label, String value,
          {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Flexible(
              child: Text(label,
                  style:
                      TextStyle(color: _t.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? _t.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _statusPill(IconData icon, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _o(color, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _o(color, 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _farePill(double fare) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _o(_t.orange, 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _o(_t.orange, 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_IC.license, color: _t.orange, size: 14),
        const SizedBox(width: 4),
        Text('₱${fare.toStringAsFixed(2)}',
            style: TextStyle(
                color: _t.orange,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ]),
    );
  }

  Widget _routeRow(
      IconData icon, Color color, String heading, String sub) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(heading,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
          Text(sub,
              style:
                  TextStyle(color: _t.textPrimary, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }

  Widget _buildEarningsTab() {
    return RefreshIndicator(
      color: _t.accent,
      backgroundColor: _t.card,
      onRefresh: _loadEarnings,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, 14, 14,
            MediaQuery.of(context).padding.bottom + 14),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _t.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _o(_t.accent, 0.3), width: 1),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Icon(_IC.priceChange, color: _t.accent, size: 15),
                const SizedBox(width: 6),
                Text('Current Fare Rates',
                    style: TextStyle(
                        color: _t.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_fareConfig.surgeEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _o(_t.orange, 0.15),
                      borderRadius: BorderRadius.circular(5),
                      border:
                          Border.all(color: _o(_t.orange, 0.4)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(_IC.bolt, color: _t.orange, size: 10),
                      const SizedBox(width: 2),
                      Text(
                          'SURGE ×${_fareConfig.surgeMultiplier.toStringAsFixed(1)}',
                          style: TextStyle(
                              color: _t.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 10),
              _infoRow(_IC.flag, 'Base Fare',
                  '₱${_fareConfig.baseFare.toStringAsFixed(2)}'),
              _infoRow(Icons.straighten_outlined, 'Per-km Rate',
                  '₱${_fareConfig.perKmRate.toStringAsFixed(2)}/km'),
              _infoRow(Icons.arrow_downward_outlined, 'Minimum Fare',
                  '₱${_fareConfig.minimumFare.toStringAsFixed(2)}'),
              if (_fareConfig.bookingFee > 0)
                _infoRow(_IC.receipt, 'Booking Fee',
                    '₱${_fareConfig.bookingFee.toStringAsFixed(2)}'),
              Divider(color: _t.border, height: 14),
              Text(
                  'Formula: max(₱${_fareConfig.minimumFare.toStringAsFixed(0)}, '
                  '(₱${_fareConfig.baseFare.toStringAsFixed(0)} + ₱${_fareConfig.perKmRate.toStringAsFixed(0)}×km)'
                  '${_fareConfig.surgeEnabled ? ' ×${_fareConfig.surgeMultiplier.toStringAsFixed(1)}' : ''}'
                  '${_fareConfig.bookingFee > 0 ? ' + ₱${_fareConfig.bookingFee.toStringAsFixed(0)}' : ''})',
                  style: TextStyle(
                      color: _t.textMuted,
                      fontSize: 9,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
          if (_summary != null) ...[
            Row(children: [
              Expanded(
                  child: _earningsStat(
                      _IC.todayEarnings,
                      'Today',
                      '₱${(_summary!['today'] as num).toStringAsFixed(2)}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _earningsStat(
                      Icons.emoji_events_outlined,
                      'All-time',
                      '₱${(_summary!['all_time'] as num).toStringAsFixed(2)}')),
            ]),
            const SizedBox(height: 14),
          ],
          Row(children: [
            Icon(_IC.receipt, color: _t.textPrimary, size: 16),
            const SizedBox(width: 7),
            Text('Earnings & History',
                style: TextStyle(
                    color: _t.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          if (_earnings.isEmpty)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Icon(_IC.receipt,
                      color: _t.textMuted, size: 48),
                  const SizedBox(height: 10),
                  Text('No earnings yet.',
                      style: TextStyle(
                          color: _t.textMuted, fontSize: 14)),
                ]),
              ),
            )
          else
            ..._earnings.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _t.card,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _t.border, width: 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _o(_t.green, 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(Icons.payments_outlined,
                            color: _t.green, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Text('₱${e['amount']}',
                            style: TextStyle(
                                color: _t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('Ride #${e['ride']} · ${e['date']}',
                            style: TextStyle(
                                color: _t.textMuted,
                                fontSize: 11)),
                      ]),
                    ),
                    Icon(_IC.check, color: _t.green, size: 16),
                  ]),
                )),
        ],
      ),
    );
  }

  Widget _earningsStat(
      IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _t.border, width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, color: _t.textMuted, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(color: _t.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: _t.green,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildProfileTab(AuthProvider auth) {
    final profile = _driverProfile;

    if (_profileLoading && profile == null) {
      return Center(
          child: CircularProgressIndicator(color: _t.accent));
    }

    return RefreshIndicator(
      color: _t.accent,
      backgroundColor: _t.card,
      onRefresh: _loadDriverProfile,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            color: _t.bgLight,
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
                          color: _t.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _t.bgLight, width: 2),
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
                    : auth.username ?? 'Driver',
                style: TextStyle(
                    color: _t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text('@${auth.username ?? ''}',
                  style: TextStyle(
                      color: _t.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              if (profile?.phone.isNotEmpty == true)
                Text(profile!.phone,
                    style: TextStyle(
                        color: _t.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _o(
                      _isOnline ? _t.green : _t.textMuted, 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _o(
                          _isOnline ? _t.green : _t.textMuted,
                          0.25)),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(
                    _isOnline
                        ? Icons.circle
                        : Icons.circle_outlined,
                    color:
                        _isOnline ? _t.green : _t.textMuted,
                    size: 9,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isOnline
                        ? 'Online — Accepting Rides'
                        : 'Offline',
                    style: TextStyle(
                        color: _isOnline
                            ? _t.green
                            : _t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              _profileStatBox(
                  'Total Trips',
                  (_summary?['total_trips'] ?? 0).toString(),
                  _t.accent),
              const SizedBox(width: 10),
              _profileStatBox(
                  'Today',
                  '₱${(_summary?['today'] as num? ?? 0).toStringAsFixed(2)}',
                  _t.green),
              const SizedBox(width: 10),
              _profileStatBox(
                  'All-time',
                  '₱${(_summary?['all_time'] as num? ?? 0).toStringAsFixed(2)}',
                  _t.orange),
            ]),
          ),
          const SizedBox(height: 14),
          if (_isTracking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _t.card,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _o(_t.green, 0.3)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    _PulsingDot(color: _t.green),
                    const SizedBox(width: 8),
                    Text('Live GPS Status',
                        style: TextStyle(
                            color: _t.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  _infoRow(_IC.gpsOn, 'Accuracy',
                      '±${_gpsAccuracy?.toStringAsFixed(0) ?? '—'} m ($_gpsAccuracyLabel)',
                      valueColor: _gpsAccuracyColor),
                  _infoRow(
                      _IC.speed, 'Speed', _gpsSpeedLabel),
                  _infoRow(
                    _IC.location,
                    'Position',
                    '${_driverLocation.latitude.toStringAsFixed(5)}, '
                        '${_driverLocation.longitude.toStringAsFixed(5)}',
                  ),
                  _infoRow(_IC.online, 'Push',
                      _isOnline
                          ? 'Broadcasting every 2s'
                          : 'Offline'),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildEditableSection(
              title: 'Personal Information',
              icon: _IC.badge,
              accentColor: _t.accent,
              onEdit: () => _showEditDialog(
                title: 'Edit Personal Info',
                fields: [
                  _EditField('Full Name', 'full_name',
                      profile?.fullName ?? ''),
                  _EditField('Age', 'age',
                      profile?.age ?? '',
                      keyboardType: TextInputType.number),
                  _EditField('Phone', 'phone',
                      profile?.phone ?? '',
                      keyboardType: TextInputType.phone),
                  _EditField('Email', 'email',
                      profile?.email ?? '',
                      keyboardType:
                          TextInputType.emailAddress),
                  _EditField('Address', 'address',
                      profile?.address ?? ''),
                ],
              ),
              child: Column(children: [
                _infoRow(
                    _IC.person,
                    'Full Name',
                    profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : '—'),
                _infoRow(
                    _IC.age,
                    'Age',
                    profile?.age.isNotEmpty == true
                        ? profile!.age
                        : '—'),
                _infoRow(
                    _IC.phone,
                    'Phone',
                    profile?.phone.isNotEmpty == true
                        ? profile!.phone
                        : '—'),
                _infoRow(
                    _IC.email,
                    'Email',
                    profile?.email.isNotEmpty == true
                        ? profile!.email
                        : '—'),
                _infoRow(
                    _IC.location,
                    'Address',
                    profile?.address.isNotEmpty == true
                        ? profile!.address
                        : '—'),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildEditableSection(
              title: 'Vehicle & License',
              icon: _IC.car,
              accentColor: _t.orange,
              onEdit: () => _showEditDialog(
                title: 'Edit Vehicle Info',
                fields: [
                  _EditField('Plate Number', 'plate_number',
                      profile?.plateNumber ?? ''),
                  _EditField("Driver's License No.",
                      'license_number',
                      profile?.licenseNumber ?? ''),
                  _EditField('Organization / TODA',
                      'organization',
                      profile?.organization ?? ''),
                ],
              ),
              child: Column(children: [
                _infoRow(
                    _IC.plate,
                    'Plate Number',
                    profile?.plateNumber.isNotEmpty == true
                        ? profile!.plateNumber
                        : '—'),
                _infoRow(
                    _IC.license,
                    'License No.',
                    profile?.licenseNumber.isNotEmpty == true
                        ? profile!.licenseNumber
                        : '—'),
                _infoRow(
                    _IC.org,
                    'Organization',
                    profile?.organization.isNotEmpty == true
                        ? profile!.organization
                        : '—'),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildDocumentsSection(profile),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _t.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _t.border, width: 1),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Icon(_IC.manage, color: _t.accent, size: 15),
                  const SizedBox(width: 6),
                  Text('Account Info',
                      style: TextStyle(
                          color: _t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                _infoRow(_IC.person, 'Username',
                    auth.username ?? '—'),
                _infoRow(_IC.role, 'Role', 'Driver'),
                _infoRow(
                    _IC.org,
                    'Organization',
                    profile?.organization.isNotEmpty == true
                        ? profile!.organization
                        : '—'),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: _t.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _t.border, width: 1),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _o(
                        _themeProvider.isDark
                            ? _t.accent
                            : _t.orange,
                        0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    _themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: _themeProvider.isDark
                        ? _t.accent
                        : _t.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(
                      _themeProvider.isDark
                          ? 'Dark Mode'
                          : 'Light Mode',
                      style: TextStyle(
                          color: _t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _themeProvider.isDark
                          ? 'Tap to switch to light mode'
                          : 'Tap to switch to dark mode',
                      style: TextStyle(
                          color: _t.textMuted, fontSize: 11),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _themeProvider.toggle()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _themeProvider.isDark
                          ? _t.accent
                          : _o(_t.orange, 0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(children: [
                      AnimatedAlign(
                        duration:
                            const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _themeProvider.isDark
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _themeProvider.isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: _themeProvider.isDark
                                ? _t.accent
                                : _t.orange,
                            size: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GestureDetector(
              onTap: () async {
                if (_isOnline) await _toggleOnline();
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _o(_t.red, 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _o(_t.red, 0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_IC.signOut, color: _t.red, size: 18),
                    const SizedBox(width: 7),
                    Text('Sign Out',
                        style: TextStyle(
                            color: _t.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStatBox(
          String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _t.border),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: _t.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

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
        color: _t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _t.border, width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: _t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _o(accentColor, 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _o(accentColor, 0.3)),
              ),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

  Widget _buildDocumentsSection(DriverProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _t.border, width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(_IC.folder, color: _t.orange, size: 15),
          const SizedBox(width: 6),
          Text('Credential Documents',
              style: TextStyle(
                  color: _t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        _buildDocumentRow(
          label: "Driver's License",
          photoUrl: profile?.licensePhotoUrl,
          icon: _IC.license,
          slot: _DocSlot.license,
        ),
        const SizedBox(height: 8),
        _buildDocumentRow(
          label: 'Vehicle / Plate',
          photoUrl: profile?.vehiclePhotoUrl,
          icon: _IC.car,
          slot: _DocSlot.vehicle,
        ),
        const SizedBox(height: 8),
        _buildDocumentRow(
          label: 'TODA Clearance',
          photoUrl: profile?.todaPhotoUrl,
          icon: Icons.description_outlined,
          slot: _DocSlot.toda,
        ),
      ]),
    );
  }

  Widget _buildDocumentRow({
    required String label,
    required String? photoUrl,
    required IconData icon,
    required _DocSlot slot,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isBase64 = hasPhoto && !photoUrl.startsWith('http');

    return GestureDetector(
      onTap: () => _pickAndUploadDocument(slot),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _o(hasPhoto ? _t.green : _t.textMuted, 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _o(hasPhoto ? _t.green : _t.border, 0.4),
              width: 1),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: hasPhoto
                ? (isBase64
                    ? Image.memory(base64Decode(photoUrl),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover)
                    : Image.network(photoUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _docPlaceholder(icon)))
                : _docPlaceholder(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: TextStyle(
                      color: _t.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(
                  hasPhoto
                      ? _IC.check
                      : Icons.upload_outlined,
                  size: 11,
                  color: hasPhoto ? _t.green : _t.textMuted,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    hasPhoto
                        ? 'Uploaded — tap to replace'
                        : 'Tap to upload',
                    style: TextStyle(
                        color: hasPhoto
                            ? _t.green
                            : _t.textMuted,
                        fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: _t.textMuted, size: 18),
        ]),
      ),
    );
  }

  Widget _docPlaceholder(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _o(_t.orange, 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: _t.orange, size: 24),
    );
  }

  Future<void> _pickAndUploadDocument(_DocSlot slot) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);

    final fieldKey = slot == _DocSlot.license
        ? 'photoLicense'
        : slot == _DocSlot.vehicle
            ? 'photoPlate'
            : 'photoToda';

    final success = await _updateProfile({fieldKey: base64Str});
    if (mounted) {
      _showSnack(
        success ? 'Document updated!' : 'Failed to update document.',
        success ? _t.green : _t.red,
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: _t.textMuted, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: _t.textMuted, fontSize: 12)),
          ]),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? _t.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showEditDialog({
    required String title,
    required List<_EditField> fields,
  }) {
    final controllers = {
      for (final f in fields)
        f.key: TextEditingController(text: f.initialValue)
    };
    final errors = <String, String?>{};

    String? validate(String key, String value) {
      final v = value.trim();
      switch (key) {
        case 'full_name':
        case 'fullName':
          if (v.isEmpty) return 'Full name is required.';
          if (v.length < 2) return 'Must be at least 2 characters.';
          return null;
        case 'age':
          if (v.isEmpty) return null;
          final n = int.tryParse(v);
          if (n == null) return 'Age must be a number.';
          if (n < 16 || n > 80) return 'Age must be 16–80.';
          return null;
        case 'phone':
          if (v.isEmpty) return null;
          final digits = v.replaceAll('+', '');
          if (!RegExp(r'^\d+$').hasMatch(digits) ||
              digits.length < 10)
            return 'Enter a valid phone number.';
          return null;
        case 'email':
          if (v.isEmpty) return null;
          if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(v))
            return 'Enter a valid email.';
          return null;
        case 'address':
          if (v.isEmpty) return null;
          if (v.length < 5)
            return 'Address must be at least 5 chars.';
          return null;
        default:
          return null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setSt) {
          final t = _t;
          bool saving = false;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: t.border, width: 1.5),
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Row(children: [
                    Icon(_IC.edit, color: t.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(title,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                        onTap: () => Navigator.pop(ctx2),
                        child: Icon(Icons.close,
                            color: t.textMuted, size: 20)),
                  ]),
                  const SizedBox(height: 20),
                  ...fields.map((f) {
                    final hasError = errors[f.key] != null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(f.label,
                              style: TextStyle(
                                  color: hasError
                                      ? t.red
                                      : t.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: t.bgDeep,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: hasError
                                    ? t.red
                                    : t.border,
                                width: hasError ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: controllers[f.key],
                              keyboardType: f.keyboardType,
                              style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 13),
                              cursorColor: t.accent,
                              onChanged: (_) {
                                if (errors[f.key] != null)
                                  setSt(
                                      () => errors[f.key] = null);
                              },
                              decoration: InputDecoration(
                                hintText: f.label,
                                hintStyle: TextStyle(
                                    color: t.textMuted,
                                    fontSize: 13),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 13),
                              ),
                            ),
                          ),
                          if (hasError) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.error_outline,
                                  color: t.red, size: 11),
                              const SizedBox(width: 3),
                              Text(errors[f.key]!,
                                  style: TextStyle(
                                      color: t.red,
                                      fontSize: 10)),
                            ]),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            bool hasErrors = false;
                            final newErrors =
                                <String, String?>{};
                            for (final f in fields) {
                              final err = validate(f.key,
                                  controllers[f.key]!.text);
                              if (err != null) {
                                newErrors[f.key] = err;
                                hasErrors = true;
                              }
                            }
                            if (hasErrors) {
                              setSt(() =>
                                  errors.addAll(newErrors));
                              return;
                            }
                            setSt(() => saving = true);
                            final updates = {
                              for (final f in fields)
                                f.key: controllers[f.key]!
                                    .text
                                    .trim()
                            };
                            final ok =
                                await _updateProfile(updates);
                            if (ctx2.mounted)
                              Navigator.pop(ctx2);
                            _showSnack(
                              ok
                                  ? 'Profile updated!'
                                  : 'Failed to save changes.',
                              ok ? t.green : t.red,
                            );
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: saving
                            ? _o(t.accent, 0.5)
                            : t.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: saving
                            ? null
                            : [
                                BoxShadow(
                                    color: _o(t.accent, 0.4),
                                    blurRadius: 10,
                                    offset:
                                        const Offset(0, 4))
                              ],
                      ),
                      child: saving
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(_IC.save,
                                    color: Colors.white,
                                    size: 17),
                                SizedBox(width: 7),
                                Text('Save Changes',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.w800,
                                        fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      for (final c in controllers.values) c.dispose();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIDE REQUEST BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _RideRequestSheet extends StatefulWidget {
  final RideRequest req;
  final FareConfig fareConfig;
  final DriverThemeColors themeColors;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RideRequestSheet({
    required this.req,
    required this.fareConfig,
    required this.themeColors,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<_RideRequestSheet>
    with SingleTickerProviderStateMixin {
  DriverThemeColors get t => widget.themeColors;

  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) {
        tm.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        tm.cancel();
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
    final cfg = widget.fareConfig;
    final displayFare =
        req.fare > 0 ? req.fare : cfg.computeFare(req.distanceKm);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.bgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: _o(t.green, 0.15),
                    blurRadius: 30,
                    spreadRadius: 4),
              ],
            ),
            child:
                Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                _PulsingDot(color: t.orange),
                const SizedBox(width: 8),
                Icon(_IC.car, color: t.textPrimary, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text('New Ride Request!',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                      alignment: Alignment.center,
                      children: [
                    CircularProgressIndicator(
                      value: _countdown / 30,
                      strokeWidth: 3,
                      backgroundColor: t.border,
                      color:
                          _countdown > 10 ? t.green : t.red,
                    ),
                    Text('$_countdown',
                        style: TextStyle(
                            color: _countdown > 10
                                ? t.green
                                : t.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _o(t.accent, 0.2),
                  child: Text(req.passengerName[0],
                      style: TextStyle(
                          color: t.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(req.passengerName,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    Row(children: [
                      Icon(Icons.straighten_outlined,
                          color: t.textMuted, size: 11),
                      const SizedBox(width: 2),
                      Text(
                          '${req.distanceKm.toStringAsFixed(1)} km route',
                          style: TextStyle(
                              color: t.textMuted,
                              fontSize: 11)),
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _o(t.green, 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _o(t.green, 0.35)),
                  ),
                  child: Column(children: [
                    Text('₱${displayFare.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: t.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 17)),
                    if (cfg.surgeEnabled)
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(_IC.bolt,
                            color: t.orange, size: 9),
                        Text(
                            'surge ×${cfg.surgeMultiplier.toStringAsFixed(1)}',
                            style: TextStyle(
                                color: t.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ])
                    else
                      Text('fare',
                          style: TextStyle(
                              color: t.textMuted, fontSize: 9)),
                  ]),
                ),
              ]),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.border),
                ),
                child: Column(children: [
                  _sheetFareRow(t, 'Base fare',
                      '₱${cfg.baseFare.toStringAsFixed(2)}'),
                  _sheetFareRow(
                      t,
                      '${req.distanceKm.toStringAsFixed(1)} km × ₱${cfg.perKmRate.toStringAsFixed(2)}',
                      '₱${(req.distanceKm * cfg.perKmRate).toStringAsFixed(2)}'),
                  if (cfg.surgeEnabled)
                    _sheetFareRow(
                        t,
                        'Surge ×${cfg.surgeMultiplier.toStringAsFixed(1)}',
                        '+${((cfg.surgeMultiplier - 1) * 100).toStringAsFixed(0)}%',
                        valueColor: t.orange),
                  if (cfg.bookingFee > 0)
                    _sheetFareRow(t, 'Booking fee',
                        '₱${cfg.bookingFee.toStringAsFixed(2)}'),
                  Divider(color: t.border, height: 10),
                  _sheetFareRow(
                      t,
                      'TOTAL',
                      '₱${displayFare.toStringAsFixed(2)}',
                      bold: true,
                      valueColor: t.green),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Column(children: [
                  _sheetRouteLine(t, _IC.pickup, t.green,
                      'Pickup', req.pickupLabel),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      children: List.generate(
                          3,
                          (_) => Container(
                                margin:
                                    const EdgeInsets.symmetric(
                                        vertical: 2),
                                width: 1.5,
                                height: 4,
                                color: t.border,
                              )),
                    ),
                  ),
                  _sheetRouteLine(t, _IC.dropoff, t.red,
                      'Dropoff', req.dropoffLabel),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDecline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: _o(t.red, 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _o(t.red, 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close,
                              color: t.red, size: 15),
                          const SizedBox(width: 5),
                          Text('Decline',
                              style: TextStyle(
                                  color: t.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: widget.onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: t.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _o(t.green, 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(_IC.check,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          const Text('Accept Ride',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sheetFareRow(DriverThemeColors t, String label,
      String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Flexible(
          child: Text(label,
              style: TextStyle(
                  color: bold ? t.textPrimary : t.textMuted,
                  fontSize: 11,
                  fontWeight: bold
                      ? FontWeight.w700
                      : FontWeight.normal),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(
                color: valueColor ??
                    (bold ? t.green : t.textPrimary),
                fontSize: 11,
                fontWeight: bold
                    ? FontWeight.w800
                    : FontWeight.w600)),
      ]),
    );
  }

  Widget _sheetRouteLine(DriverThemeColors t, IconData icon,
      Color color, String label, String sub) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
          Text(sub,
              style:
                  TextStyle(color: t.textPrimary, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM MAP MARKERS
// ─────────────────────────────────────────────────────────────────────────────

class _DriverMarker extends StatefulWidget {
  final bool isOnline;
  final Color onlineColor;
  final Color offlineColor;

  const _DriverMarker({
    required this.isOnline,
    required this.onlineColor,
    required this.offlineColor,
  });

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
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isOnline ? widget.onlineColor : widget.offlineColor;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: widget.isOnline ? _pulse.value : 1.0,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border:
                Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Icon(_IC.car, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _RouteMarker({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 2),
      Icon(icon, color: color, size: 26),
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
        vsync: this,
        duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
}