import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Giai đoạn của lời mời nhận ca. UI chỉ cần lắng nghe giá trị này để điều hướng.
enum AlertPhase {
  waiting, // đang chờ cứu hộ viên phản hồi
  accepting, // đang ghi nhận tiếp nhận
  accepted, // đã nhận → sang màn hình tiến trình
  rejected, // cứu hộ viên chủ động từ chối
  expired, // hết thời gian phản hồi
  cancelledByVictim, // người báo tin hủy yêu cầu
  reassigned, // ca không còn chờ bạn (đã phân công lại / đã nhận bởi hệ thống)
  full, // ca đã đủ số cứu hộ viên tiếp nhận (tối đa AlertStatus.soCuuHoToiDa)
}

enum AcceptResult { success, notAvailable, full, error }

class _NotAvailable implements Exception {}

class _TeamFull implements Exception {}

class AlertStatus {
  AlertStatus._();
  static const choTiepNhan = 'cuuho_trangthai_phancong_chotiepnhan';
  static const tiepNhan = 'cuuho_trangthai_phancong_tiepnhan';
  static const daDen = 'cuuho_trangthai_phancong_daden';
  static const tuChoi = 'cuuho_trangthai_phancong_tuchoi';
  static const daHuy = 'cuuho_trangthai_phancong_dahuy';
  static const yeuCauDaHuy = 'user_tinhtrang_dahuy';

  /// Số cứu hộ viên tối đa được tiếp nhận cho một ca.
  static const int soCuuHoToiDa = 3;

  /// Trạng thái trong YeuCauCuuHo.danhSachPhanCongVien được tính là "đã vào đội".
  /// Muốn tính cả người đang cứu nạn thì thêm 'cuuho_trangthai_phancong_dangcuuho'.
  static const List<String> tinhVaoSoLuong = [tiepNhan, daDen];
}

class EmergencyAlertController extends ChangeNotifier {
  static const int totalSeconds = 180;

  // Tốc độ trung bình ước tính trong đô thị (km/h). OSRM demo công cộng chỉ
  // có dữ liệu ô tô và bỏ qua profile xe, nên thời gian được ước tính từ quãng đường.
  static const double _motoKmH = 30;
  static const double _carKmH = 25;
  static const double _walkKmH = 4.5;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _disposed = false;

  // ── Định danh ──────────────────────────────────────────────────────
  String currentDoctorId = '';
  String currentMaYeuCau = '';
  String _assignmentDocId = '';
  String _expectedMaYeuCau = '';
  late String _dayKey;

  // ── Giai đoạn & đếm ngược ──────────────────────────────────────────
  AlertPhase phase = AlertPhase.waiting;
  bool _processed = false;
  bool isSoundOn = false;
  DateTime? _deadline;
  Timer? _timer;
  final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(totalSeconds);

  // ── Cứu hộ viên ────────────────────────────────────────────────────
  String doctorName = 'Cứu hộ viên';
  String doctorRoleId = '';
  String? doctorAvatarUrl;

  // ── Vị trí ─────────────────────────────────────────────────────────
  LatLng myLocation = const LatLng(0.0, 0.0);
  bool isMyLocationApproximate = false;
  bool hasGpsFix = false;
  String? locationWarning;
  LatLng victimLocation = const LatLng(0.0, 0.0);
  bool isVictimLocationApproximate = false;
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionSub;

  // ── Lộ trình ───────────────────────────────────────────────────────
  List<LatLng> polylineCoordinates = [];
  double? routeDistanceMeters;
  bool isLoadingRoute = false;
  bool _routeInFlight = false;
  bool _routeDirty = false;
  bool _didInitialFit = false;
  DateTime? _lastRouteAt;
  LatLng? _lastRouteFrom;
  String selectedTravelMode = 'moto'; // moto | car | walk

  // ── Ca cứu hộ ──────────────────────────────────────────────────────
  int mucDoKhanCap = 1;
  String address = 'Đang tải địa chỉ...';
  String victimName = 'Đang tải...';
  String victimPhone = '';
  Map<String, dynamic>? _victimProfile;
  bool _victimProfileLoaded = false;
  LatLng? _geocodedFor;
  Future<void> _applyChain = Future.value();

