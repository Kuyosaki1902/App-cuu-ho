import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  final String _userID = 'nguoidung1';
  final int _soLuongCaTiepNhan = 0;

  // 🟢 QUẢN LÝ THỜI GIAN THEO NGÀY
  int _onlineSeconds = 0;
  String _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;
  String get userID => _userID;
  int get onlineSeconds => _onlineSeconds;

  TrangChuController() {
    initLocationService();
    _initAndCheckNewDayTimer();
    fetchFullUserData(_userID);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    _timer?.cancel();
    _usersNearbySubscription?.cancel();
    super.dispose();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  // 🟢 1. Khởi tạo thời gian từ SharedPreferences và kiểm tra ngày mới
  Future<void> _initAndCheckNewDayTimer() async {
    final prefs = await SharedPreferences.getInstance();
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? savedDate = prefs.getString('saved_online_date');

    if (savedDate == null || savedDate != currentDate) {
      _onlineSeconds = 0;
      await prefs.setString('saved_online_date', currentDate);
      await prefs.setInt('saved_online_seconds', 0);
    } else {
      _onlineSeconds = prefs.getInt('saved_online_seconds') ?? 0;
    }
    _todayDateStr = currentDate;
    notifyListeners();

    if (_isOnline) {
      _startTimer();
    }
  }

  // 🟢 2. Cập nhật Bật/Tắt Online & Cập nhật Firestore
  void toggleOnline(bool val) {
    _checkDayRollover();
    _isOnline = val;

    if (_isOnline) {
      _startTimer();
      listenToNearbyUsers(); // Bắt đầu lắng nghe quét người dùng khi Online
    } else {
      _stopTimer();
      _usersNearbySubscription?.cancel(); // Dừng lắng nghe từ Firestore
      _nearbyUsers = []; // 🟢 XÓA DANH SÁCH NGƯỜI DÙNG XUNG QUANH KHI OFFLINE
    }

    _updateUserOnlineStatusInFirestore(_isOnline);
    notifyListeners();
  }

  /// 🟢 Cập nhật thuộc tính isOnline vào Firestore NguoiDung
  Future<void> _updateUserOnlineStatusInFirestore(bool status) async {
    try {
      await _firestore.collection('NguoiDung').doc(_userID).update({
        'isOnline': status,
      });
      debugPrint('Đã cập nhật isOnline = $status cho user $_userID');
    } catch (e) {
      debugPrint('Lỗi cập nhật isOnline trên Firestore: $e');
    }
  }

  // 🟢 3. Bắt đầu bộ đếm giờ
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkDayRollover();
      _onlineSeconds++;
      _saveOnlineSeconds();
      notifyListeners();
    });
  }

  // 🟢 4. Dừng đếm giờ
  void _stopTimer() {
    _timer?.cancel();
    _saveOnlineSeconds();
  }

  // 🟢 5. Kiểm tra nếu thời gian đếm xuyên qua thời khắc 00:00 đêm sang ngày mới
  void _checkDayRollover() {
    String nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (nowStr != _todayDateStr) {
      _todayDateStr = nowStr;
      _onlineSeconds = 0;
      _saveOnlineSeconds();
    }
  }

  // 🟢 6. Lưu thời gian vào SharedPreferences
  Future<void> _saveOnlineSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_online_date', _todayDateStr);
    await prefs.setInt('saved_online_seconds', _onlineSeconds);
  }

  // 🟢 7. Định dạng thời gian hiển thị hh:mm:ss
  String get formattedOnlineTime {
    int hours = _onlineSeconds ~/ 3600;
    int minutes = (_onlineSeconds % 3600) ~/ 60;
    int seconds = _onlineSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
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

  //================= Firebase =================
  Future<void> fetchFullUserData(String userId) async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      DocumentSnapshot userDoc = await _firestore
          .collection('NguoiDung')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        maVaiTro = userData['maVaiTro'] ?? '';

        // 🟢 Đọc trạng thái isOnline từ Firestore nếu có
        if (userData.containsKey('isOnline')) {
          _isOnline = userData['isOnline'] ?? true;
        } else {
          // Nếu chưa có thuộc tính isOnline thì khởi tạo mặc định là true
          _updateUserOnlineStatusInFirestore(_isOnline);
        }
      }

      if (maVaiTro == 'vaitro_cuuhococc') {
        DocumentSnapshot profileDoc = await _firestore
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
          DocumentSnapshot roleDoc = await _firestore
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

  /// 🟢 Phương thức thực hiện chuyển vai trò về 'vaitro_nguoidung'
  Future<bool> chuyenVaiTroNguoiDung() async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      // 1. Cập nhật mã vai trò lên Firestore ở bảng NguoiDung
      await _firestore.collection('NguoiDung').doc(_userID).update({
        'maVaiTro': 'vaitro_nguoidung',
      });

      // 2. Cập nhật lại giá trị maVaiTro trong Controller
      maVaiTro = 'vaitro_nguoidung';

      // 3. Tải lại toàn bộ thông tin vai trò/hồ sơ tương ứng với maVaiTro mới
      await fetchFullUserData(_userID);

      debugPrint('Đã chuyển maVaiTro về vaitro_nguoidung thành công.');
      return true;
    } catch (e) {
      debugPrint('Lỗi khi chuyển vai trò: $e');
      return false;
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

  // Bảng màu dành riêng cho các nhóm người thân
  final List<Color> _familyColorPalette = [
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  void _processFamilyGroups(List<Map<String, dynamic>> users) {
    int groupCounter = 1;
    // Map lưu userId -> groupId
    Map<String, int> userGroupMap = {};

    for (int i = 0; i < users.length; i++) {
      String u1Id = users[i]['userId'];
      List<dynamic> listNT1 = users[i]['danhSachNguoiThan'] ?? [];

      for (int j = i + 1; j < users.length; j++) {
        String u2Id = users[j]['userId'];

        // Kiểm tra xem u2Id có nằm trong danh sách người thân của u1Id không
        bool isRelative = listNT1.any((nt) => nt['maNguoiThan'] == u2Id);

        if (isRelative) {
          int assignedGroup;

          // Nếu 1 trong 2 đã có group thì lấy group đó, chưa có thì tạo group mới
          if (userGroupMap.containsKey(u1Id)) {
            assignedGroup = userGroupMap[u1Id]!;
          } else if (userGroupMap.containsKey(u2Id)) {
            assignedGroup = userGroupMap[u2Id]!;
          } else {
            assignedGroup = groupCounter++;
          }

          userGroupMap[u1Id] = assignedGroup;
          userGroupMap[u2Id] = assignedGroup;
        }
      }
    }

    // Gán thông tin màu sắc và groupId vào từng user
    for (var user in users) {
      String uId = user['userId'];
      if (userGroupMap.containsKey(uId)) {
        int gId = userGroupMap[uId]!;
        user['groupId'] = gId;
        // Chọn màu theo thuật toán xoay vòng trong Bảng màu
        user['groupColor'] =
            _familyColorPalette[(gId - 1) % _familyColorPalette.length];
        user['hasFamilyNearby'] = true;
      } else {
        user['groupId'] = null;
        user['groupColor'] = const Color(0xFF0284C7); // Màu xanh lam mặc định
        user['hasFamilyNearby'] = false;
      }
    }
  }

  //---------Quét người dùng xung quanh-------------//
  StreamSubscription<QuerySnapshot>? _usersNearbySubscription;
  List<Map<String, dynamic>> _nearbyUsers = [];

  // Getter truyền danh sách người dùng xung quanh ra UI
  List<Map<String, dynamic>> get nearbyUsers => _nearbyUsers;

  /// 🟢 Lắng nghe người dùng xung quanh và đọc danh sách người thân từ NguoiThan/{userId}/DanhSachNguoiThan
  void listenToNearbyUsers() {
    _usersNearbySubscription?.cancel();

    // 🟢 Nếu Cứu hộ viên đang Offline thì không quét và xóa danh sách người dùng
    if (!_isOnline) {
      _nearbyUsers = [];
      notifyListeners();
      return;
    }
    _usersNearbySubscription = _firestore
        .collection('NguoiDung')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
          if (_currentPosition == null) return;

          List<Map<String, dynamic>> tempUsers = [];

          for (var doc in snapshot.docs) {
            if (doc.id == _userID) continue;

            final data = doc.data() as Map<String, dynamic>;

            if (data['maVaiTro'] != 'vaitro_nguoidung') continue;
            if (data['viDo'] == null || data['kinhDo'] == null) continue;

            double userLat = (data['viDo'] as num).toDouble();
            double userLng = (data['kinhDo'] as num).toDouble();

            double distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              userLat,
              userLng,
            );

            // Bán kính quét 100 mét
            if (distanceInMeters <= 100.0) {
              String userId = doc.id;

              // 🟢 1. TRUY VẤN SUB-COLLECTION DanhSachNguoiThan TỪ COLLECTION NguoiThan
              List<Map<String, dynamic>> listNguoiThan = [];
              try {
                QuerySnapshot nguoiThanSnap = await _firestore
                    .collection('NguoiThan')
                    .doc(userId)
                    .collection('DanhSachNguoiThan')
                    .get();

                for (var ntDoc in nguoiThanSnap.docs) {
                  String maNguoiThan = ntDoc.id;
                  Map<String, dynamic> ntData =
                      ntDoc.data() as Map<String, dynamic>;
                  String moiQuanHe = ntData['moiQuanHe'] ?? '';
                  String trangThai = ntData['trangThai'] ?? '';

                  if (maNguoiThan.isNotEmpty) {
                    DocumentSnapshot userRelativeDoc = await _firestore
                        .collection('NguoiDung')
                        .doc(maNguoiThan)
                        .get();

                    if (userRelativeDoc.exists &&
                        userRelativeDoc.data() != null) {
                      Map<String, dynamic> relativeData =
                          userRelativeDoc.data() as Map<String, dynamic>;

                      listNguoiThan.add({
                        'maNguoiThan': maNguoiThan,
                        'hoTen': relativeData['hoTen'] ?? 'Chưa cập nhật',
                        'soDienThoai':
                            relativeData['soDienThoai'] ?? 'Chưa cập nhật',
                        'moiQuanHe': moiQuanHe,
                        'trangThai': trangThai,
                        'ngayTao': ntData['ngayTao'],
                      });
                    }
                  }
                }
              } catch (e) {
                debugPrint('Lỗi đọc NguoiThan/$userId/DanhSachNguoiThan: $e');
              }

              // 🟢 2. MẶC ĐỊNH TẤT CẢ NGƯỜI DÙNG LÀ MÀU TRẮNG
              tempUsers.add({
                'userId': userId,
                'hoTen': data['hoTen'] ?? 'Người dùng',
                'soDienThoai': data['soDienThoai'] ?? 'Chưa cập nhật',
                'email': data['email'] ?? 'Chưa cập nhật',
                'diaChi': data['diaChi'] ?? 'Chưa cập nhật',
                'danhSachNguoiThan': listNguoiThan,
                'location': LatLng(userLat, userLng),
                'distance': distanceInMeters,
                'groupColor': Colors.white, // Mặc định màu trắng
                'hasFamilyNearby': false,
              });
            }
          }

          _nearbyUsers = tempUsers;
          notifyListeners();
        });
  }

  // Cập nhật vị trí GPS Cứu hộ viên
  Future<void> _updateLocationOnMap(LatLng newPos) async {
    _currentPosition = newPos;
    _isLoadingLocation = false;

    // 🟢 Đồng bộ vị trí thực tế của Cứu hộ viên lên Firestore NguoiDung
    try {
      await _firestore.collection('NguoiDung').doc(_userID).update({
        'viDo': newPos.latitude,
        'kinhDo': newPos.longitude,
        'isOnline': _isOnline,
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật vị trí Cứu hộ viên lên Firestore: $e');
    }

    // Bắt đầu quét người dùng xung quanh
    if (_usersNearbySubscription == null) {
      listenToNearbyUsers();
    }

    notifyListeners();

    if (mapController != null) {
      double currentZoom = await mapController!.getZoomLevel();
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, currentZoom),
      );
    }
  }
}
