// lib/GiaoDienDangTimKiem/controllers/tim_kiem_cuu_ho_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/gemini/gemini_service.dart';
import 'package:cuhokhancap/user/models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/luuanhmodel.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/models/yeucaucuuhomodel.dart';

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TimKiemCuuHoController {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();

  GoogleMapController? mapController;
  bool isLoading = true;

  YeuCauCuuHoModel? yeuCauCuuHo;
  ChiTietMoTaHienTruongModel? chiTietMoTa;
  List<LuuAnhModel> danhSachAnhBase64 = [];

  LatLng currentDeviceLocation = const LatLng(10.7769, 106.6993);

  final Set<Circle> circles = {};
  final Set<Marker> markers = {};

  // 🌟 Mở rộng bán kính: 1000m (1km) -> 3000m (3km) -> 5000m (5km)
  int currentScanStep = 0;
  final List<double> scanRadii = [1000, 3000, 5000];

  Timer? _step15sTimer;
  Timer? _secondsTimer;
  StreamSubscription<List<ChiTietPhanCongCuuHoModel>>? _phanCongSubscription;

  int elapsedSeconds = 0;
  List<Map<String, dynamic>> rescuerList = [];
  List<String> acceptedRescuerIds = [];
  Set<String> assignedRescuerIds = {};

  Map<String, dynamic>? aiAnalysisResult;

  String get formattedElapsedTime {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  Future<void> initSearch(String maYeuCau, Function() onUpdate) async {
    isLoading = true;
    onUpdate();

    try {
      await fetchGPSLocation();

      await _firebaseService.updateYeuCauLocation(
        maYeuCau: maYeuCau,
        viDo: currentDeviceLocation.latitude,
        kinhDo: currentDeviceLocation.longitude,
      );

      yeuCauCuuHo = await _firebaseService.getYeuCauCuuHoById(maYeuCau);
      moveToCurrentLocation();

      // 🌟 GIẢI QUYẾT BƯỚC 1: TRUY VẾT & BẮN THÔNG BÁO NGƯỜI THÂN QUA RTDB TRƯỚC
      if (yeuCauCuuHo != null) {
        await _firebaseService.notifyConnectedRelatives(
          maNguoiYeuCau: yeuCauCuuHo!.maNguoiYeuCau,
          maYeuCau: maYeuCau,
          viDo: currentDeviceLocation.latitude,
          kinhDo: currentDeviceLocation.longitude,
        );
      }

      // 🌟 GIẢI QUYẾT BƯỚC 2: ĐỌC MÔ TẢ & ẢNH BASE64 ĐỂ GEMINI MULTIMODAL PHÂN TÍCH
      chiTietMoTa = await _firebaseService.getMoTaHienTruongById(maYeuCau);
      if (chiTietMoTa != null) {
        danhSachAnhBase64 = await _firebaseService.getImagesByMoTaId(
          chiTietMoTa!.maYeuCau,
        );

        aiAnalysisResult = await _geminiService.analyzeSceneAndSuggestSkills(
          moTa: chiTietMoTa!,
          danhSachAnhBase64: danhSachAnhBase64,
        );
      }

      await updateMapOverlays();

      // 🌟 GIẢI QUYẾT BƯỚC 3: STREAM THEO DÕI CÁC BẢN GHI PHÂN CÔNG
      _listenToPhanCongChanges(maYeuCau, onUpdate);

      // Đếm thời gian nhảy từng giây
      _secondsTimer?.cancel();
      _secondsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsedSeconds++;
        onUpdate();
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo tìm kiếm cứu hộ: $e');
    } finally {
      isLoading = false;
      onUpdate();
    }

    // 🌟 GIẢI QUYẾT BƯỚC 4: BẮT ĐẦU VÒNG QUÉT RADAR AI 15S
    startAdaptiveAIRadar(maYeuCau, onUpdate);
  }

  /// 🌟 REALTIME MONITORING: LẮNG NGHE ĐƠN & QUẢN LÝ TRẠNG THÁI
  void _listenToPhanCongChanges(String maYeuCau, Function() onUpdate) {
    _phanCongSubscription?.cancel();
    _phanCongSubscription = _firebaseService.streamPhanCongByYeuCau(maYeuCau).listen((
      phanCongList,
    ) async {
      acceptedRescuerIds.clear();

      for (var pc in phanCongList) {
        if (pc.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_tiepnhan') {
          if (!acceptedRescuerIds.contains(pc.maNguoiCuuHo)) {
            acceptedRescuerIds.add(pc.maNguoiCuuHo);
          }
        }
      }

      // 🛑 ĐIỀU KIỆN 1: Ít nhất 1 CHV chấp nhận -> NGỪNG QUÉT MỚI & đổi trạng thái sang user_tinhtrang_daphancong
      if (acceptedRescuerIds.isNotEmpty) {
        _stop15sRadarTimer(); // Tắt Timer 15s quét mở rộng ngay!

        if (yeuCauCuuHo?.maTinhTrangYeuCau != 'user_tinhtrang_daphancong') {
          await _firebaseService.updateTinhTrangYeuCau(
            maYeuCau,
            'user_tinhtrang_daphancong',
          );
          debugPrint(
            '🎯 Đã có CHV chấp nhận -> Dừng quét mới & chuyển user_tinhtrang_daphancong',
          );
        }
      }

      // 🛑 ĐIỀU KIỆN 2: Đủ 5 CHV chấp nhận -> Dừng hẳn & Hủy tất cả các bản ghi chờ còn lại
      if (acceptedRescuerIds.length >= 5) {
        _stopAllTimers();
        await _firebaseService.cancelRemainingAssignments(maYeuCau);
        debugPrint('🎯 Đã đủ 5 CHV chấp nhận! Hủy các đơn chờ còn lại.');
      }

      onUpdate();
    });
  }

  /// 🌟 RADAR 15S MỞ RỘNG BÁN KÍNH (1km -> 3km -> 5km)
  void startAdaptiveAIRadar(String maYeuCau, Function() onUpdate) async {
    currentScanStep = 0; // 1km
    await _executeAIScanAndAssign(maYeuCau, onUpdate);

    _schedule15sNextStep(maYeuCau, onUpdate);
  }

  void _schedule15sNextStep(String maYeuCau, Function() onUpdate) {
    _step15sTimer?.cancel();
    _step15sTimer = Timer(const Duration(seconds: 15), () async {
      // Nếu CHƯA CÓ AI nhận đơn VÀ chưa đạt mức tối đa 5km (bước 2)
      if (acceptedRescuerIds.isEmpty &&
          currentScanStep < scanRadii.length - 1) {
        currentScanStep++; // Tăng từ 1km (bước 0) -> 3km (bước 1) -> 5km (bước 2)
        await updateMapOverlays();
        await _executeAIScanAndAssign(maYeuCau, onUpdate);

        _schedule15sNextStep(maYeuCau, onUpdate);
      }
    });
  }

  /// 🌟 QUÉT AI VÀ SẮP XẾP ƯU TIÊN PHÂN CÔNG
  Future<void> _executeAIScanAndAssign(
    String maYeuCau,
    Function() onUpdate,
  ) async {
    double maxDistanceMeters = scanRadii[currentScanStep];

    List<NguoiDungModel> onlineRescuers = await _firebaseService
        .getOnlineRescuers();
    if (onlineRescuers.isEmpty) return;

    List<Map<String, dynamic>> scoredRescuers = [];

    bool hasMoTa =
        chiTietMoTa != null &&
        chiTietMoTa!.ghiChuText != null &&
        chiTietMoTa!.ghiChuText.toString().isNotEmpty;

    String loaiYeuCau = yeuCauCuuHo?.maLoaiYeuCau ?? 'loaiyeucau_sos';

    bool shouldAIControl =
        (loaiYeuCau == 'loaiyeucau_choncuuhovien' ||
        loaiYeuCau == 'loaiyeucau_timtudong');

    for (var rescuer in onlineRescuers) {
      if (rescuer.maNguoiDung == yeuCauCuuHo?.maNguoiYeuCau) continue;
      if (assignedRescuerIds.contains(rescuer.maNguoiDung)) continue;
      if (rescuer.viDo == null || rescuer.kinhDo == null) continue;

      double distanceMeters = Geolocator.distanceBetween(
        currentDeviceLocation.latitude,
        currentDeviceLocation.longitude,
        rescuer.viDo!,
        rescuer.kinhDo!,
      );

      if (distanceMeters <= maxDistanceMeters) {
        double score = 0.0;

        if (hasMoTa && shouldAIControl) {
          // Có mô tả + Chọn CHV/Tìm tự động -> AI tính điểm chuyên ngành/kỹ năng
          score = await _calculateAIScore(rescuer, distanceMeters);
        } else {
          // Không mô tả hoặc SOS thường -> Ưu tiên khoảng cách gần nhất
          score = 10000.0 - distanceMeters;
        }

        scoredRescuers.add({
          'user': rescuer,
          'distanceMeters': distanceMeters,
          'score': score,
        });
      }
    }

    // Sắp xếp giảm dần theo điểm số
    scoredRescuers.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    for (var item in scoredRescuers) {
      if (acceptedRescuerIds.length >= 5) break;

      NguoiDungModel user = item['user'];
      double distanceKm = (item['distanceMeters'] as double) / 1000;

      assignedRescuerIds.add(user.maNguoiDung!);
      rescuerList.add({
        'user': user,
        'distanceKm': distanceKm.toStringAsFixed(1),
      });

      _addRescuerMarker(user, distanceKm.toStringAsFixed(1));

      // 🌟 Tạo phân công (Lấy maYeuCau làm Key & Set nhanCaCuuHo = true)
      await _createAssignmentRecord(maYeuCau, user.maNguoiDung!);
    }

    onUpdate();
  }

  Future<double> _calculateAIScore(
    NguoiDungModel user,
    double distanceMeters,
  ) async {
    double score = 0.0;
    List<String> reqChuyenNganh = List<String>.from(
      aiAnalysisResult?['chuyenNganhYeuCau'] ?? [],
    );
    List<String> reqKyNang = List<String>.from(
      aiAnalysisResult?['kyNangYeuCau'] ?? [],
    );

    // 1. Khớp Hồ sơ CÓ CCHN
    final hoSoCoCCHN = await _firebaseService.getHoSoCoCCHN(user.maNguoiDung!);
    if (hoSoCoCCHN != null) {
      String cn = hoSoCoCCHN.tenChuyenNganh.toLowerCase();
      for (var req in reqChuyenNganh) {
        if (cn.contains(req.toLowerCase())) {
          score += 5000.0;
        }
      }
    }

    // 2. Khớp Kỹ năng Subcollection
    List<String> userSkillIds = await _firebaseService.getSkillIdsByUserId(
      user.maNguoiDung!,
    );
    for (var skId in userSkillIds) {
      for (var req in reqKyNang) {
        if (skId.toLowerCase().contains(req.toLowerCase())) {
          score += 2000.0;
        }
      }
    }

    // 3. Phạt điểm nhẹ theo khoảng cách xa
    score -= (distanceMeters * 0.5);
    return score;
  }

  Future<void> _createAssignmentRecord(
    String maYeuCau,
    String maNguoiCuuHo,
  ) async {
    try {
      int previousCount = await _firebaseService.countAssignmentsByRescuer(
        maNguoiCuuHo,
      );
      String maPhanCong = 'phancong_${maNguoiCuuHo}_${previousCount + 1}';

      final phanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      // Ghi Root Collection
      await _firebaseService.createPhanCongCuuHo(phanCong);

      // 🌟 Ghi Subcollection với Document ID là maYeuCau & Đổi nhanCaCuuHo = true
      await _firebaseService.createPhanCongTheoNgay(
        maNguoiCuuHo: maNguoiCuuHo,
        phanCong: phanCong,
      );
    } catch (e) {
      debugPrint('Lỗi tạo bản ghi phân công: $e');
    }
  }

  Future<void> fetchGPSLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentDeviceLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Lỗi GPS: $e');
    }
  }

  Future<void> _addRescuerMarker(NguoiDungModel user, String distanceKm) async {
    Widget rescuerMarkerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF006A55), width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF006A55),
                child: Icon(
                  Icons.medical_services,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.hoTen,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$distanceKm km',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: ClipPath(
            clipper: _ArrowClipper(),
            child: Container(
              width: 14,
              height: 10,
              color: const Color(0xFF006A55),
            ),
          ),
        ),
      ],
    );

    BitmapDescriptor customIcon = await rescuerMarkerWidget
        .toBitmapDescriptor();

    markers.add(
      Marker(
        markerId: MarkerId('rescuer_${user.maNguoiDung}'),
        position: LatLng(user.viDo!, user.kinhDo!),
        icon: customIcon,
        anchor: const Offset(0.5, 1.0),
      ),
    );
  }

  Future<void> updateMapOverlays() async {
    circles.clear();
    markers.removeWhere((m) => m.markerId.value == 'current_device_marker');

    Widget victimMarkerWidget = Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF006A55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.location_on, color: Colors.white, size: 20),
    );

    BitmapDescriptor victimIcon = await victimMarkerWidget.toBitmapDescriptor();

    markers.add(
      Marker(
        markerId: const MarkerId('current_device_marker'),
        position: currentDeviceLocation,
        icon: victimIcon,
        anchor: const Offset(0.5, 0.5),
      ),
    );

    circles.add(
      Circle(
        circleId: const CircleId('scan_radius_outer'),
        center: currentDeviceLocation,
        radius: scanRadii[currentScanStep],
        fillColor: const Color(0xFF006A55).withOpacity(0.12),
        strokeColor: const Color(0xFF006A55).withOpacity(0.4),
        strokeWidth: 2,
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    moveToCurrentLocation();
  }

  void moveToCurrentLocation() {
    mapController?.animateCamera(CameraUpdate.newLatLng(currentDeviceLocation));
  }

  void _stop15sRadarTimer() {
    _step15sTimer?.cancel();
  }

  void _stopAllTimers() {
    _step15sTimer?.cancel();
    _secondsTimer?.cancel();
  }

  void dispose() {
    _stopAllTimers();
    _phanCongSubscription?.cancel();
  }
}