  // Mô tả hiện trường (chỉ hiển thị khi người báo tin thực sự gửi)
  String moTaChiTiet = '';
  List<String> trieuChung = [];
  String ghiAmUrl = '';
  String hinhAnhUrl = '';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _assignmentSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _requestSub;

  EmergencyAlertController() {
    _startLocationTracking();
  }

  // ════════════════════════════════════════════════════════════════════
  // Tham chiếu Firestore
  // ════════════════════════════════════════════════════════════════════
  DocumentReference<Map<String, dynamic>> get _assignmentRef => _firestore
      .collection('ChiTietPhanCongCuuHo')
      .doc(currentDoctorId)
      .collection('DanhSachNgay')
      .doc(_dayKey)
      .collection('DanhSachPhanCong')
      .doc(_assignmentDocId);

  DocumentReference<Map<String, dynamic>> get _requestRef =>
      _firestore.collection('YeuCauCuuHo').doc(currentMaYeuCau);

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('NguoiDung').doc(currentDoctorId);

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════
  // Bắt đầu lắng nghe lời mời
  // ════════════════════════════════════════════════════════════════════
  /// [expectedMaYeuCau] rỗng: lấy ca đang chờ đầu tiên; có giá trị: chỉ lấy đúng ca đó.
  void start(String currentUserId, {String expectedMaYeuCau = ''}) {
    currentDoctorId = currentUserId;
    _expectedMaYeuCau = expectedMaYeuCau;
    _dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    unawaited(_run());
  }

  Future<void> _run() async {
    await _fetchDoctorInfo();
    if (_disposed) return;
    _assignmentSub?.cancel();
    _assignmentSub = _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(currentDoctorId)
        .collection('DanhSachNgay')
        .doc(_dayKey)
        .collection('DanhSachPhanCong')
        .snapshots()
        .listen(
          _onAssignmentSnapshot,
          onError: (Object e) => debugPrint('Lỗi lắng nghe phân công: $e'),
        );
  }

  bool _isPending(Map<String, dynamic> data) {
    final s = (data['maTrangThaiTiepNhan'] ?? '').toString();
    return s == AlertStatus.choTiepNhan || s.isEmpty;
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _pick(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_processed) {
      for (final d in docs) {
        if (d.id == _assignmentDocId) return d;
      }
      return null;
    }
    for (final d in docs) {
      final data = d.data();
      final caseId = (data['maYeuCau'] ?? '').toString().isNotEmpty
          ? data['maYeuCau'].toString()
          : d.id;
      if (_expectedMaYeuCau.isNotEmpty &&
          caseId != _expectedMaYeuCau &&
          d.id != _expectedMaYeuCau) {
        continue;
      }
      if (_isPending(data)) return d;
    }
    return null;
  }

  void _onAssignmentSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    if (_disposed) return;
    final doc = _pick(snap.docs);

