import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/controllers/thanh_tich_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/NguoiCuuHo/Models/chitiettinnhanmodel.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Trạng thái quyền / dịch vụ vị trí, để UI báo rõ cho cứu hộ viên.
enum LocationStatus {
  initializing,
  ok,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

/// Các mã trạng thái phân công (giữ nguyên giá trị đang dùng trên Firestore).
class RescueStatus {
  RescueStatus._();
  static const tiepNhan = 'cuuho_trangthai_phancong_tiepnhan';
  static const denNoi = 'cuuho_trangthai_phancong_daden';
  static const dangCuuHo = 'cuuho_trangthai_phancong_dangcuuho';
  static const hoanThanh = 'cuuho_trangthai_phancong_hoanthanh';
  static const daHuy = 'cuuho_trangthai_phancong_dahuy';
}

/// Báo cáo xử trí do CỨU HỘ VIÊN nhập (thay cho dữ liệu y tế điền cứng trước đây).
class RescueReport {
  final String tinhTrang; // Ổn định | Cần theo dõi | Nguy kịch
  final List<String> thaoTac;
  final String huyetAp;
  final String spo2;
  final String mach;
  final String chuyenTuyen;
  final String ghiChu;

  const RescueReport({
    required this.tinhTrang,
    this.thaoTac = const [],
    this.huyetAp = '',
    this.spo2 = '',
    this.mach = '',
    this.chuyenTuyen = '',
    this.ghiChu = '',
  });

  Map<String, dynamic> toMap() => {
    'tinhTrang': tinhTrang,
    'thaoTac': thaoTac,
    'sinhHieu': {'huyetAp': huyetAp, 'spo2': spo2, 'mach': mach},
    'chuyenTuyen': chuyenTuyen,
    'ghiChu': ghiChu,
  };

  factory RescueReport.fromMap(Map<String, dynamic> m) {
    final sh = m['sinhHieu'] is Map
        ? Map<String, dynamic>.from(m['sinhHieu'] as Map)
        : <String, dynamic>{};
    return RescueReport(
      tinhTrang: (m['tinhTrang'] ?? '').toString(),
      thaoTac: m['thaoTac'] is List
          ? (m['thaoTac'] as List).map((e) => e.toString()).toList()
          : const [],
      huyetAp: (sh['huyetAp'] ?? '').toString(),
      spo2: (sh['spo2'] ?? '').toString(),
      mach: (sh['mach'] ?? '').toString(),
      chuyenTuyen: (m['chuyenTuyen'] ?? '').toString(),
      ghiChu: (m['ghiChu'] ?? '').toString(),
    );
  }
}

class RescueProcessController extends ChangeNotifier {
  // ── Hằng số nghiệp vụ ──────────────────────────────────────────────
  /// Bán kính coi là "đã ở hiện trường". GPS điện thoại sai số 3–10 m và toạ độ
  /// geohash chỉ là tâm ô lưới, nên 2 m là không thực tế.
  static const double arrivalRadiusMeters = 50;
  static const int stepMoving = 0;
  static const int stepArrived = 1;
  static const int stepRescuing = 2;
  static const int stepCompleted = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentDoctorId;
  final String maYeuCau;
  late final String _dayKey;
  bool _disposed = false;

  /// [dayKey] phải là ngày của bản ghi phân công (trang chủ truyền vào).
  /// Nếu để trống sẽ dùng ngày hiện tại, dễ sai khi ca được giao trước 0h.
  RescueProcessController(
    this.currentDoctorId,
    this.maYeuCau, {
    String? dayKey,
  }) {
    _dayKey = dayKey ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _startTicker();
    unawaited(_init());
  }

  // ── Tiến trình ─────────────────────────────────────────────────────
  int currentStep = stepMoving;
  bool isBusy = false;
  DateTime? caStartedAt;
  DateTime? arrivedAt;
  DateTime? rescueStartedAt;
  DateTime? completedAt;
  RescueReport? report;

  /// Chỉ phần đồng hồ lắng nghe ticker này, không rebuild cả màn hình mỗi giây.
  final ValueNotifier<int> ticker = ValueNotifier<int>(0);
  Timer? _timer;

  // ── Vị trí ─────────────────────────────────────────────────────────
  GoogleMapController? mapController;
  LatLng doctorLocation = const LatLng(0.0, 0.0);
  LatLng victimLocation = const LatLng(0.0, 0.0);
  bool isVictimLocationApproximate = false;
  double? gpsAccuracyMeters;
  double currentSpeedKmH = 0.0;
  LocationStatus locationStatus = LocationStatus.initializing;
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastUploadAt;
  double? _initialStraightMeters;

