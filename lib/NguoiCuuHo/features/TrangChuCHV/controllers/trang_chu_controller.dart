import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cuhokhancap/NguoiCuuHo/Models/nguoidungmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';

class TrangChuController extends ChangeNotifier with WidgetsBindingObserver {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _usersNearbySubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _completedRescuesSubscription;

  // --- NƠI LƯU TRỮ TRẠNG THÁI (STATE) ---
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isOnline = true;
  String? name;
  String? role;
  String? image;
  String? maVaiTro;
  Timer? _timer;
  bool _isDisposed = false;
  String _userID = '';
  int _soLuongCaTiepNhan = 0;
  int _onlineSeconds = 0;
  String _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<Map<String, dynamic>> _nearbyUsers = [];
  NguoiDungModel? _currentUserModel;
  NguoiDungModel? get currentUserModel => _currentUserModel;

  // Lấy UID động từ FirebaseAuth, nếu chưa đăng nhập mới dùng ID mặc định
  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userID = prefs.getString('maNguoiDung_daLuu') ?? '';
  }

  //String get _userID => FirebaseAuth.instance.currentUser?.uid ?? 'nguoidung2';

  // Getters cho UI đọc dữ liệu
  LatLng? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  Timer? get timer => _timer;
  int get soLuongCaTiepNhan => _soLuongCaTiepNhan;
  String get userID => _userID;
  int get onlineSeconds => _onlineSeconds;
  List<Map<String, dynamic>> get nearbyUsers => _nearbyUsers;
  Timer? _antiOverrideTimer;
  // 🟢 1. Khai báo biến lưu danh sách thông báo & số lượng chưa đọc
  List<Map<String, dynamic>> _danhSachThongBao = [];
  int _soThongBaoChuaDoc = 0;
  List<Map<String, dynamic>> get danhSachThongBao => _danhSachThongBao;
  int get soThongBaoChuaDoc => _soThongBaoChuaDoc;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  TrangChuController(String userId) {
    _userID = userId;
    WidgetsBinding.instance.addObserver(this);

    debugPrint('👉 [Controller Init] Đang khởi tạo cho userID: "$_userID"');

    // 🟢 1. Cập nhật trạng thái true ngay lập tức
    _isOnline = true;
    _updateUserOnlineStatusInFirestore(true);

    // 🟢 2. CHỐNG GHI ĐÈ: Liên tục "bồi" lại true trong 3 giây đầu tiên (mỗi 500ms một lần)
    // Để triệt tiêu hoàn toàn mọi lệnh `false` trễ hạn từ dispose bên phía người dùng.
    int counter = 0;
    _antiOverrideTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (_isDisposed || counter >= 6) {
        // Chạy trong vòng 3 giây (6 lần) là đủ quét sạch mọi lệnh delay cũ
        timer.cancel();
        return;
      }
      counter++;
      _updateUserOnlineStatusInFirestore(true);
    });

    initLocationService();
    _initAndCheckNewDayTimer();
    fetchFullUserData(_userID);
    _listenToTodayCompletedRescues();
    // 🟢 Đảm bảo khởi chạy Service khi userID hợp lệ
    if (_isOnline && _userID.isNotEmpty) {
      _startBackgroundService();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this); // Hủy đăng ký
    _antiOverrideTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _usersNearbySubscription?.cancel();
    mapController?.dispose();
    _completedRescuesSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // 3. Ghi đè hàm này để chặn tuyệt đối việc gọi khi đã dispose
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Khi ứng dụng bị thu nhỏ hoặc chuyển hướng sang màn hình khác / app khác
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _positionStreamSubscription?.cancel();
    }
  }

  // 🟢 2. Trong hàm lắng nghe Realtime thông báo
  void _listenToNotifications() {
    _notificationSubscription?.cancel();
    if (_userID.isEmpty) return;

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _notificationSubscription = _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(_userID)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .orderBy('thoiGianTao', descending: true) // Sắp xếp ca mới nhất lên đầu
        .snapshots()
        .listen((snapshot) {
          if (!_isDisposed) {
            _danhSachThongBao = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            // Đếm các ca đang chờ tiếp nhận (chưa đọc / chưa xử lý)
            _soThongBaoChuaDoc = _danhSachThongBao
                .where(
                  (item) =>
                      item['maTrangThaiTiepNhan'] ==
                      'cuuho_trangthai_phancong_chotiepnhan',
                )
                .length;

            notifyListeners();
          }
        });
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      // Đợi 1 giây để Isolate ngầm sẵn sàng nhận message
      await Future.delayed(const Duration(seconds: 1));
    }
    service.invoke('startListening', {'userId': _userID});
  }

  // 🟢 Hàm lắng nghe số ca có trangThai = 'cuuho_trangthai_phancong_hoanthanh' trong ngày hôm nay
  void _listenToTodayCompletedRescues() {
    _completedRescuesSubscription?.cancel();

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _completedRescuesSubscription = _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(_userID)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .where(
          'maTrangThaiTiepNhan',
          isEqualTo: 'cuuho_trangthai_phancong_hoanthanh',
        )
        .snapshots()
        .listen(
          (snapshot) {
            if (!_isDisposed) {
              _soLuongCaTiepNhan = snapshot.docs.length;
              notifyListeners(); // Cập nhật lại UI ở TrangChuBottomPanel
              debugPrint(
                '✅ Số ca hoàn thành hôm nay ($todayStr): $_soLuongCaTiepNhan',
              );
            }
          },
          onError: (e) {
            debugPrint('Lỗi đếm số ca hoàn thành: $e');
          },
        );
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  // 🟢 1. Khởi tạo thời gian từ SharedPreferences và kiểm tra ngày mới
  Future<void> _initAndCheckNewDayTimer() async {
    final prefs = await SharedPreferences.getInstance();
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Tạo key riêng biệt theo từng User ID
    String dateKey = 'saved_online_date_$_userID';
    String secondsKey = 'saved_online_seconds_$_userID';

    String? savedDate = prefs.getString(dateKey);

    if (savedDate == null || savedDate != currentDate) {
      _onlineSeconds = 0;
      await prefs.setString(dateKey, currentDate);
      await prefs.setInt(secondsKey, 0);
    } else {
      _onlineSeconds = prefs.getInt(secondsKey) ?? 0;
    }
    _todayDateStr = currentDate;
    notifyListeners();

    if (_isOnline) {
      _startTimer();
    }
  }

  // 🟢 2. Cập nhật Bật/Tắt Online & Cập nhật Firestore
  void toggleOnline(bool val) async {
    _checkDayRollover();
    _isOnline = val;

    if (_isOnline) {
      _startTimer();
      listenToNearbyUsers();
      await _startBackgroundService();
    } else {
      _stopTimer();
      _usersNearbySubscription?.cancel(); // Dừng lắng nghe từ Firestore
      _nearbyUsers = [];
      FlutterBackgroundService().invoke('stopListening');
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
    if (_userID.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    String dateKey = 'saved_online_date_$_userID';
    String secondsKey = 'saved_online_seconds_$_userID';

    await prefs.setString(dateKey, _todayDateStr);
    await prefs.setInt(secondsKey, _onlineSeconds);
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
            distanceFilter: 10, // 🟢 Giảm distanceFilter xuống 5m để nhạy hơn
          ),
        ).listen((Position position) {
          _updateLocationOnMap(LatLng(position.latitude, position.longitude));
        });
  }

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
        // Đảm bảo maNguoiDung có dữ liệu
        userData['maNguoiDung'] ??= userId;

        // 🟢 Chuyển đổi dữ liệu Firestore sang NguoiDungModel
        _currentUserModel = NguoiDungModel.fromMap(userData);
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        maVaiTro = userData['maVaiTro'] ?? '';
        _isOnline = true;
        _updateUserOnlineStatusInFirestore(true);
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
          role = 'Cứu hộ viên không có CCHN';
        }
      } else {
        if (maVaiTro != null && maVaiTro!.isNotEmpty) {
          DocumentSnapshot roleDoc = await _firestore
              .collection('VaiTro')
              .doc(maVaiTro)
              .get();

          if (roleDoc.exists && roleDoc.data() != null) {
            Map<String, dynamic> roleData =
                roleDoc.data() as Map<String, dynamic>;
            role = roleData['vaiTro'] ?? 'Đang cập nhật';
          } else {
            role = 'Cứu hộ viên không CCHN';
          }
        } else {
          role = 'Đang cập nhật';
        }
      }
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu Firestore: $e');
    } finally {
      if (!_isDisposed) {
        _isLoadingLocation = false;
        notifyListeners();
      }
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
  // Thêm biến lưu vị trí cũ để check khoảng cách dịch chuyển
  LatLng? _lastAnimatedPosition;

  Future<void> _updateLocationOnMap(LatLng newPos) async {
    _currentPosition = newPos;
    _isLoadingLocation = false;

    try {
      await _firestore.collection('NguoiDung').doc(_userID).set({
        'viDo': newPos.latitude,
        'kinhDo': newPos.longitude,
        'isOnline': _isOnline,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi cập nhật vị trí Cứu hộ viên lên Firestore: $e');
    }

    if (_isOnline && _usersNearbySubscription == null) {
      listenToNearbyUsers();
    }

    notifyListeners();

    // 🟢 CHỈ animateCamera khi vị trí thay đổi đủ lớn (ví dụ > 5-10 mét) hoặc lần đầu tiên,
    // tránh bị gọi liên tục gây giật màn hình mỗi khi GPS nhích từng cm.
    if (mapController != null && !_isDisposed) {
      if (_lastAnimatedPosition == null ||
          Geolocator.distanceBetween(
                _lastAnimatedPosition!.latitude,
                _lastAnimatedPosition!.longitude,
                newPos.latitude,
                newPos.longitude,
              ) >
              5.0) {
        _lastAnimatedPosition = newPos;
        try {
          double currentZoom = await mapController!.getZoomLevel();
          if (mapController != null && !_isDisposed) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                newPos,
                currentZoom < 16 ? 18.2 : currentZoom,
              ),
            );
          }
        } catch (e) {
          debugPrint('Bỏ qua lỗi map đã dispose: $e');
        }
      }
    }
  }

  // 🟢 Hàm chuyên dùng cho nút MyLocation: Ép bản đồ quay về vị trí hiện tại ngay lập tức
  // 🟢 Hàm định vị căn giữa bản đồ nhưng GIỮ NGUYÊN ĐỘ ZOOM hiện tại của người dùng
  Future<void> centerMapOnCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();

      if (mapController != null && _currentPosition != null) {
        // 1. Lấy độ zoom hiện tại mà người dùng đang thu/phóng
        double currentZoom = await mapController!.getZoomLevel();

        // 2. Di chuyển camera về vị trí mới với đúng mức zoom đó
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, currentZoom),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi căn giữa bản đồ: $e');
      if (mapController != null && _currentPosition != null) {
        double currentZoom = await mapController!.getZoomLevel();
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, currentZoom),
        );
      }
    }
  }
}
