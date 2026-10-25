// lib/GiaoDienDangTimKiem/controllers/tim_kiem_cuu_ho_controller.dart

import 'dart:async';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/models/yeucaucuuhomodel.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

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

  GoogleMapController? mapController;
  bool isLoading = true;

  YeuCauCuuHoModel? yeuCauCuuHo;
  ChiTietMoTaHienTruongModel? chiTietMoTa;

  LatLng currentDeviceLocation = const LatLng(10.7769, 106.6993);

  final Set<Circle> circles = {};
  final Set<Marker> markers = {};

  int currentScanStep = 0;
  final List<double> scanRadii = [1000, 3000, 5000];
  final List<Duration> scanIntervals = [
    const Duration(seconds: 10),
    const Duration(seconds: 10),
    const Duration(seconds: 10),
  ];

  Timer? _scanTimer;
  Timer? _secondsTimer;
  Timer? _timeoutTimer;
  StreamSubscription<List<ChiTietPhanCongCuuHoModel>>? _phanCongSubscription;

  int elapsedSeconds = 0;
  List<Map<String, dynamic>> rescuerList = []; // Cứu hộ viên được đề xuất/quét
  List<String> acceptedRescuerIds = []; // Danh sách CHV ĐÃ TIẾP NHẬN

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

      chiTietMoTa = await _firebaseService.getMoTaHienTruongById(maYeuCau);
      await updateMapOverlays();

      // 🌟 1. Bật Stream Realtime lắng nghe bảng ChiTietPhanCongCuuHo
      _listenToPhanCongChanges(maYeuCau, onUpdate);

      // 🌟 2. Khởi tạo đếm ngược 5 phút (300s) timeout
      _startTimeoutTimer(maYeuCau, onUpdate);
    } catch (e) {
      debugPrint('Lỗi khởi tạo tìm kiếm cứu hộ: $e');
    } finally {
      isLoading = false;
      onUpdate();
    }

    // 🌟 3. Tiến hành Quét AI & Gửi yêu cầu
    startScanProcess(maYeuCau, onUpdate);
  }

  /// 🌟 REALTIME MONITORING: Lắng nghe liên tục thay đổi trạng thái phản hồi
  void _listenToPhanCongChanges(String maYeuCau, Function() onUpdate) {
    _phanCongSubscription?.cancel();
    _phanCongSubscription = _firebaseService
        .streamPhanCongByYeuCau(maYeuCau)
        .listen((phanCongList) {
          acceptedRescuerIds.clear();

          for (var pc in phanCongList) {
            // Nếu chuyển trạng thái sang cuuho_trangthai_tiepnhan
            if (pc.maTrangThaiTiepNhan == 'cuuho_trangthai_tiepnhan') {
              if (!acceptedRescuerIds.contains(pc.maNguoiCuuHo)) {
                acceptedRescuerIds.add(pc.maNguoiCuuHo);
              }
            }
            // Nếu cuuho_trangthai_tuchoi thì tự động bỏ qua (không ghi nhận)
          }

          // 🛑 ĐIỀU KIỆN CỐT LÕI 1: Có đủ 5 Cứu hộ viên tiếp nhận ca -> Dừng tìm kiếm ngay
          if (acceptedRescuerIds.length >= 5) {
            _stopAllTimersAndSearch();
            _firebaseService.updateTinhTrangYeuCau(
              maYeuCau,
              'user_tinhtrang_daphancong',
            );
            debugPrint('🎯 Đã có đủ 5 Cứu hộ viên nhận đơn. Dừng tìm kiếm!');
          }

          onUpdate();
        });
  }

  /// 🌟 TIMEOUT TIMER: Đếm ngược 5 phút (300 giây)
  void _startTimeoutTimer(String maYeuCau, Function() onUpdate) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 5), () async {
      _stopAllTimersAndSearch();

      if (acceptedRescuerIds.isNotEmpty) {
        // 🛑 ĐIỀU KIỆN CỐT LÕI 2: Quá 5 phút & Ít nhất 1 CHV nhận -> user_tinhtrang_daphancong
        await _firebaseService.updateTinhTrangYeuCau(
          maYeuCau,
          'user_tinhtrang_daphancong',
        );
        debugPrint(
          '⏱️ Hết 5 phút: Đã có ${acceptedRescuerIds.length} CHV nhận.',
        );
      } else {
        // 🛑 ĐIỀU KIỆN CỐT LÕI 3: Quá 5 phút & KHÔNG có ai nhận -> user_tinhtrang_quahandieuphoi
        await _firebaseService.updateTinhTrangYeuCau(
          maYeuCau,
          'user_tinhtrang_quahandieuphoi',
        );
        debugPrint('⏱️ Hết 5 phút: Không có CHV nào nhận đơn!');
      }
      onUpdate();
    });
  }

  void startScanProcess(String maYeuCau, Function() onUpdate) {
    currentScanStep = 0;
    elapsedSeconds = 0;

    _performScanWithAI(maYeuCau, onUpdate);

    _secondsTimer?.cancel();
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds++;
      onUpdate();
    });

    _scheduleNextScanStep(maYeuCau, onUpdate);
  }

  void _scheduleNextScanStep(String maYeuCau, Function() onUpdate) {
    _scanTimer?.cancel();
    _scanTimer = Timer(scanIntervals[currentScanStep], () {
      if (rescuerList.length < 5 && currentScanStep < scanRadii.length - 1) {
        currentScanStep++;
        updateMapOverlays();
        _performScanWithAI(maYeuCau, onUpdate);
        _scheduleNextScanStep(maYeuCau, onUpdate);
      }
    });
  }

  /// 🌟 PHÂN TÍCH TỪ KHÓA AI & MATCH HỒ SƠ
  Future<void> _performScanWithAI(String maYeuCau, Function() onUpdate) async {
    double currentRadiusMeters = scanRadii[currentScanStep];

    try {
      Set<String> rescuerUserIds = await _firebaseService
          .getAllRescuerUserIds();
      if (rescuerUserIds.isEmpty) return;

      List<String> userIdsList = rescuerUserIds.toList();
      List<NguoiDungModel> rescuerUsers = [];

      for (var i = 0; i < userIdsList.length; i += 30) {
        var chunk = userIdsList.sublist(
          i,
          i + 30 > userIdsList.length ? userIdsList.length : i + 30,
        );
        for (var userId in chunk) {
          final user = await _firebaseService.getUserById(userId);
          if (user != null) rescuerUsers.add(user);
        }
      }

      // Trích xuất mô tả hiện trường từ màn hình trước
      String keywordsText = '';
      if (chiTietMoTa?.ghiChuText != null) {
        keywordsText = chiTietMoTa!.ghiChuText.toString().toLowerCase();
      }

      String loaiYeuCau = yeuCauCuuHo?.maLoaiYeuCau ?? 'loaiyeucau_sos';

      for (var user in rescuerUsers) {
        if (rescuerList.length >= 5) break;

        if (yeuCauCuuHo != null &&
            user.maNguoiDung == yeuCauCuuHo!.maNguoiYeuCau) {
          continue;
        }

        if (user.viDo == null || user.kinhDo == null) continue;

        double distanceInMeters = Geolocator.distanceBetween(
          currentDeviceLocation.latitude,
          currentDeviceLocation.longitude,
          user.viDo!,
          user.kinhDo!,
        );

        if (distanceInMeters <= currentRadiusMeters) {
          bool isExisted = rescuerList.any(
            (r) => r['user'].maNguoiDung == user.maNguoiDung,
          );

          if (!isExisted) {
            // Lọc theo maLoaiYeuCau
            bool isMatched = await _checkAIMatchProfile(
              user.maNguoiDung!,
              loaiYeuCau,
              keywordsText,
            );

            if (isMatched) {
              double distanceKm = (distanceInMeters / 1000);

              rescuerList.add({
                'user': user,
                'distanceKm': distanceKm.toStringAsFixed(1),
              });

              _addRescuerMarker(user, distanceKm.toStringAsFixed(1));

              // Gửi bản ghi phân công với trạng thái chờ phản hồi initial
              await _createAssignmentRecord(maYeuCau, user.maNguoiDung!);
            }
          }
        }
      }

      onUpdate();
    } catch (e) {
      debugPrint('Lỗi quét AI cứu hộ: $e');
    }
  }

  /// 🌟 KIỂM TRA MATCH HỒ SƠ DỰA VÀO LOẠI YÊU CẦU & AI KEYWORDS
  Future<bool> _checkAIMatchProfile(
    String userId,
    String loaiYeuCau,
    String keywords,
  ) async {
    // 1. loaiyeucau_timtudong: Chỉ tìm HoSoCuuHoCoCCHN
    final hoSoCoCCHN = await _firebaseService.getHoSoCoCCHN(userId);
    if (hoSoCoCCHN != null) {
      if (keywords.isEmpty)
        return true; // Không có mô tả -> Ghép mặc định theo vị trí
      String chuyenNganh = hoSoCoCCHN.tenChuyenNganh.toLowerCase();
      if (keywords.contains(chuyenNganh) || chuyenNganh.contains(keywords)) {
        return true;
      }
    }

    if (loaiYeuCau == 'loaiyeucau_timtudong') {
      return false; // Bỏ qua hồ sơ không CCHN nếu chọn tìm tự động chuẩn y tế
    }

    // 2. loaiyeucau_sos: Tìm cả 2 hồ sơ (Kiểm tra tiếp HoSoCuuHoKhongCCHN)
    final hoSoKhongCCHN = await _firebaseService.getHoSoKhongCCHN(userId);
    if (hoSoKhongCCHN != null) {
      if (keywords.isEmpty) return true;

      // 🌟 Truy vấn danh sách ID kỹ năng từ Subcollection ChiTietKiNang/{userId}/DanhSachKiNang
      List<String> userSkillIds = await _firebaseService.getSkillIdsByUserId(
        userId,
      );

      if (userSkillIds.isNotEmpty) {
        // Kiểm tra mã kỹ năng (vd: kn_bang_bo, kn_cpr) có nằm trong ghi chú mô tả không
        bool isSkillIdMatched = userSkillIds.any(
          (skId) => keywords.contains(skId.toLowerCase()),
        );
        if (isSkillIdMatched) return true;

        // Đọc tiếp tên / mô tả kỹ năng từ bảng KyNangCuuHo để so sánh từ khóa
        List<String> skillDetails = await _firebaseService.getSkillNamesByIds(
          userSkillIds,
        );
        bool isSkillDetailMatched = skillDetails.any(
          (detail) => keywords.contains(detail) || detail.contains(keywords),
        );
        if (isSkillDetailMatched) return true;
      }
    }

    return true; // Mặc định hỗ trợ tìm rộng nếu chưa trùng khớp hoàn toàn từ khóa
  }

  Future<void> _createAssignmentRecord(
    String maYeuCau,
    String maNguoiCuuHo,
  ) async {
    try {
      int previousCount = await _firebaseService.countAssignmentsByRescuer(
        maNguoiCuuHo,
      );
      int soCaThamGia = previousCount + 1;
      String maPhanCong = 'phancong_${maNguoiCuuHo}_$soCaThamGia';

      final phanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_chophanhoi', // Trạng thái ban đầu
      );

      await _firebaseService.createPhanCongCuuHo(phanCong);
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
    double rating = 5.0;

    Widget rescuerMarkerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF006A55), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
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
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$rating • $distanceKm km',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
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

    String latStr = currentDeviceLocation.latitude.toStringAsFixed(4);
    String lngStr = currentDeviceLocation.longitude.toStringAsFixed(4);

    Widget victimMarkerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF006A55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$latStr, $lngStr',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
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
    if (mapController == null) return;
    mapController?.animateCamera(CameraUpdate.newLatLng(currentDeviceLocation));
  }

  void _stopAllTimersAndSearch() {
    _scanTimer?.cancel();
    _secondsTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void dispose() {
    _stopAllTimersAndSearch();
    _phanCongSubscription?.cancel();
  }
}
