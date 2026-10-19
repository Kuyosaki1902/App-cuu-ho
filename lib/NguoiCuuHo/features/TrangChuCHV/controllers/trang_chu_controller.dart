import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class TrangChuController extends ChangeNotifier {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NƠI LƯU TRỰ TRẠNG THÁI (STATE) ---
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isOnline = true;
  String? name;
  String? role;
  String? image;
  String _selectedRadius = '3.0 km (Chuẩn)';
  String maVaiTro = '';
  Timer? _timer;
  final String _userID = 'nguoidung2';
  final int _soLuongCaTiepNhan = 0;

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  String get selectedRadius => _selectedRadius;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;
  String get userID => _userID;

  TrangChuController() {
    initLocationService();
    _startTimer();
    // Gọi hàm lấy dữ liệu ngay khi khởi tạo Controller
    fetchFullUserData(_userID);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- CÁC HÀM XỬ LÝ LOGIC ---
  double getCircleRadiusInMeters() {
    if (_selectedRadius.contains('1.0')) return 1000.0;
    if (_selectedRadius.contains('5.0')) return 5000.0;
    return 3000.0;
  }

  void updateSelectedRadius(String radius) {
    _selectedRadius = radius;
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  // 🟢 Cập nhật logic toggleOnline để điều khiển Timer
  void toggleOnline(bool val) {
    _isOnline = val;
    if (!_isOnline) {
      _onlineSeconds = 0; // Reset số giây trực ca về 0 khi tắt online
    }
    notifyListeners();
  }

  double getZoomLevel() {
    if (_selectedRadius.contains('1.0')) return 11;
    if (_selectedRadius.contains('5.0')) return 13;
    return 12;
  }

  // --- LOGIC GPS & BẢN ĐỒ ---
  Future<void> initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    _isLoadingLocation = true;
    notifyListeners();

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLoadingLocation = false;
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isLoadingLocation = false;
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _updateLocationOnMap(LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          _updateLocationOnMap(LatLng(position.latitude, position.longitude));
        });
  }

  void _updateLocationOnMap(LatLng newPos) {
    _currentPosition = newPos;
    _isLoadingLocation = false;
    notifyListeners();

    mapController?.animateCamera(
      CameraUpdate.newLatLng(
        newPos,
      ), // 🟢 Giữ camera di chuyển theo vị trí mà không đổi góc zoom
    );
  }

  //================= XỬ LÝ BOTTOM PANEL =================
  DateTime _currentTime = DateTime.now();
  DateTime get currentTime => _currentTime;

  int _onlineSeconds = 0;
  int get onlineSeconds => _onlineSeconds;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();

      // Chỉ đếm thời gian khi Bác sĩ đang ở trạng thái Online
      if (_isOnline) {
        _onlineSeconds++;
        notifyListeners(); // Thông báo cập nhật thời gian từng giây
      }
    });
  }

  // Định dạng thời gian hiển thị hh:mm:ss
  String get formattedOnlineTime {
    int hours = _onlineSeconds ~/ 3600;
    int minutes = (_onlineSeconds % 3600) ~/ 60;
    int seconds = _onlineSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  //================= FireBase =================
  Future<void> fetchFullUserData(String userId) async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      // 1. Lấy thông tin cá nhân (Họ tên, Mã vai trò,...) từ bảng 'NguoiDung'
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        maVaiTro = userData['maVaiTro'] ?? '';
        // image = userData['hinhAnh'] ?? userData['avatar'];
      } else {
        debugPrint('Không tìm thấy Document "$userId" trong bảng NguoiDung');
      }

      // 🟢 2. PHÂN NHÁNH XỬ LÝ LẤY VAI TRÒ / CHUYÊN MÔN
      if (maVaiTro == 'vaitro_cuuhococc') {
        // 🟢 TRƯỜNG HỢP 1: Cứu hộ viên CÓ CCHN -> Lấy chuyên ngành từ bảng 'HoSoCuuHoCoCCHN'
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('HoSoCuuHoCoCCHN')
            .doc(userId)
            .get();

        if (profileDoc.exists && profileDoc.data() != null) {
          Map<String, dynamic> profileData =
              profileDoc.data() as Map<String, dynamic>;
          role =
              profileData['tenChuyenNganh'] ??
              profileData['chuyenNganh'] ??
              'Cứu hộ viên có CCHN';
        } else {
          role = 'Cứu hộ viên có CCHN';
          debugPrint(
            'Không tìm thấy Document "$userId" trong bảng HoSoCuuHoCoCCHN',
          );
        }
      } else {
        // 🟢 TRƯỜNG HỢP 2: Cứu hộ viên KHÔNG CCHN / Vai trò khác -> Truy vấn vào bảng 'VaiTro' dựa trên maVaiTro
        if (maVaiTro.isNotEmpty) {
          DocumentSnapshot roleDoc = await FirebaseFirestore.instance
              .collection('VaiTro')
              .doc(maVaiTro)
              .get();

          if (roleDoc.exists && roleDoc.data() != null) {
            Map<String, dynamic> roleData =
                roleDoc.data() as Map<String, dynamic>;
            // Lấy tên vai trò (kiểm tra cả tenVaiTro hoặc vaiTro phòng trường hợp tên field khác nhau)
            role =
                roleData['tenVaiTro'] ??
                roleData['vaiTro'] ??
                roleData['moTa'] ??
                'Cứu hộ viên';
          } else {
            role = 'Cứu hộ viên';
            debugPrint('Không tìm thấy Document "$maVaiTro" trong bảng VaiTro');
          }
        } else {
          role = 'Chưa cập nhật';
        }
      }
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu Firestore: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// 🟢 Lấy chuỗi Base64 của Ảnh đại diện theo maNguoiDung
  Future<String?> getAvatarBase64(String maNguoiDung) async {
    try {
      // 1. Tìm maPhanLoaiAnh có tenPhanLoai là "Ảnh đại diện" trong bảng PhanLoaiAnh
      QuerySnapshot phanLoaiSnap = await _firestore
          .collection('PhanLoaiAnh')
          .where('tenPhanLoaiAnh', isEqualTo: 'Ảnh đại diện')
          .limit(1)
          .get();

      if (phanLoaiSnap.docs.isEmpty) {
        debugPrint(
          '🔴 Không tìm thấy loại "Ảnh đại diện" trong bảng PhanLoaiAnh',
        );
        return null;
      }

      String maPhanLoaiAvatar = phanLoaiSnap.docs.first.id;

      // 2. Tìm trong bảng LuuAnh bằng maNguoiDung và maPhanLoaiAnh
      QuerySnapshot luuAnhSnap = await _firestore
          .collection('LuuAnh')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .where('maPhanLoaiAnh', isEqualTo: maPhanLoaiAvatar)
          .limit(1)
          .get();

      if (luuAnhSnap.docs.isNotEmpty) {
        final data = luuAnhSnap.docs.first.data() as Map<String, dynamic>;
        return data['base64Image'] ?? data['duongDanAnh'] ?? data['duLieuAnh'];
      }
    } catch (e) {
      debugPrint('🔴 Lỗi lấy ảnh đại diện Base64: $e');
    }
    return null;
  }

  /// 🟢 Hàm tiện ích chuyển chuỗi Base64 thành Uint8List để hiển thị ảnh MemoryImage
  static Uint8List? bytesFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      // Bỏ tiền tố Data URL nếu có (ví dụ: "data:image/png;base64,...")
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(cleanBase64.trim());
    } catch (e) {
      debugPrint('🔴 Lỗi giải mã Base64: $e');
      return null;
    }
  }
}