  // ── Lộ trình ───────────────────────────────────────────────────────
  List<LatLng> polylineCoordinates = [];
  double? routeDistanceMeters;
  int? etaMinutes;
  bool _routeInFlight = false;
  bool _routeDirty = false;
  bool _didInitialFit = false;
  DateTime? _lastRouteAt;
  LatLng? _lastRouteFrom;

  // ── Thông tin cứu hộ viên ──────────────────────────────────────────
  String doctorName = 'Đang tải...';
  String doctorPhone = '';
  String doctorRoleId = '';
  String? doctorAvatarUrl;

  // ── Thông tin nạn nhân ─────────────────────────────────────────────
  /// true khi người báo tin hủy yêu cầu sau lúc cứu hộ viên đã nhận ca.
  bool victimCancelled = false;
  String victimUserId = '';
  String victimName = 'Đang tải...';
  String victimPhone = '';
  String victimAddress = 'Đang tải địa chỉ...';
  Map<String, dynamic>? _victimProfile;
  bool _victimProfileLoaded = false;
  LatLng? _geocodedFor;

  // ── Hiện trường ────────────────────────────────────────────────────
  ChiTietMoTaHienTruongModel? moTaHienTruongModel;
  String moTaChiTiet = 'Đang tải...';
  List<String> trieuChung = [];
  String ghiAmUrl = '';
  String hinhAnhUrl = '';

  // ── Đội ngũ ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> teamMembers = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  List<String> _assignedIds = [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _requestSub;
  Future<void> _applyChain = Future.value();

  // ── Chat ───────────────────────────────────────────────────────────
  List<ChiTietTinNhanModel> danhSachTinNhan = [];
  bool chatError = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tinNhanSub;

  // ════════════════════════════════════════════════════════════════════
  // Tham chiếu Firestore
  // ════════════════════════════════════════════════════════════════════
  DocumentReference<Map<String, dynamic>> get _assignmentRef => _firestore
      .collection('ChiTietPhanCongCuuHo')
      .doc(currentDoctorId)
      .collection('DanhSachNgay')
      .doc(_dayKey)
      .collection('DanhSachPhanCong')
      .doc(maYeuCau);

  DocumentReference<Map<String, dynamic>> get _requestRef =>
      _firestore.collection('YeuCauCuuHo').doc(maYeuCau);

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════
  // Khởi tạo
  // ════════════════════════════════════════════════════════════════════
  Future<void> _init() async {
    await Future.wait([_fetchDoctorInfo(), _restoreProgress()]);
    if (_disposed) return;
    // Ca đã hoàn thành (mở lại sau khi tắt app) thì không cần theo dõi GPS.
    if (currentStep < stepCompleted) unawaited(_startLocationTracking());

    if (maYeuCau.isEmpty) {
      victimAddress = 'Thiếu mã yêu cầu cứu hộ';
      notifyListeners();
      return;
    }
    _listenRequest();
    unawaited(_fetchChiTietMoTaHienTruong());
    _listenToTinNhan();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final doc = await _firestore
          .collection('NguoiDung')
          .doc(currentDoctorId)
          .get();
      final data = doc.data();
      if (data != null) {
        doctorName = (data['hoTen'] ?? 'Cứu hộ viên').toString();
        doctorPhone = (data['soDienThoai'] ?? '').toString();
        doctorAvatarUrl = (data['anhDaiDien'] ?? data['avatar'])?.toString();
        doctorRoleId = (data['maVaiTro'] ?? '').toString();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin cứu hộ viên: $e');
    }
  }