    if (!_processed) {
      if (doc != null) _beginCase(doc);
      return;
    }
    // Đang chờ mà bản ghi biến mất hoặc không còn "chờ tiếp nhận" do bên khác
    // (điều phối phân công lại…) → báo cho UI.
    if (phase == AlertPhase.waiting &&
        (doc == null || !_isPending(doc.data()))) {
      _finish(AlertPhase.reassigned);
    }
  }

  void _beginCase(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    _processed = true;
    _assignmentDocId = doc.id;
    currentMaYeuCau = (data['maYeuCau'] ?? '').toString().isNotEmpty
        ? data['maYeuCau'].toString()
        : doc.id;

    _startCountdown();
    unawaited(_playAlert());
    unawaited(_recordDispatched(data));
    _listenRequest();
    unawaited(_fetchFieldDetails());
    notifyListeners();
  }

  /// Chỉ tính "ca được phát" một lần cho mỗi ca (kể cả khi mở lại màn hình).
  Future<void> _recordDispatched(Map<String, dynamic> data) async {
    if (data['daTinhCaDuocPhat'] == true) return;
    try {
      await _assignmentRef.set({
        'daTinhCaDuocPhat': true,
      }, SetOptions(merge: true));
      await _capNhatThongKeHoSo('soLuongCaDuocPhat');
    } catch (e) {
      debugPrint('Lỗi ghi nhận ca được phát: $e');
    }
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final doc = await _firestore
          .collection('NguoiDung')
          .doc(currentDoctorId)
          .get();
      final data = doc.data();
      if (data == null) return;
      doctorName = (data['hoTen'] ?? 'Cứu hộ viên').toString();
      doctorRoleId = (data['maVaiTro'] ?? '').toString();
      doctorAvatarUrl = (data['anhDaiDien'] ?? data['avatar'])?.toString();

      // Chỉ dùng vị trí trong hồ sơ khi chưa có GPS, và đánh dấu là gần đúng.
      if (!hasGpsFix && myLocation.latitude == 0.0) {
        final loc = _parseLocation(data);
        if (loc != null) {
          myLocation = loc;
          isMyLocationApproximate = true;
        }
      }
      notifyListeners();
      unawaited(fetchRealtimeRoute(force: true));
    } catch (e) {
      debugPrint('Lỗi đọc thông tin cứu hộ viên: $e');
    }
  }

  bool get doctorHasLicense => doctorRoleId == 'vaitro_cuuhococc';
  String get doctorRoleLabel =>
      doctorHasLicense ? 'Cứu hộ viên có CCHN' : 'Cứu hộ viên';
  String get doctorInitials {
    final parts = doctorName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.last.isEmpty) return 'CH';
    return parts.last.substring(0, 1).toUpperCase();
  }

  // ════════════════════════════════════════════════════════════════════
  // Đếm ngược theo mốc thời gian thực (không đếm tick)
  // ════════════════════════════════════════════════════════════════════
  void _startCountdown() {
    _timer?.cancel();
    // Luôn bắt đầu đếm 180 giây kể từ lúc màn hình này được mở lên
    _deadline = DateTime.now().add(const Duration(seconds: totalSeconds));
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final d = _deadline;
    if (d == null || _disposed) return;
    final ms = d.difference(DateTime.now()).inMilliseconds;
    final left = math.max(0, (ms / 1000).ceil());
    remainingSeconds.value = left;

    if (phase == AlertPhase.waiting) {
      if (left == 0) {
        _timer?.cancel();
        unawaited(
          _closeWaiting(
            AlertStatus.tuChoi,
            AlertPhase.expired,
            reason: 'Hết thời gian phản hồi',
            statField: 'soLuongDaKhongNhan',
          ),
        );
      } else if (left % 2 == 0) {
        HapticFeedback.heavyImpact(); // rung cùng nhịp chuông
      }
    }
  }

  double get progressValue => remainingSeconds.value / totalSeconds;

  static String formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ════════════════════════════════════════════════════════════════════
  // Kết thúc lời mời
  // ════════════════════════════════════════════════════════════════════
  void _finish(AlertPhase next) {
    if (phase != AlertPhase.waiting && phase != AlertPhase.accepting) return;
    phase = next;
    _timer?.cancel();
    unawaited(stopEmergencySound());
    notifyListeners();
  }

  /// Từ chối / hết giờ / bị hủy: ghi trạng thái và TRẢ cứu hộ viên về trạng thái rảnh.
  Future<void> _closeWaiting(
    String status,
    AlertPhase next, {
    String? reason,
    String? statField,
  }) async {
    if (phase != AlertPhase.waiting) return;
    _finish(next); // đổi giai đoạn ngay để chống xử lý hai lần

    if (currentDoctorId.isEmpty || _assignmentDocId.isEmpty) return;
    try {
      final batch = _firestore.batch();
      batch.set(_assignmentRef, {
        'maTrangThaiTiepNhan': status,
        'thoiGianPhanHoi': Timestamp.now(),
        if (reason != null) 'lyDoTuChoi': reason,
      }, SetOptions(merge: true));
      if (currentMaYeuCau.isNotEmpty) {
        batch.set(_requestRef, {
          'danhSachPhanCongVien': {currentDoctorId: status},
        }, SetOptions(merge: true));
      }
      // true = đang bận. Từ chối hoặc hết giờ thì phải về false (bản cũ đặt true).
      batch.set(_userRef, {'nhanCaCuuHo': false}, SetOptions(merge: true));
      await batch.commit().timeout(
        const Duration(seconds: 6),
        onTimeout: () => debugPrint('Ghi phản hồi chậm (có thể đang offline).'),
      );
      if (statField != null) await _capNhatThongKeHoSo(statField);
    } catch (e) {
      debugPrint('Lỗi ghi phản hồi ca: $e');
    }
  }

  Future<void> reject(String reason) => _closeWaiting(
    AlertStatus.tuChoi,
    AlertPhase.rejected,
    reason: reason,
    statField: 'soLuongDaKhongNhan',
  );

  /// Người báo tin hủy: không tính là lỗi của cứu hộ viên nên không cộng "không nhận".
  Future<void> _handleVictimCanceled() => _closeWaiting(
    AlertStatus.daHuy,
    AlertPhase.cancelledByVictim,
    reason: 'Người báo tin đã hủy yêu cầu',
  );

  // ════════════════════════════════════════════════════════════════════
  // Tiếp nhận (transaction: chỉ thành công khi ca vẫn đang chờ)
  // ════════════════════════════════════════════════════════════════════
  /// Đếm số cứu hộ viên đã tiếp nhận ca (tiepnhan hoặc daden), không tính [boQua].
  int _demSoNguoiDaNhan(Map<String, dynamic>? yeuCau, {String? boQua}) {
    final raw = yeuCau?['danhSachPhanCongVien'];
    if (raw is! Map) return 0;
    var n = 0;
    raw.forEach((k, v) {
      if (k.toString() == boQua) return;
      final status = v is Map
          ? (v['maTrangThaiTiepNhan'] ?? v['trangThai'] ?? '').toString()
          : (v ?? '').toString();
      if (AlertStatus.tinhVaoSoLuong.contains(status)) n++;
    });
    return n;
  }

  Future<AcceptResult> accept() async {
    if (phase != AlertPhase.waiting || _assignmentDocId.isEmpty) {
      return AcceptResult.notAvailable;
    }
    phase = AlertPhase.accepting;
    notifyListeners();

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(_assignmentRef);
        final data = snap.data();
        if (!snap.exists || data == null || !_isPending(data)) {
          throw _NotAvailable();
        }

        // Kiểm tra đội đã đủ người chưa NGAY TRONG transaction: nếu nhiều người bấm
        // cùng lúc thì chỉ những người lọt vào đủ 3 chỗ mới thành công.
        final reqSnap = await tx.get(_requestRef);
        final daNhan = _demSoNguoiDaNhan(
          reqSnap.data(),
          boQua: currentDoctorId,
        );
        if (daNhan >= AlertStatus.soCuuHoToiDa) throw _TeamFull();

        tx.set(_assignmentRef, {
          'maTrangThaiTiepNhan': AlertStatus.tiepNhan,
          'thoiGianTiepNhan': Timestamp.now(),
        }, SetOptions(merge: true));
        tx.set(_requestRef, {
          'danhSachPhanCongVien': {currentDoctorId: AlertStatus.tiepNhan},
        }, SetOptions(merge: true));
        tx.set(_userRef, {'nhanCaCuuHo': true}, SetOptions(merge: true));
      });
    } on _NotAvailable {
      _finish(AlertPhase.reassigned);
      return AcceptResult.notAvailable;
    } on _TeamFull {
      // Đã đủ người: đóng lời mời của riêng bạn (không tính là bỏ lỡ, không trừ
      // thống kê) rồi để màn hình hiện hộp thoại theo AlertPhase.full.
      phase =
          AlertPhase.waiting; // _closeWaiting chỉ chạy khi đang ở giai đoạn chờ
      await _closeWaiting(
        AlertStatus.tuChoi,
        AlertPhase.full,
        reason: 'Đã đủ cứu hộ viên',
      );
      return AcceptResult.full;
    } catch (e) {
      debugPrint('Lỗi tiếp nhận ca: $e');
      // Lỗi mạng: cho phép thử lại nếu còn thời gian.
      if (phase == AlertPhase.accepting) {
        phase = AlertPhase.waiting;
        notifyListeners();
      }
      return AcceptResult.error;
    }

    phase = AlertPhase.accepted;
    _timer?.cancel();
    unawaited(stopEmergencySound());
    notifyListeners();
    // Transaction chỉ thành công một lần cho mỗi ca nên thống kê không bị cộng trùng.
    // Nên chuyển bước này sang Cloud Function.
    unawaited(_capNhatThongKeHoSo('soluongCaDaNhan'));
    return AcceptResult.success;
  }

  /// Gợi ý: chuyển việc tăng thống kê sang Cloud Function.
  Future<void> _capNhatThongKeHoSo(String fieldName) async {
    if (currentDoctorId.isEmpty) return;
    try {
      var role = doctorRoleId;
      if (role.isEmpty) {
        final doc = await _userRef.get();
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
    } catch (e) {
      debugPrint('Lỗi cập nhật thống kê hồ sơ: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Yêu cầu cứu hộ (realtime): nạn nhân, vị trí, hủy từ người dùng
  // ════════════════════════════════════════════════════════════════════
  void _listenRequest() {
    _requestSub?.cancel();
    _requestSub = _requestRef.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      _applyChain = _applyChain.then((_) => _applyRequest(data));
    }, onError: (Object e) => debugPrint('Lỗi lắng nghe yêu cầu: $e'));
  }

  LatLng? _parseLocation(Map<String, dynamic> d) {
    final lat = d['viDo'];
    final lng = d['kinhDo'];
    if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
    final gh = (d['geoHash'] ?? d['geohash'])?.toString();
    if (gh != null && gh.isNotEmpty) {
      try {
        final g = GeoHash(gh);
        return LatLng(g.latitude(), g.longitude());
      } catch (e) {
        debugPrint('Lỗi giải mã Geohash: $e');
      }
    }
    return null;
  }

  Future<void> _applyRequest(Map<String, dynamic> data) async {
    try {
      final status = (data['maTinhTrangYeuCau'] ?? '').toString();
      if (status == AlertStatus.yeuCauDaHuy) {
        if (phase == AlertPhase.waiting) unawaited(_handleVictimCanceled());
        return;
      }

      mucDoKhanCap = int.tryParse(data['mucDoKhanCap']?.toString() ?? '1') ?? 1;

      final uid = (data['maNguoiYeuCau'] ?? data['maNguoiDung'] ?? '')
          .toString();
      if (uid.isNotEmpty && !_victimProfileLoaded) {
        final u = await _firestore.collection('NguoiDung').doc(uid).get();
        _victimProfileLoaded = true;
        final p = u.data();
        if (p != null) {
          _victimProfile = p;
          victimName = (p['hoTen'] ?? 'Nạn nhân khẩn cấp').toString();
          victimPhone = (p['soDienThoai'] ?? '').toString();
        }
      }

      var loc = _parseLocation(data);
      var approximate = false;
      if (loc == null && _victimProfile != null) {
        loc = _parseLocation(_victimProfile!);
        approximate = loc != null;
      }
      isVictimLocationApproximate = approximate;
      if (loc != null) victimLocation = loc;
      notifyListeners();

      // Lấy lộ trình trước, địa chỉ sau (địa chỉ có thể chậm tới 5 giây).
      unawaited(fetchRealtimeRoute(force: true));

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
          address = await getAddressFromLatLng(loc.latitude, loc.longitude);
          notifyListeners();
        }
      } else {
        address = 'Không xác định được tọa độ vị trí';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi xử lý yêu cầu cứu hộ: $e');
    }
  }

  Future<void> _fetchFieldDetails() async {
    try {
      final doc = await _firestore
          .collection('ChiTietMoTaHienTruong')
          .doc(currentMaYeuCau)
          .get();
      final data = doc.data();
      if (data == null) return;
      final ghiChu = data['ghiChuText'];
      if (ghiChu is Map) {
        moTaChiTiet = (ghiChu['moTaChiTiet'] ?? '').toString();
        final tc = ghiChu['trieuChung'];
        if (tc is List) trieuChung = tc.map((e) => e.toString()).toList();
      }
      ghiAmUrl = (data['ghiAmUrl'] ?? '').toString();
      // Trường 'videoUrl' trên Firestore thực chất chứa URL ảnh hiện trường.
      hinhAnhUrl = (data['videoUrl'] ?? '').toString();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải mô tả hiện trường: $e');
    }
  }

  bool get hasFieldInfo =>
      moTaChiTiet.isNotEmpty ||
      trieuChung.isNotEmpty ||
      ghiAmUrl.isNotEmpty ||
      hinhAnhUrl.isNotEmpty;

  // ════════════════════════════════════════════════════════════════════
  // GPS
  // ════════════════════════════════════════════════════════════════════
  Future<void> _startLocationTracking() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationWarning = 'GPS đang tắt. Khoảng cách chỉ là ước tính.';
        notifyListeners();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationWarning = 'Chưa có quyền vị trí. Khoảng cách chỉ là ước tính.';
        notifyListeners();
        return;
      }

      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _onPosition(last);
      } catch (_) {}

      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            _onPosition,
            onError: (Object e) => debugPrint('Lỗi luồng GPS: $e'),
          );
    } catch (e) {
      debugPrint('Lỗi khởi động GPS: $e');
    }
  }

  void _onPosition(Position p) {
    myLocation = LatLng(p.latitude, p.longitude);
    isMyLocationApproximate = false;
    hasGpsFix = true;
    locationWarning = null;
    notifyListeners();
    unawaited(fetchRealtimeRoute());
  }

  // ════════════════════════════════════════════════════════════════════
  // Khoảng cách, thời gian ước tính
  // ════════════════════════════════════════════════════════════════════
  bool get hasMyLocation => myLocation.latitude != 0.0;
  bool get hasVictimLocation => victimLocation.latitude != 0.0;

  double? get distanceMeters {
    if (routeDistanceMeters != null) return routeDistanceMeters;
    if (!hasMyLocation || !hasVictimLocation) return null;
    return Geolocator.distanceBetween(
      myLocation.latitude,
      myLocation.longitude,
      victimLocation.latitude,
      victimLocation.longitude,
    );
  }

  static String formatMeters(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

  String get distanceText {
    final d = distanceMeters;
    return d == null ? '--' : formatMeters(d);
  }

  double _speedOf(String mode) {
    switch (mode) {
      case 'car':
        return _carKmH;
      case 'walk':
        return _walkKmH;
      default:
        return _motoKmH;
    }
  }

  int? etaMinutes(String mode) {
    final d = distanceMeters;
    if (d == null) return null;
    return math.max(1, ((d / 1000) / _speedOf(mode) * 60).ceil());
  }

  String etaText(String mode) {
    final m = etaMinutes(mode);
    return m == null ? '--' : '$m phút';
  }

  void changeTravelMode(String mode) {
    if (selectedTravelMode == mode) return;
    selectedTravelMode = mode;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════
  // Lộ trình OSRM (giới hạn tần suất)
  // ════════════════════════════════════════════════════════════════════
  Future<void> fetchRealtimeRoute({bool force = false}) async {
    if (_disposed || !hasMyLocation || !hasVictimLocation) return;
    if (_routeInFlight) {
      if (force) _routeDirty = true;
      return;
    }
    final now = DateTime.now();
    if (!force && _lastRouteAt != null && _lastRouteFrom != null) {
      final moved = Geolocator.distanceBetween(
        _lastRouteFrom!.latitude,
        _lastRouteFrom!.longitude,
        myLocation.latitude,
        myLocation.longitude,
      );
      if (now.difference(_lastRouteAt!) < const Duration(seconds: 8) ||
          moved < 20) {
        return;
      }
    }

    _routeInFlight = true;
    _lastRouteAt = now;
    _lastRouteFrom = myLocation;
    isLoadingRoute = true;
    notifyListeners();
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${myLocation.longitude},${myLocation.latitude};'
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
        if (!_didInitialFit) _didInitialFit = fitMapBounds();
      } else {
        throw 'Không có tuyến đường';
      }
    } catch (e) {
      debugPrint('Lỗi lấy tuyến đường OSRM: $e');
      polylineCoordinates = [myLocation, victimLocation];
      routeDistanceMeters = null; // quay về khoảng cách đường chim bay
    } finally {
      _routeInFlight = false;
      isLoadingRoute = false;
      notifyListeners();
      if (_routeDirty && !_disposed) {
        _routeDirty = false;
        unawaited(fetchRealtimeRoute(force: true));
      }
    }
  }

  bool fitMapBounds() {
    final map = mapController;
    if (map == null) return false;
    try {
      if (hasMyLocation && hasVictimLocation) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            math.min(myLocation.latitude, victimLocation.latitude),
            math.min(myLocation.longitude, victimLocation.longitude),
          ),
          northeast: LatLng(
            math.max(myLocation.latitude, victimLocation.latitude),
            math.max(myLocation.longitude, victimLocation.longitude),
          ),
        );
        unawaited(
          map
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80))
              .catchError((Object _) {}),
        );
        return true;
      }
      if (hasVictimLocation) {
        unawaited(
          map
              .animateCamera(CameraUpdate.newLatLngZoom(victimLocation, 16))
              .catchError((Object _) {}),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  void focusMe() {
    final map = mapController;
    if (map == null || !hasMyLocation) return;
    try {
      unawaited(
        map
            .animateCamera(CameraUpdate.newLatLngZoom(myLocation, 16))
            .catchError((Object _) {}),
      );
    } catch (_) {}
  }

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
  // Âm thanh
  // ════════════════════════════════════════════════════════════════════
  Future<void> _playAlert() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/nhan_cuu_ho.mp3'));
      isSoundOn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi phát âm thanh chuông báo: $e');
    }
  }

  Future<void> stopEmergencySound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Lỗi tắt âm thanh: $e');
    }
    if (isSoundOn) {
      isSoundOn = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Tiện ích ngoài ứng dụng
  // ════════════════════════════════════════════════════════════════════
  bool get hasVictimPhone => RegExp(r'\d{3,}').hasMatch(victimPhone);

  Future<void> makePhoneCall() async {
    if (!hasVictimPhone) return;
    final uri = Uri(
      scheme: 'tel',
      path: victimPhone.replaceAll(RegExp(r'\s+'), ''),
    );
    try {
      // Android 11+: cần khai báo <queries> cho scheme "tel" trong manifest.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi gọi điện: $e');
    }
  }

  Future<void> openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi mở liên kết: $e');
    }
  }

  /// Chỉ mở ứng dụng bản đồ. Việc ghi trạng thái "tiếp nhận" chỉ do accept() làm
  /// (hàm startNavigation() cũ ghi trạng thái và đặt nhanCaCuuHo = false với ý nghĩa ngược).
  Future<void> openExternalNavigation() async {
    if (!hasVictimLocation) return;
    final origin = hasMyLocation
        ? '&origin=${myLocation.latitude},${myLocation.longitude}'
        : '';
    await openUrl(
      'https://www.google.com/maps/dir/?api=1$origin'
      '&destination=${victimLocation.latitude},${victimLocation.longitude}'
      '&travelmode=driving',
    );
  }

  // ════════════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _positionSub?.cancel();
    _assignmentSub?.cancel();
    _requestSub?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose(); // bản cũ không giải phóng AudioPlayer
    remainingSeconds.dispose();
    // mapController do widget GoogleMap tự giải phóng.
    super.dispose();
  }
}
