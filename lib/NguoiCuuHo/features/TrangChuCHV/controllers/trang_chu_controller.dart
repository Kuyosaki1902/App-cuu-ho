import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrangChuController extends ChangeNotifier {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  // --- NƠI LƯU TRỰ TRẠNG THÁI (STATE) ---
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isOnline = true;
  String? name;
  String? role;
  String? image;
  String _selectedRadius = '3.0 km (Chuẩn)';
  Timer? _timer;
  int _soLuongCaTiepNhan = 0; // Số lượng ca tiếp nhận

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  String get selectedRadius => _selectedRadius;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;

  TrangChuController() {
    initLocationService();
    _startTimer();
    // Gọi hàm lấy dữ liệu ngay khi khởi tạo Controller
    fetchFullUserData('nguoidung3');
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

      // 1. Lấy thông tin cá nhân (Họ tên, Ảnh,...) từ bảng 'NguoiDung'
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Lấy hoTen (chú ý chính xác tên field trên Firestore)
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        //image = userData['hinhAnh'] ?? userData['avatar'];
      } else {
        debugPrint('Không tìm thấy Document "$userId" trong bảng NguoiDung');
      }

      // 2. Lấy thông tin chuyên môn (Chuyên ngành, Chức danh,...) từ bảng 'HoSoCuuHoCoCCHN'
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('HoSoCuuHoCoCCHN')
          .doc(userId)
          .get();

      if (profileDoc.exists && profileDoc.data() != null) {
        Map<String, dynamic> profileData =
            profileDoc.data() as Map<String, dynamic>;
        // Lấy chuyên ngành/vai trò
        role =
            profileData['tenChuyenNganh'] ??
            profileData['chuyenNganh'] ??
            'Chưa cập nhật';
      } else {
        debugPrint(
          'Không tìm thấy Document "$userId" trong bảng HoSoCuuHoCoCCHN',
        );
      }
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu Firestore: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }
}
