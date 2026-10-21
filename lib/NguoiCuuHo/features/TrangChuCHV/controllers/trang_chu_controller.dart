import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class TrangChuController extends ChangeNotifier {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NƠI LƯU TRỮ TRẠNG THÁI (STATE) ---
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isOnline = true;
  String? name;
  String? role;
  String? image;
  String maVaiTro = '';
  Timer? _timer;
  final String _userID = 'nguoidung2';
  final int _soLuongCaTiepNhan = 0;

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;
  String get userID => _userID;

  TrangChuController() {
    initLocationService();
    _startTimer();
    fetchFullUserData(_userID);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void toggleOnline(bool val) {
    _isOnline = val;
    if (!_isOnline) {
      _onlineSeconds = 0;
    }
    notifyListeners();
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

  Future<void> _updateLocationOnMap(LatLng newPos) async {
    _currentPosition = newPos;
    _isLoadingLocation = false;
    notifyListeners();

    if (mapController != null) {
      //Lấy góc zoom hiện tại mà người dùng đang thu phóng trên bản đồ
      double currentZoom = await mapController!.getZoomLevel();

      // Di chuyển camera về vị trí mới và GIỮ NGUYÊN góc zoom hiện tại
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, currentZoom),
      );
    }
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

      if (_isOnline) {
        _onlineSeconds++;
        notifyListeners();
      }
    });
  }

  String get formattedOnlineTime {
    int hours = _onlineSeconds ~/ 3600;
    int minutes = (_onlineSeconds % 3600) ~/ 60;
    int seconds = _onlineSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  //================= Firebase =================
  Future<void> fetchFullUserData(String userId) async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        maVaiTro = userData['maVaiTro'] ?? '';
      }

      if (maVaiTro == 'vaitro_cuuhococc') {
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
        }
      } else {
        if (maVaiTro.isNotEmpty) {
          DocumentSnapshot roleDoc = await FirebaseFirestore.instance
              .collection('VaiTro')
              .doc(maVaiTro)
              .get();

          if (roleDoc.exists && roleDoc.data() != null) {
            Map<String, dynamic> roleData =
                roleDoc.data() as Map<String, dynamic>;
            role =
                roleData['tenVaiTro'] ??
                roleData['vaiTro'] ??
                roleData['moTa'] ??
                'Cứu hộ viên';
          } else {
            role = 'Cứu hộ viên';
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

  Future<String?> getAvatarBase64(String maNguoiDung) async {
    try {
      QuerySnapshot phanLoaiSnap = await _firestore
          .collection('PhanLoaiAnh')
          .where('tenPhanLoaiAnh', isEqualTo: 'Ảnh đại diện')
          .limit(1)
          .get();

      if (phanLoaiSnap.docs.isEmpty) return null;

      String maPhanLoaiAvatar = phanLoaiSnap.docs.first.id;

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
      debugPrint('Lỗi lấy ảnh đại diện Base64: $e');
    }
    return null;
  }

  static Uint8List? bytesFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(cleanBase64.trim());
    } catch (e) {
      debugPrint('Lỗi giải mã Base64: $e');
      return null;
    }
  }
}