  /// Khôi phục tiến trình nếu app bị tắt giữa chừng.
  Future<void> _restoreProgress() async {
    if (maYeuCau.isEmpty) return;
    var docExists = false;
    try {
      final data = (await _assignmentRef.get()).data();
      DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;

      if (data != null) {
        docExists = true;
        // Nguồn sự thật là maTrangThaiTiepNhan (cùng thứ trang chủ dùng để mở
        // màn hình này). currentStep cũ còn sót từ lần chạy trước không được
        // phép kéo ca lên bước cao hơn trạng thái thực.
        final status = (data['maTrangThaiTiepNhan'] ?? '').toString();
        final maxByStatus = status == RescueStatus.hoanThanh
            ? stepCompleted
            : status == RescueStatus.dangCuuHo
            ? stepRescuing
            : status == RescueStatus.denNoi
            ? stepArrived
            : stepMoving;
        final saved = (data['currentStep'] as num?)?.toInt() ?? 0;
        currentStep = math.min(
          maxByStatus,
          math.min(stepCompleted, math.max(stepMoving, saved)),
        );
        caStartedAt = ts(data['thoiGianBatDauDiChuyen']);
        if (currentStep >= stepArrived) arrivedAt = ts(data['thoiGianDenNoi']);
        if (currentStep >= stepRescuing) {
          rescueStartedAt = ts(data['thoiGianBatDauCuuNan']);
        }
        if (currentStep >= stepCompleted) {
          completedAt = ts(data['thoiGianHoanThanh']);
          final r = data['baoCaoXuTri'];
          if (r is Map) {
            report = RescueReport.fromMap(Map<String, dynamic>.from(r));
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi khôi phục tiến trình: $e');
    }

    if (caStartedAt == null) {
      caStartedAt = DateTime.now();
      // update (không phải set) để không tạo doc "ma" khi sai đường dẫn.
      if (docExists) {
        unawaited(
          _assignmentRef
              .update({
                'thoiGianBatDauDiChuyen': Timestamp.fromDate(caStartedAt!),
              })
              .catchError((Object e) => debugPrint('Ghi mốc bắt đầu: $e')),
        );
      }
    }
    if (currentStep >= stepRescuing && rescueStartedAt == null) {
      rescueStartedAt = DateTime.now();
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════
  // GPS
  // ════════════════════════════════════════════════════════════════════
  LocationSettings get _locationSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        // Dịch vụ nền để vẫn theo dõi khi khoá màn hình.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Đang thực hiện ca cứu hộ',
          notificationText: 'Ứng dụng đang theo dõi vị trí của bạn.',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  void _setLocationStatus(LocationStatus s) {
    if (locationStatus == s) return;
    locationStatus = s;
    notifyListeners();
  }

  Future<void> retryLocation() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _setLocationStatus(LocationStatus.initializing);
    await _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationStatus(LocationStatus.serviceDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setLocationStatus(LocationStatus.permissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationStatus(LocationStatus.permissionDeniedForever);
        return;
      }

      // Vị trí gần nhất để có điểm xuất phát ngay.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _onPosition(last);
      } catch (_) {}

      if (_disposed || currentStep >= stepCompleted) return;
      await _positionSub?.cancel();
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: _locationSettings,
          ).listen(
            _onPosition,
            onError: (Object e) {
              debugPrint('Lỗi luồng GPS: $e');
              _setLocationStatus(LocationStatus.error);
            },
          );
    } catch (e) {
      debugPrint('Lỗi khởi động GPS: $e');
      _setLocationStatus(LocationStatus.error);
    }
  }

  void _onPosition(Position p) {
    doctorLocation = LatLng(p.latitude, p.longitude);
    currentSpeedKmH = (p.speed * 3.6).clamp(0.0, 120.0).toDouble();
    gpsAccuracyMeters = p.accuracy;
    locationStatus = LocationStatus.ok;
    _captureInitialDistance();
    notifyListeners();
    unawaited(fetchRealtimeRoute());
    _maybeUploadLocation();
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Chia sẻ vị trí cứu hộ viên (tối đa 1 lần / 10 giây) để điều phối và
  /// nạn nhân theo dõi được. Có thể bỏ nếu việc này đã làm ở nơi khác.
  void _maybeUploadLocation() {
    if (currentStep >= stepCompleted || maYeuCau.isEmpty) return;
    final now = DateTime.now();
    if (_lastUploadAt != null &&
        now.difference(_lastUploadAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastUploadAt = now;
    unawaited(
      _assignmentRef
          .update({
            'viTriCuuHoVien': GeoPoint(
              doctorLocation.latitude,
              doctorLocation.longitude,
            ),
            'doChinhXacGps': gpsAccuracyMeters,
            'capNhatViTriLuc': FieldValue.serverTimestamp(),
          })
          .catchError((Object e) => debugPrint('Gửi vị trí: $e')),
    );
  }

  // ── Khoảng cách ────────────────────────────────────────────────────
  bool get hasDoctorLocation => doctorLocation.latitude != 0.0;
  bool get hasVictimLocation => victimLocation.latitude != 0.0;

  double? get distanceToVictimMeters {
    if (!hasDoctorLocation || !hasVictimLocation) return null;
    return Geolocator.distanceBetween(
      doctorLocation.latitude,
      doctorLocation.longitude,
      victimLocation.latitude,
      victimLocation.longitude,
    );
  }

  bool get isNearVictim =>
      (distanceToVictimMeters ?? double.infinity) <= arrivalRadiusMeters;

  void _captureInitialDistance() {
    _initialStraightMeters ??= distanceToVictimMeters;
  }

  /// 0..1: mức đã tiến gần nạn nhân so với lúc bắt đầu.
  double? get approachProgress {
    final initial = _initialStraightMeters;
    final now = distanceToVictimMeters;
    if (initial == null || now == null || initial < 1) return null;
    return ((initial - now) / initial).clamp(0.0, 1.0).toDouble();
  }

  static String formatMeters(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

  String get remainingDistanceText {
    final straight = distanceToVictimMeters;
    if (straight == null) return '--';
    if (routeDistanceMeters != null && straight > 100) {
      return formatMeters(routeDistanceMeters!);
    }
    return formatMeters(straight);
  }

  String get etaText {
    if (isNearVictim) return 'Bạn đã ở gần hiện trường';
    if (etaMinutes == null) return 'Đang tính lộ trình…';
    return 'Dự kiến đến sau khoảng $etaMinutes phút';
  }

  // ════════════════════════════════════════════════════════════════════
  // Lộ trình OSRM
  // ════════════════════════════════════════════════════════════════════
  Future<void> fetchRealtimeRoute({bool force = false}) async {
    if (_disposed || currentStep != stepMoving) return;
    if (!hasDoctorLocation || !hasVictimLocation) return;
    if (_routeInFlight) {
      if (force) _routeDirty = true;
      return;
    }

    final now = DateTime.now();
    if (!force && _lastRouteAt != null && _lastRouteFrom != null) {
      final moved = Geolocator.distanceBetween(
        _lastRouteFrom!.latitude,
        _lastRouteFrom!.longitude,
        doctorLocation.latitude,
        doctorLocation.longitude,
      );
      if (now.difference(_lastRouteAt!) < const Duration(seconds: 8) ||
          moved < 20) {
        return;
      }
    }

    _routeInFlight = true;
    _lastRouteAt = now;
    _lastRouteFrom = doctorLocation;
    try {
      // Server demo công cộng của OSRM: khi chạy thật hãy dùng server riêng.
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${doctorLocation.longitude},${doctorLocation.latitude};'
        '${victimLocation.longitude},${victimLocation.latitude}'
        '?overview=full&geometries=polyline',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (_disposed) return;
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final data = jsonDecode(res.body);
      final routes = data['routes'];
      if (data['code'] == 'Ok' && routes is List && routes.isNotEmpty) {
        final route = routes[0];
        final decoded = PolylinePoints.decodePolyline(
          route['geometry'] as String,
        );
        polylineCoordinates = decoded
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        routeDistanceMeters = (route['distance'] as num).toDouble();
        etaMinutes = ((route['duration'] as num).toDouble() / 60).ceil();
        notifyListeners();
        if (!_didInitialFit) _didInitialFit = fitMapBounds();
      }
    } catch (e) {
      debugPrint('Lỗi lấy tuyến đường OSRM: $e');
      if (polylineCoordinates.isEmpty &&
          hasDoctorLocation &&
          hasVictimLocation) {
        polylineCoordinates = [doctorLocation, victimLocation];
        notifyListeners();
      }
    } finally {
      _routeInFlight = false;
      if (_routeDirty && !_disposed) {
        _routeDirty = false;
        unawaited(fetchRealtimeRoute(force: true));
      }
    }
  }

  /// Trả về true nếu đã điều khiển được camera.
  bool fitMapBounds() {
    final map = mapController;
    if (map == null || !hasDoctorLocation || !hasVictimLocation) return false;
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(doctorLocation.latitude, victimLocation.latitude),
        math.min(doctorLocation.longitude, victimLocation.longitude),
      ),
      northeast: LatLng(
        math.max(doctorLocation.latitude, victimLocation.latitude),
        math.max(doctorLocation.longitude, victimLocation.longitude),
      ),
    );
    try {
      unawaited(
        map
            .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80))
            .catchError((Object _) {}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void focusVictim() {
    final map = mapController;
    if (map == null || !hasVictimLocation) return;
    try {
      unawaited(
        map
            .animateCamera(CameraUpdate.newLatLngZoom(victimLocation, 18))
            .catchError((Object _) {}),
      );
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════
  // Yêu cầu cứu hộ: nạn nhân + đội ngũ (realtime)
  // ════════════════════════════════════════════════════════════════════
  void _listenRequest() {
    _requestSub?.cancel();
    _requestSub = _requestRef.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      // Xếp hàng xử lý để các snapshot không chạy chồng nhau.
      _applyChain = _applyChain.then((_) => _applyRequestData(data));
    }, onError: (Object e) => debugPrint('Lỗi lắng nghe YeuCauCuuHo: $e'));
  }

  LatLng? _parseLocation(Map<String, dynamic> d) {
    final lat = d['viDo'];
    final lng = d['kinhDo'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    final gh = (d['geoHash'] ?? d['geohash'])?.toString();
    if (gh != null && gh.isNotEmpty) {
      try {
        final g = GeoHash(gh);
        return LatLng(g.latitude(), g.longitude());
      } catch (_) {}
    }
    return null;
  }

  Future<void> _applyRequestData(Map<String, dynamic> data) async {
    try {
      victimCancelled =
          (data['maTinhTrangYeuCau'] ?? '').toString() ==
          'user_tinhtrang_dahuy';

      final uid = (data['maNguoiYeuCau'] ?? data['maNguoiDung'] ?? '')
          .toString();
      if (uid.isNotEmpty) {
        victimUserId = uid;
        if (!_victimProfileLoaded) {
          final u = await _firestore.collection('NguoiDung').doc(uid).get();
          _victimProfileLoaded = true;
          final p = u.data();
          if (p != null) {
            _victimProfile = p;
            victimName = (p['hoTen'] ?? 'Nạn nhân').toString();
            victimPhone = (p['soDienThoai'] ?? '').toString();
          }
        }
      }

      // Ưu tiên toạ độ chính xác (viDo/kinhDo), sau đó geohash.
      var loc = _parseLocation(data);
      var approximate = false;
      if (loc == null && _victimProfile != null) {
        // Vị trí trong hồ sơ người dùng có thể đã cũ → đánh dấu gần đúng.
        loc = _parseLocation(_victimProfile!);
        approximate = loc != null;
      }
      isVictimLocationApproximate = approximate;
      if (loc != null) victimLocation = loc;
      _captureInitialDistance();
      notifyListeners();
      unawaited(fetchRealtimeRoute(force: true));

      await _updateTeam(data);

      if (loc != null) {
        final moved = _geocodedFor == null
            ? double.infinity
            : Geolocator.distanceBetween(
                _geocodedFor!.latitude,
                _geocodedFor!.longitude,
                loc.latitude,
                loc.longitude,
              );
        if (moved > 30) {
          _geocodedFor = loc;
          victimAddress = await getAddressFromLatLng(
            loc.latitude,
            loc.longitude,
          );
          notifyListeners();
        }
      } else {
        victimAddress = 'Không xác định được tọa độ vị trí';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi xử lý dữ liệu yêu cầu: $e');
    }
  }

  String _roleLabelOf(dynamic maVaiTro) {
    switch (maVaiTro?.toString()) {
      case 'vaitro_cuuhococc':
        return 'Cứu hộ viên có CCHN';
      default:
        return 'Cứu hộ viên';
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case RescueStatus.tiepNhan:
        return 'Đã nhận ca';
      case RescueStatus.denNoi:
        return 'Đã đến nơi';
      case RescueStatus.dangCuuHo:
        return 'Đang cứu nạn';
      case RescueStatus.hoanThanh:
        return 'Hoàn thành';
      case RescueStatus.daHuy:
        return 'Đã hủy';
      case 'cuuho_trangthai_phancong_tuchoi':
        return 'Đã từ chối';
      default:
        return 'Đang chờ';
    }
  }

  Future<void> _updateTeam(Map<String, dynamic> data) async {
    final raw = data['danhSachPhanCongVien'];
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    _assignedIds = map.keys.toList();

    final list = <Map<String, dynamic>>[];
    for (final id in map.keys) {
      if (id == currentDoctorId) continue;
      var user = _userCache[id];
      if (user == null) {
        try {
          user = (await _firestore.collection('NguoiDung').doc(id).get())
              .data();
          if (user != null) _userCache[id] = user;
        } catch (_) {}
      }
      if (user == null) continue;
      list.add({
        'id': id,
        'name': (user['hoTen'] ?? 'Cứu hộ viên').toString(),
        'role':
            (user['chuyenKhoa'] ??
                    user['vaiTro'] ??
                    _roleLabelOf(user['maVaiTro']))
                .toString(),
        'phone': (user['soDienThoai'] ?? '').toString(),
        'status': _statusLabel(map[id]?.toString()),
      });
    }
    teamMembers = list;
    notifyListeners();
  }

  /// Tên hiển thị của người gửi tin nhắn.
  String senderLabel(String id) {
    if (id == currentDoctorId) return 'Bạn';
    if (id == victimUserId) return victimName;
    for (final m in teamMembers) {
      if (m['id'] == id) return m['name'].toString();
    }
    return 'Điều phối';
  }

  // ════════════════════════════════════════════════════════════════════
  // Hiện trường
  // ════════════════════════════════════════════════════════════════════
  Future<void> _fetchChiTietMoTaHienTruong() async {
    try {
      final doc = await _firestore
          .collection('ChiTietMoTaHienTruong')
          .doc(maYeuCau)
          .get();
      final data = doc.data();
      if (data == null) {
        moTaChiTiet = 'Chưa có mô tả chi tiết';
        notifyListeners();
        return;
      }
      moTaHienTruongModel = ChiTietMoTaHienTruongModel.fromMap(data, doc.id);

      final ghiChu = data['ghiChuText'];
      if (ghiChu is Map) {
        moTaChiTiet = (ghiChu['moTaChiTiet'] ?? 'Chưa có mô tả chi tiết')
            .toString();
        final tc = ghiChu['trieuChung'];
        if (tc is List) trieuChung = tc.map((e) => e.toString()).toList();
      } else {
        moTaChiTiet = 'Chưa có mô tả chi tiết';
      }
      ghiAmUrl = (data['ghiAmUrl'] ?? '').toString();
      // Trường 'videoUrl' trên Firestore thực chất chứa URL ảnh.
      hinhAnhUrl = (data['videoUrl'] ?? '').toString();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải ChiTietMoTaHienTruong: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Chat
  // ════════════════════════════════════════════════════════════════════
  void _listenToTinNhan() {
    _tinNhanSub?.cancel();
    _tinNhanSub = _firestore
        .collection('ChiTietTinNhan')
        .where('maPhongChat', isEqualTo: maYeuCau)
        .orderBy('thoiGianGui', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            chatError = false;
            danhSachTinNhan = snapshot.docs
                .map((d) => ChiTietTinNhanModel.fromMap(d.data(), d.id))
                .toList();
            notifyListeners();
          },
          onError: (Object e) {
            // Thường do thiếu composite index (maPhongChat + thoiGianGui):
            // Firebase in kèm đường dẫn tạo index trong log.
            debugPrint('Lỗi stream tin nhắn: $e');
            chatError = true;
            notifyListeners();
          },
        );
  }

  Future<void> guiTinNhan(String noiDung) async {
    if (noiDung.trim().isEmpty) return;
    try {
      final msg = ChiTietTinNhanModel(
        maTinNhan: '',
        maPhongChat: maYeuCau,
        maNguoiGui: currentDoctorId,
        noiDung: noiDung.trim(),
        loaiTinNhan: 'text',
        thoiGianGui: DateTime.now(),
      );
      unawaited(
        _firestore
            .collection('ChiTietTinNhan')
            .add(msg.toMap())
            .then((_) {})
            .catchError((Object e) => debugPrint('Lỗi gửi tin nhắn: $e')),
      );
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Chuyển bước (có khoá chống bấm đúp, cập nhật lạc quan)
  // ════════════════════════════════════════════════════════════════════
  /// Ghi trạng thái đồng thời vào bản ghi phân công và vào map của yêu cầu.
  /// Dùng khoá lồng nhau + merge nên không ghi đè trạng thái của đồng đội.
  Future<void> _writeStatus(String status, Map<String, dynamic> extra) {
    final batch = _firestore.batch();
    batch.set(_assignmentRef, {
      ...extra,
      'maTrangThaiTiepNhan': status,
    }, SetOptions(merge: true));
    batch.set(_requestRef, {
      'danhSachPhanCongVien': {currentDoctorId: status},
    }, SetOptions(merge: true));
    return batch.commit();
  }

  Future<void> _safe(String label, Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      debugPrint('$label: $e');
    }
  }

  Future<bool> _advance(
    int to,
    String status,
    Map<String, dynamic> extra,
  ) async {
    if (isBusy || currentStep != to - 1) return false;
    isBusy = true;
    final now = DateTime.now();
    currentStep = to;
    if (to == stepArrived) {
      arrivedAt = now;
      polylineCoordinates = [];
      routeDistanceMeters = null;
    }
    if (to == stepRescuing) {
      rescueStartedAt = now;
      ticker.value++;
    }
    notifyListeners();

    try {
      await _writeStatus(status, {'currentStep': to, ...extra}).timeout(
        const Duration(seconds: 4),
        // Mất mạng: Firestore giữ hàng đợi và tự đồng bộ khi có lại mạng.
        onTimeout: () =>
            debugPrint('Ghi trạng thái chậm (có thể đang offline).'),
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật bước: $e');
    }
    isBusy = false;
    notifyListeners();
    return true;
  }

  /// Xác nhận đã đến nơi. Nếu còn ngoài bán kính, hệ thống ghi nhận là xác nhận thủ công.
  Future<bool> confirmArrival() {
    final d = distanceToVictimMeters;
    return _advance(stepArrived, RescueStatus.denNoi, {
      'thoiGianDenNoi': Timestamp.fromDate(DateTime.now()),
      'xacNhanThuCong': d == null || d > arrivalRadiusMeters,
      'khoangCachKhiXacNhanM': d?.round(),
    });
  }

  Future<bool> startRescue() => _advance(stepRescuing, RescueStatus.dangCuuHo, {
    'thoiGianBatDauCuuNan': Timestamp.fromDate(DateTime.now()),
  });

  Future<bool> completeMission(RescueReport r) async {
    if (isBusy || currentStep != stepRescuing) return false;
    isBusy = true;
    final now = DateTime.now();
    completedAt = now;
    report = r;
    currentStep = stepCompleted;
    _stopTracking();
    notifyListeners();

    try {
      await _completeRemote(r, now).timeout(
        const Duration(seconds: 6),
        onTimeout: () =>
            debugPrint('Hoàn thành ca: đang đồng bộ nền (offline?).'),
      );
    } catch (e) {
      debugPrint('Lỗi hoàn thành ca: $e');
    }
    isBusy = false;
    notifyListeners();
    return true;
  }

  Future<void> _completeRemote(RescueReport r, DateTime now) async {
    // Tránh cộng thống kê hai lần nếu ca đã được đánh dấu hoàn thành.
    var alreadyDone = false;
    try {
      final data = (await _assignmentRef.get()).data();
      alreadyDone = data?['maTrangThaiTiepNhan'] == RescueStatus.hoanThanh;
    } catch (_) {}

    // Phát các lệnh ghi cùng lúc: Firestore xếp hàng offline theo thứ tự.
    await Future.wait([
      _safe(
        'status',
        () => _writeStatus(RescueStatus.hoanThanh, {
          'currentStep': stepCompleted,
          'thoiGianHoanThanh': Timestamp.fromDate(now),
          'thoiGianCanThiepGiay': rescueElapsedSeconds,
          'tongThoiGianCaGiay': totalCaSeconds,
          'baoCaoXuTri': r.toMap(),
        }),
      ),
      if (!alreadyDone) ...[
        _safe('stats', () => _capNhatThongKeHoSo('soLuongCaHoanThanh')),

        // THÊM ĐOẠN CODE NÀY VÀO ĐÂY:
        _safe('thanh_tich', () async {
          final thanhTichService = ThanhTichService(firestore: _firestore);
          await thanhTichService.ghiNhanCaHoanThanh(currentDoctorId, maYeuCau);
        }),
      ],
      _safe('record', () => _saveRescueRecord(r, now)),
      _safe('release', releaseRescueDuty),
    ]);
  }

  /// Hủy ca ở bước 1 (di chuyển) hoặc bước 2 (đã đến nơi), có ghi lý do.
  Future<bool> cancelCase({required String reason, String note = ''}) async {
    if (isBusy || currentStep > stepArrived) return false;
    isBusy = true;
    notifyListeners();
    _stopTracking();

    Future<void> remote() async {
      var alreadyCancelled = false;
      try {
        final data = (await _assignmentRef.get()).data();
        alreadyCancelled = data?['maTrangThaiTiepNhan'] == RescueStatus.daHuy;
      } catch (_) {}
      await Future.wait([
        _safe(
          'status',
          () => _writeStatus(RescueStatus.daHuy, {
            'lyDoHuy': reason,
            'ghiChuHuy': note,
            'thoiGianHuy': Timestamp.fromDate(DateTime.now()),
            'buocKhiHuy': currentStep,
          }),
        ),
        if (!alreadyCancelled)
          _safe('stats', () => _capNhatThongKeHoSo('soLuongDaKhongNhan')),
        _safe('release', releaseRescueDuty),
      ]);
    }

    try {
      await remote().timeout(
        const Duration(seconds: 6),
        onTimeout: () => debugPrint('Hủy ca: đang đồng bộ nền (offline?).'),
      );
    } catch (e) {
      debugPrint('Lỗi hủy ca: $e');
    }
    isBusy = false;
    notifyListeners();
    return true;
  }

  Future<void> releaseRescueDuty() async {
    await _firestore.collection('NguoiDung').doc(currentDoctorId).update({
      'nhanCaCuuHo': false,
    });
  }

  /// Gợi ý: chuyển việc tăng thống kê sang Cloud Function để tránh gian lận
  /// và đảm bảo idempotent (client hiện chỉ chống trùng ở mức cơ bản).
  Future<void> _capNhatThongKeHoSo(String fieldName) async {
    if (currentDoctorId.isEmpty) return;
    var role = doctorRoleId;
    if (role.isEmpty) {
      final doc = await _firestore
          .collection('NguoiDung')
          .doc(currentDoctorId)
          .get();
      role = (doc.data()?['maVaiTro'] ?? '').toString();
    }

    String target = '';
    if (role == 'vaitro_cuuhococc') {
      target = 'HoSoCuuHoCoCCHN';
    } else if (role == 'vaitro_cuhochuacocc' ||
        role == 'vaitro_cuhokhongcocc') {
      target = 'HoSoCuuHoKhongCCHN';
    }
    if (target.isEmpty) return;

    await _firestore.collection(target).doc(currentDoctorId).set({
      fieldName: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> _saveRescueRecord(RescueReport r, DateTime now) async {
    final solo = teamMembers.isEmpty;
    final data = <String, dynamic>{
      'maCuuHo': maYeuCau,
      'maNanNhan': victimUserId,
      'tenNanNhan': victimName,
      'soDienThoaiNanNhan': victimPhone,
      'diaChiSuCo': victimAddress,
      // arrayUnion: mỗi người chỉ thêm chính mình, không ghi đè danh sách.
      'DanhSachCuuHoVien': FieldValue.arrayUnion([currentDoctorId]),
      // Báo cáo của riêng từng cứu hộ viên (không bị người hoàn thành sau ghi đè).
      'chiTietTheoCuuHoVien': {
        currentDoctorId: {
          'ten': doctorName,
          'maVaiTro': doctorRoleId,
          'tongThoiGianGiay': totalCaSeconds,
          'thoiGianCanThiepGiay': rescueElapsedSeconds,
          'baoCaoXuTri': r.toMap(),
          'thoiGianHoanThanh': Timestamp.fromDate(now),
        },
      },
      // Các khoá dưới đây giữ lại để màn hình lịch sử cũ vẫn đọc được;
      // nội dung nay là DỮ LIỆU THẬT do cứu hộ viên nhập.
      'tomTatXuTri': r.thaoTac,
      'sinhHieu': {
        'huyetAp': r.huyetAp,
        'spo2': r.spo2,
        'mach': r.mach,
        'trangThai': r.tinhTrang,
      },
      'tongThoiGianGiay': totalCaSeconds,
      'tongThoianGiay': totalCaSeconds, // khoá cũ bị gõ sai, bỏ khi đã migrate
      'tongThoiGianHienThi': formattedTotalTime,
      'xacNhanHoanThanh': {
        'maNguoiXacNhan': currentDoctorId,
        'thoiGian': FieldValue.serverTimestamp(),
      },
      'thoiGianHoanThanh': FieldValue.serverTimestamp(),
    };
    if (r.chuyenTuyen.isNotEmpty) data['benhVienChuyenTuyen'] = r.chuyenTuyen;
    if (solo) {
      data['bacSiPhuTrach'] = doctorName;
      data['maBacSiPhuTrach'] = currentDoctorId;
    }
    await _firestore
        .collection('HoSoCuuHo')
        .doc(maYeuCau)
        .set(data, SetOptions(merge: true));
  }

  // ════════════════════════════════════════════════════════════════════
  // Thời gian (tính theo đồng hồ thực, không đếm tick)
  // ════════════════════════════════════════════════════════════════════
  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (currentStep == stepRescuing) ticker.value++;
    });
  }

  int get rescueElapsedSeconds {
    final s = rescueStartedAt;
    if (s == null) return 0;
    final end = completedAt ?? DateTime.now();
    return math.max(0, end.difference(s).inSeconds);
  }

  int get totalCaSeconds {
    final s = caStartedAt;
    if (s == null) return 0;
    final end = completedAt ?? DateTime.now();
    return math.max(0, end.difference(s).inSeconds);
  }

  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedRescueTime => formatDuration(rescueElapsedSeconds);
  String get formattedTotalTime => formatDuration(totalCaSeconds);

  // ════════════════════════════════════════════════════════════════════
  // Hiển thị thông tin cứu hộ viên
  // ════════════════════════════════════════════════════════════════════
  bool get doctorHasLicense => doctorRoleId == 'vaitro_cuuhococc';
  String get doctorRoleLabel => _roleLabelOf(doctorRoleId);

  String get doctorInitials {
    final parts = doctorName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.last.isEmpty) return 'CH';
    return parts.last.substring(0, 1).toUpperCase();
  }

  // ════════════════════════════════════════════════════════════════════
  // Tiện ích ngoài ứng dụng
  // ════════════════════════════════════════════════════════════════════
  Future<void> makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    try {
      // Android 11+: cần khai báo <queries> cho scheme "tel" trong manifest.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi khi gọi điện: $e');
    }
  }

  Future<void> openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi mở liên kết: $e');
    }
  }

  /// Mở ứng dụng bản đồ để chỉ đường từng chặng đến nạn nhân.
  Future<void> openExternalNavigation() async {
    if (!hasVictimLocation) return;
    await openUrl(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${victimLocation.latitude},${victimLocation.longitude}'
      '&travelmode=driving',
    );
  }

  /// Reverse geocoding bằng Nominatim (OpenStreetMap).
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0 || lat.isNaN || lng.isNaN) {
      return 'Đang định vị...';
    }
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json'
      '&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=vi',
    );
    try {
      final res = await http
          .get(
            url,
            headers: {
              'User-Agent': 'CuuHoKhanCapApp/1.0 (contact@cuhokhancap.com)',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null && data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (e) {
      debugPrint('Lỗi Reverse Geocoding OSM: $e');
    }
    return 'Vị trí sự cố (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
  }

  // ════════════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _positionSub?.cancel();
    _requestSub?.cancel();
    _tinNhanSub?.cancel();
    ticker.dispose();
    // mapController do widget GoogleMap tự giải phóng, không dispose ở đây.
    super.dispose();
  }
}
