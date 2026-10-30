import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrangChuController extends ChangeNotifier {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _usersNearbySubscription;
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

  // Lấy UID động từ FirebaseAuth, nếu chưa đăng nhập mới dùng ID mặc định
  String get _userID => FirebaseAuth.instance.currentUser?.uid ?? 'nguoidung2';
  final int _soLuongCaTiepNhan = 0;

  // Quản lý thời gian theo ngày
  int _onlineSeconds = 0;
  String _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Danh sách người dùng xung quanh
  List<Map<String, dynamic>> _nearbyUsers = [];

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;
  String get userID => _userID;
  int get onlineSeconds => _onlineSeconds;
  List<Map<String, dynamic>> get nearbyUsers => _nearbyUsers;

  TrangChuController() {
    initLocationService();
    _initAndCheckNewDayTimer();
    fetchFullUserData(_userID);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _usersNearbySubscription?.cancel();
    mapController?.dispose();
    _timer?.cancel();
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
      _nearbyUsers = []; // Xóa danh sách người dùng xung quanh khi Offline
    }

    _updateUserOnlineStatusInFirestore(_isOnline);
    notifyListeners();
  }

  /// Cập nhật thuộc tính isOnline vào Firestore NguoiDung
  Future<void> _updateUserOnlineStatusInFirestore(bool status) async {
    try {
      await _firestore.collection('NguoiDung').doc(_userID).set({
        'isOnline': status,
      }, SetOptions(merge: true));
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
            distanceFilter: 1, // 🟢 Giảm distanceFilter xuống 5m để nhạy hơn
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

        if (userData.containsKey('isOnline')) {
          _isOnline = userData['isOnline'] ?? true;
        } else {
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

  // 🟢 KÍCH HOẠT VÀ LƯU CUỘC GỌI KHẨN CẤP LỒNG NHAU TRÊN FIRESTORE
  Future<void> triggerEmergencyCallToRelative({
    required String victimUserId,
    required List<dynamic> danhSachNguoiThan,
    required String victimName,
  }) async {
    try {
      for (var nt in danhSachNguoiThan) {
        String callId = _firestore.collection('CuocGoiKhoanCap').doc().id;
        String maNguoiThan = (nt['maNguoiThan'] ?? '').toString();
        debugPrint('👉 [Controller] Đang ghi cho maNguoiThan: $maNguoiThan');

        if (maNguoiThan.isNotEmpty) {
          await _firestore
              .collection('CuocGoiKhoanCap')
              .doc(victimUserId)
              .collection('DanhSachNguoiThan')
              .doc(maNguoiThan)
              .set({
                'idCuocGoi': callId,
                'maNguoiDung': victimUserId,
                'maNguoiThan': maNguoiThan,
                'noiDungDoc':
                    'Xin chào, đây là cuộc gọi tự động khẩn cấp. Người thân của bạn là $victimName đang cần sự trợ giúp gấp.',
                'trangThai': 'dangGoi',
                'thoiGianTao': FieldValue.serverTimestamp(),
              });
          debugPrint(
            '✅ [Controller] Đã ghi thành công cho người thân: $maNguoiThan',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [Controller] Lỗi Firestore: $e');
    }
  }

  /// Phương thức chuyển vai trò về 'vaitro_nguoidung'
  Future<bool> chuyenVaiTroNguoiDung() async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      await _firestore.collection('NguoiDung').doc(_userID).update({
        'maVaiTro': 'vaitro_nguoidung',
      });

      maVaiTro = 'vaitro_nguoidung';
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

  //--------- Quét người dùng xung quanh (ĐÃ ĐƯỢC TỐI ƯU REALTIME TỐC ĐỘ CAO) -------------//

  /// Lắng nghe người dùng xung quanh và đọc danh sách người thân
  void listenToNearbyUsers({double maxRadiusInMeters = 100.0}) {
    _usersNearbySubscription?.cancel();

    // 🟢 Nếu Cứu hộ viên đang Offline hoặc chưa có tọa độ GPS -> Dừng quét
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

            // 🟢 Lọc bán kính linh hoạt (Khuyên dùng 200m để bù trừ sai số GPS)
            if (distanceInMeters <= maxRadiusInMeters) {
              String userId = doc.id;

              // 🟢 TRUY VẤN NGUỜI THÂN SONG SONG (DÙNG FUTURE.WAIT ĐỂ TRÁNH NGHẼN STREAM)
              List<Map<String, dynamic>> listNguoiThan = [];
              try {
                QuerySnapshot nguoiThanSnap = await _firestore
                    .collection('NguoiThan')
                    .doc(userId)
                    .collection('DanhSachNguoiThan')
                    .get();

                List<Future<Map<String, dynamic>?>> relativeFutures =
                    nguoiThanSnap.docs.map((ntDoc) async {
                      String maNguoiThan = ntDoc.id;
                      Map<String, dynamic> ntData =
                          ntDoc.data() as Map<String, dynamic>;

                      if (maNguoiThan.isNotEmpty) {
                        DocumentSnapshot userRelativeDoc = await _firestore
                            .collection('NguoiDung')
                            .doc(maNguoiThan)
                            .get();

                        if (userRelativeDoc.exists &&
                            userRelativeDoc.data() != null) {
                          Map<String, dynamic> relativeData =
                              userRelativeDoc.data() as Map<String, dynamic>;
                          return {
                            'maNguoiThan': maNguoiThan,
                            'hoTen': relativeData['hoTen'] ?? 'Chưa cập nhật',
                            'soDienThoai':
                                relativeData['soDienThoai'] ?? 'Chưa cập nhật',
                            'moiQuanHe': ntData['moiQuanHe'] ?? '',
                            'trangThai': ntData['trangThai'] ?? '',
                            'ngayTao': ntData['ngayTao'],
                          };
                        }
                      }
                      return null;
                    }).toList();

                var results = await Future.wait(relativeFutures);
                listNguoiThan = results
                    .whereType<Map<String, dynamic>>()
                    .toList();
              } catch (e) {
                debugPrint('Lỗi đọc NguoiThan/$userId/DanhSachNguoiThan: $e');
              }

              tempUsers.add({
                'userId': userId,
                'hoTen': data['hoTen'] ?? 'Người dùng',
                'soDienThoai': data['soDienThoai'] ?? 'Chưa cập nhật',
                'email': data['email'] ?? 'Chưa cập nhật',
                'diaChi': data['diaChi'] ?? 'Chưa cập nhật',
                'danhSachNguoiThan': listNguoiThan,
                'location': LatLng(userLat, userLng),
                'distance': distanceInMeters,
                'groupColor': Colors.white,
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

    // Đồng bộ vị trí thực tế của Cứu hộ viên lên Firestore NguoiDung
    try {
      await _firestore.collection('NguoiDung').doc(_userID).set({
        'viDo': newPos.latitude,
        'kinhDo': newPos.longitude,
        'isOnline': _isOnline,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi cập nhật vị trí Cứu hộ viên lên Firestore: $e');
    }

    // 🟢 TỰ ĐỘNG KHỞI CHẠY/TÍNH TOÁN LẠI QUÉT XUNG QUANH MỖI KHI CỨU HỘ VIÊN DI CHUYỂN
    if (_isOnline) {
      if (_usersNearbySubscription == null) {
        listenToNearbyUsers();
      }
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
