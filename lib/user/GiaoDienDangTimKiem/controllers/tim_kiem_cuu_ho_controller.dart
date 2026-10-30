// lib/GiaoDienDangTimKiem/controllers/tim_kiem_cuu_ho_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'dart:convert';
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
      if (acceptedRescuerIds.length >= 3) {
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

  /// 🌟 QUÉT AI VÀ SẮP XẾP ƯU TIÊN PHÂN CÔNG (Đã tích hợp kiểm tra danhSachPhanCongVien có sẵn)
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
      // 🌟 Giới hạn dừng lại khi đủ 3 người nhận
      if (acceptedRescuerIds.length >= 3) break;

      NguoiDungModel user = item['user'];
      String maNguoiCuuHo = user.maNguoiDung!;

      // 🌟 Lấy trạng thái từ danhSachPhanCongVien đã có sẵn trong model yêu cầu cứu hộ
      String? trangThaiCu = yeuCauCuuHo?.danhSachPhanCongVien[maNguoiCuuHo];

      // Nếu người này ĐÃ TỪ CHỐI trước đó -> Chặn hoàn toàn, không quét/phân công lại
      if (trangThaiCu == 'cuuho_trangthai_phancong_tuchoi' ||
          trangThaiCu == 'tuchoi') {
        continue;
      }

      // Nếu đã có trong danh sách với bất kỳ trạng thái nào khác (đang chờ, đã nhận...) -> Bỏ qua không cấp phát trùng
      if (trangThaiCu != null && trangThaiCu.isNotEmpty) {
        continue;
      }

      double distanceKm = (item['distanceMeters'] as double) / 1000;

      assignedRescuerIds.add(maNguoiCuuHo);
      rescuerList.add({
        'user': user,
        'distanceKm': distanceKm.toStringAsFixed(1),
      });

      _addRescuerMarker(user, (item['distanceMeters'] as double));

      // 🌟 Tạo phân công và cập nhật trực tiếp vào danhSachPhanCongVien
      await _createAssignmentRecord(maYeuCau, maNguoiCuuHo);
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
      String maPhanCong =
          'phancong_${maNguoiCuuHo}_${DateTime.now().millisecondsSinceEpoch}';

      final phanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      // 1. Ghi Subcollection theo ngày
      await _firebaseService.createPhanCongTheoNgay(
        maNguoiCuuHo: maNguoiCuuHo,
        phanCong: phanCong,
      );

      // 2. Cập nhật trực tiếp qua FirebaseService
      await _firebaseService.updateDanhSachPhanCongVien(
        maYeuCau: maYeuCau,
        maNguoiCuuHo: maNguoiCuuHo,
        trangThai: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      // Cập nhật local model
      yeuCauCuuHo?.danhSachPhanCongVien[maNguoiCuuHo] =
          'cuuho_trangthai_phancong_chotiepnhan';
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

  // 🌟 Hàm cắt lấy 2 chữ cái đầu/cuối của tên (Ví dụ: "Phạm Nhật Động" -> "PĐ")
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  // 🌟 Tạo Marker Cứu hộ viên với Avatar hoặc Chữ viết tắt
  Future<void> _addRescuerMarker(
    NguoiDungModel user,
    double distanceMeters,
  ) async {
    // 1. Lấy dữ liệu Avatar từ Firebase
    String? avatarData = await _firebaseService.getUserAvatarUrl(
      user.maNguoiDung!,
    );

    ImageProvider? avatarProvider;
    if (avatarData != null && avatarData.isNotEmpty) {
      if (avatarData.startsWith('http')) {
        avatarProvider = NetworkImage(avatarData);
      } else {
        // Giải mã chuỗi Base64
        String base64Str = avatarData.contains(',')
            ? avatarData.split(',').last
            : avatarData;
        try {
          avatarProvider = MemoryImage(base64Decode(base64Str));
        } catch (e) {
          debugPrint('Lỗi decode Base64 avatar: $e');
        }
      }
    }

    // 2. Định dạng khoảng cách (Dưới 1km hiện mét "m", trên 1km hiện "km")
    String distanceText = distanceMeters < 1000
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    // 3. Lấy chữ cái viết tắt tên nạn nhân/bác sĩ
    String initials = _getInitials(user.hoTen);

    // 4. Dựng Widget Custom Marker
    Widget rescuerMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- KHUNG AVATAR ---
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006A55), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                // Có ảnh -> Nền trắng chứa ảnh; Không ảnh -> Nền xanh chứa chữ viết tắt
                backgroundColor: avatarProvider != null
                    ? Colors.white
                    : const Color(0xFF006A55),
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 4),

            // --- THẺ KHẢNG CÁCH SỐ MẾT / KM BÊN DƯỚI ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF006A55), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                distanceText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF006A55),
                ),
              ),
            ),

            // --- MŨI TÊN CHỈ XUỐNG VỊ TRÍ MAP ---
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: _ArrowClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: const Color(0xFF006A55),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Chuyển Widget thành Bitmap để hiển thị trên Google Maps
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

    // 🌟 1. TẠO MARKER NẠN NHÂN (MÀU ĐỎ + SOS)
    Widget victimMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. ICON NẠN NHÂN (Tròn, màu đỏ khẩn cấp) ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC81E1E), // Đỏ khẩn cấp
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),

            // --- 2. MŨI TÊN ĐỎ ---
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: _ArrowClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: const Color(0xFFC81E1E),
                ),
              ),
            ),

            // --- 3. THẺ CHỮ "SOS" NẰM DƯỚI MŨI TÊN ---
            Transform.translate(
              offset: const Offset(0, -2), // Kéo sát vào mũi tên
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC81E1E),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFC81E1E),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Chuyển đổi Widget thành hình ảnh Bitmap
    BitmapDescriptor victimIcon = await victimMarkerWidget.toBitmapDescriptor();

    // 🌟 2. THÊM MARKER NẠN NHÂN LÊN BẢN ĐỒ
    markers.add(
      Marker(
        markerId: const MarkerId('current_device_marker'),
        position: currentDeviceLocation,
        icon: victimIcon,
        // Dời tâm mỏ neo xuống khoảng 75% chiều cao widget để mũi tên chỉ đúng tọa độ
        anchor: const Offset(0.5, 0.75),
      ),
    );

    // 🌟 3. VẼ VÒNG TRÒN RADAR QUÉT (Giữ nguyên màu xanh thương hiệu)
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

  /// 🌟 HỦY TÌM KIẾM CỨU HỘ & DỌN DẸP DỮ LIỆU
  Future<void> cancelSearch(String maYeuCau) async {
    try {
      isLoading = true; // Hiện loading nếu cần

      // 1. Dừng mọi luồng quét và bộ đếm thời gian
      _stopAllTimers();
      _phanCongSubscription?.cancel();

      // 2. Lấy mã nạn nhân hiện tại
      String? maNanNhan = yeuCauCuuHo?.maNguoiYeuCau;

      if (maNanNhan != null) {
        // 3. Gọi FirebaseService để xóa thông báo khẩn cấp trên Realtime DB của người thân
        await _firebaseService.removeEmergencyNotification(
          maNanNhan: maNanNhan,
        );
      }

      // 4. Đổi trạng thái các đơn phân công đang chờ thành "Đã hủy"
      await _firebaseService.cancelRemainingAssignments(maYeuCau);

      // 5. Đổi trạng thái tổng của Yêu cầu cứu hộ thành Hủy (nếu có mã trạng thái hủy)
      // await _firebaseService.updateTinhTrangYeuCau(maYeuCau, 'user_tinhtrang_dahuy');

      debugPrint(
        '✅ Đã hủy tìm kiếm, thu hồi đơn và xóa thông báo RTDB thành công!',
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi hủy tìm kiếm: $e');
    } finally {
      isLoading = false;
    }
  }
}
