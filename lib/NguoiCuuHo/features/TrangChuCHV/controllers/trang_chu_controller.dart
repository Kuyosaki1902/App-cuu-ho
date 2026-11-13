import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cuhokhancap/NguoiCuuHo/Models/nguoidungmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// ngoài class:
Uint8List? _decodeB64(String? s) => TrangChuController.bytesFromBase64(s);

class TrangChuController extends ChangeNotifier with WidgetsBindingObserver {
  /// Bán kính quét người xung quanh (dùng chung cho controller, map, header).
  static const double kNearbyRadiusMeters = 10.0;
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _usersNearbySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _completedRescuesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- STATE ---
  LatLng? _currentPosition;
  double? _gpsAccuracy;
  bool _isLoadingLocation = true;
  bool _locationReady = false;
  bool _isOnline = true;
  String? name;
  String? role;
  String? maVaiTro;
  int capDoUyTin = 1;
  bool _isDisposed = false;
  String _userID = '';
  int _soLuongCaHoanThanh = 0;
  List<Map<String, dynamic>> _nearbyUsers = [];
  NguoiDungModel? _currentUserModel;
  Uint8List? _avatarBytes;

  // --- Bộ đếm giờ trực (theo đồng hồ thực, không notify toàn cục) ---
  Timer? _timer;
  int _onlineSeconds = 0;
  int _baseSeconds = 0;
  DateTime? _onlineSince;
  String _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final ValueNotifier<int> onlineSecondsNotifier = ValueNotifier<int>(0);

  // --- Thông báo ca ---
  List<Map<String, dynamic>> _danhSachThongBao = [];
  int _soThongBaoChuaDoc = 0;

  // --- Getters ---
  NguoiDungModel? get currentUserModel => _currentUserModel;
  LatLng? get currentPosition => _currentPosition;
  double? get gpsAccuracy => _gpsAccuracy;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isOnline => _isOnline;
  int get soLuongCaHoanThanh => _soLuongCaHoanThanh;
  String get userID => _userID;
  int get onlineSeconds => _onlineSeconds;
  List<Map<String, dynamic>> get nearbyUsers => _nearbyUsers;
  List<Map<String, dynamic>> get danhSachThongBao => _danhSachThongBao;
  int get soThongBaoChuaDoc => _soThongBaoChuaDoc;
  Uint8List? get avatarBytes => _avatarBytes;

  TrangChuController(String userId) {
    _userID = userId;
    WidgetsBinding.instance.addObserver(this);
    _isOnline = true;
    initLocationService();
    _initAndCheckNewDayTimer();
    fetchFullUserData(_userID).then((_) => _loadAvatar());
    _listenToTodayCompletedRescues();
    _listenToNotifications();
    // Đồng bộ trạng thái "đang trực" lên Firestore ngay khi mở app
    _pushDutyStatus(true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _usersNearbySubscription?.cancel();
    _completedRescuesSubscription?.cancel();
    _notificationSubscription?.cancel(); // 🟢 trước đây bị bỏ sót
    _timer?.cancel();
    mapController?.dispose();
    onlineSecondsNotifier.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      _checkDayRollover();
      if (_locationReady) {
        _startPositionStream();
      } else {
        initLocationService(); // trước đó thiếu GPS/quyền -> thử lại
      }
    }
  }

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ---------------------------------------------------------------------------
  // THÔNG BÁO / SỐ CA
  // ---------------------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _assignmentsRef(String dayStr) {
    return _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(_userID)
        .collection('DanhSachNgay')
        .doc(dayStr)
        .collection('DanhSachPhanCong');
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();
    if (_userID.isEmpty) return;

    // Không dùng orderBy trên Firestore: doc thiếu 'thoiGianTao' sẽ bị loại ngầm.
    _notificationSubscription = _assignmentsRef(_todayStr()).snapshots().listen(
      (snapshot) {
        if (_isDisposed) return;
        final list = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        int ms(dynamic v) => v is Timestamp ? v.millisecondsSinceEpoch : 0;
        list.sort(
          (a, b) => ms(b['thoiGianTao']).compareTo(ms(a['thoiGianTao'])),
        );

        _danhSachThongBao = list;
        _soThongBaoChuaDoc = list
            .where(
              (i) =>
                  i['maTrangThaiTiepNhan'] ==
                  'cuuho_trangthai_phancong_chotiepnhan',
            )
            .length;
        notifyListeners();
      },
      onError: (e) => debugPrint('Lỗi nghe thông báo: $e'),
    );
  }

  void _listenToTodayCompletedRescues() {
    _completedRescuesSubscription?.cancel();
    if (_userID.isEmpty) return;

    final todayStr = _todayStr();
    _completedRescuesSubscription = _assignmentsRef(todayStr)
        .where(
          'maTrangThaiTiepNhan',
          isEqualTo: 'cuuho_trangthai_phancong_hoanthanh',
        )
        .snapshots()
        .listen((snapshot) {
          if (_isDisposed) return;
          _soLuongCaHoanThanh = snapshot.docs.length;
          notifyListeners();
          debugPrint(
            '✅ Số ca hoàn thành hôm nay ($todayStr): $_soLuongCaHoanThanh',
          );
        }, onError: (e) => debugPrint('Lỗi đếm số ca hoàn thành: $e'));
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  // ---------------------------------------------------------------------------
  // GIỜ TRỰC
  // ---------------------------------------------------------------------------
  Future<void> _initAndCheckNewDayTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = _todayStr();

    final dateKey = 'saved_online_date_$_userID';
    final secondsKey = 'saved_online_seconds_$_userID';

    final savedDate = prefs.getString(dateKey);
    if (savedDate == null || savedDate != currentDate) {
      _onlineSeconds = 0;
      await prefs.setString(dateKey, currentDate);
      await prefs.setInt(secondsKey, 0);
    } else {
      _onlineSeconds = prefs.getInt(secondsKey) ?? 0;
    }
    _todayDateStr = currentDate;
    onlineSecondsNotifier.value = _onlineSeconds;

    if (_isOnline && !_isDisposed) {
      _startTimer();
    }
  }

  /// Bật/tắt trực chiến.
  void toggleOnline(bool val) {
    _checkDayRollover();
    _isOnline = val;

    if (val) {
      _startTimer();
      _lastPushedAt = null; // ép đẩy vị trí ngay
      listenToNearbyUsers();
      if (_currentPosition != null) {
        _pushLocationThrottled(_currentPosition!);
      }
    } else {
      _stopTimer();
      _usersNearbySubscription?.cancel();
      _usersNearbySubscription = null;
      _nearbyUsers = [];
    }
    notifyListeners();
    _pushDutyStatus(val);
  }

  /// Ghi trạng thái trực lên Firestore (đã sửa lỗi đảo ngược `!_isOnline`).
  Future<void> _pushDutyStatus(bool onDuty) async {
    if (_userID.isEmpty) return;
    try {
      await _firestore.collection('NguoiDung').doc(_userID).set({
        'nhanCaCuuHo': onDuty,
        'isOnline': onDuty,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái trực: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _onlineSince = DateTime.now();
    _baseSeconds = _onlineSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      _checkDayRollover();
      if (_onlineSince == null) return;
      _onlineSeconds =
          _baseSeconds + DateTime.now().difference(_onlineSince!).inSeconds;
      onlineSecondsNotifier.value = _onlineSeconds;
      if (_onlineSeconds % 15 == 0) _saveOnlineSeconds();
    });
  }

  void _stopTimer() {
    if (_onlineSince != null) {
      _onlineSeconds =
          _baseSeconds + DateTime.now().difference(_onlineSince!).inSeconds;
      _onlineSince = null;
    }
    _timer?.cancel();
    onlineSecondsNotifier.value = _onlineSeconds;
    _saveOnlineSeconds();
  }

  /// Qua 00:00: reset giờ trực và nghe lại các collection theo ngày mới.
  void _checkDayRollover() {
    final nowStr = _todayStr();
    if (nowStr == _todayDateStr) return;

    _todayDateStr = nowStr;
    _onlineSeconds = 0;
    _baseSeconds = 0;
    if (_onlineSince != null) _onlineSince = DateTime.now();
    onlineSecondsNotifier.value = 0;
    _saveOnlineSeconds();

    _listenToTodayCompletedRescues();
    _listenToNotifications();
  }

  Future<void> _saveOnlineSeconds() async {
    if (_userID.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_online_date_$_userID', _todayDateStr);
      await prefs.setInt('saved_online_seconds_$_userID', _onlineSeconds);
    } catch (e) {
      debugPrint('Lỗi lưu giờ trực: $e');
    }
  }

  String get formattedOnlineTime {
    final hours = _onlineSeconds ~/ 3600;
    final minutes = (_onlineSeconds % 3600) ~/ 60;
    final seconds = _onlineSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  // ---------------------------------------------------------------------------
  // GPS & BẢN ĐỒ
  // ---------------------------------------------------------------------------
  bool _initializingLocation = false;

  Future<bool> _ensureLocationPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission(); // chờ người dùng bấm xong
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  Future<void> initLocationService() async {
    if (_initializingLocation) return; // chống gọi chồng
    _initializingLocation = true;
    _isLoadingLocation = true;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      if (!await _ensureLocationPermission()) return;
      if (_isDisposed) return;
      _locationReady = true;

      // Quyền xong rồi mới xin thông báo (tránh 2 hộp thoại chồng nhau)
      unawaited(Permission.notification.request());

      // 1) Vị trí cache: hiện map gần như tức thì
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          await _updateLocationOnMap(
            LatLng(last.latitude, last.longitude),
            accuracy: last.accuracy,
          );
        }
      } catch (e) {
        debugPrint('Lỗi last known: $e');
      }

      // 2) Bật stream sớm: không phụ thuộc getCurrentPosition có timeout hay không
      _startPositionStream();

      // 3) Lấy vị trí chính xác, cho thời gian dài hơn
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        await _updateLocationOnMap(
          LatLng(position.latitude, position.longitude),
          accuracy: position.accuracy,
        );
      } catch (e) {
        debugPrint('Lỗi lấy vị trí chính xác (stream vẫn đang chạy): $e');
      }
    } finally {
      _isLoadingLocation = false;
      _initializingLocation = false;
      notifyListeners();
    }
  }

  void _startPositionStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen(
          (Position p) => _updateLocationOnMap(
            LatLng(p.latitude, p.longitude),
            accuracy: p.accuracy,
          ),
          onError: (e) => debugPrint('Lỗi stream GPS: $e'),
        );
  }

  // Throttle ghi vị trí lên Firestore
  LatLng? _lastPushedPosition;
  DateTime? _lastPushedAt;

  Future<void> _pushLocationThrottled(LatLng pos) async {
    if (!_isOnline || _userID.isEmpty) return;

    final now = DateTime.now();
    if (_lastPushedPosition != null && _lastPushedAt != null) {
      final moved = Geolocator.distanceBetween(
        _lastPushedPosition!.latitude,
        _lastPushedPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      final elapsed = now.difference(_lastPushedAt!);
      if (moved < 5 && elapsed < const Duration(seconds: 15)) return;
    }
    _lastPushedPosition = pos;
    _lastPushedAt = now;

    try {
      await _firestore.collection('NguoiDung').doc(_userID).set({
        'viDo': pos.latitude,
        'kinhDo': pos.longitude,
        'isOnline': true,
        'capNhatLuc': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi cập nhật vị trí CHV lên Firestore: $e');
    }
  }

  LatLng? _lastAnimatedPosition;

  Future<void> _updateLocationOnMap(LatLng newPos, {double? accuracy}) async {
    if (_isDisposed) return;
    _currentPosition = newPos;
    if (accuracy != null) _gpsAccuracy = accuracy;
    _isLoadingLocation = false;
    notifyListeners();

    // Camera: chỉ dịch chuyển khi nhích > 5m, giữ nguyên zoom
    if (mapController != null) {
      final last = _lastAnimatedPosition;
      if (last == null ||
          Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                newPos.latitude,
                newPos.longitude,
              ) >
              5.0) {
        _lastAnimatedPosition = newPos;
        try {
          mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
        } catch (e) {
          debugPrint('Bỏ qua lỗi map đã dispose: $e');
        }
      }
    }

    if (_isOnline) {
      if (_usersNearbySubscription == null) {
        listenToNearbyUsers();
      } else {
        _recomputeNearby(); // 🟢 tự di chuyển cũng phải tính lại
      }
      await _pushLocationThrottled(newPos); // chỉ ghi khi đang trực
    }
  }

  Future<void> centerMapOnCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      _gpsAccuracy = position.accuracy;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi căn giữa bản đồ: $e');
    }

    if (_isDisposed || mapController == null || _currentPosition == null) {
      return;
    }
    try {
      final zoom = await mapController!.getZoomLevel();
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, zoom),
      );
    } catch (e) {
      debugPrint('Lỗi animate camera: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DỮ LIỆU NGƯỜI DÙNG
  // ---------------------------------------------------------------------------
  Future<void> fetchFullUserData(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('NguoiDung')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = Map<String, dynamic>.from(userDoc.data()!);
        userData['maNguoiDung'] ??= userId;

        _currentUserModel = NguoiDungModel.fromMap(userData);
        name = userData['hoTen'] ?? 'Chưa cập nhật';
        maVaiTro = userData['maVaiTro'] ?? '';
        capDoUyTin = (userData['capDoUyTin'] as num?)?.toInt() ?? 1;
        // 🟢 Không đặt _isOnline = true ở đây nữa (đè trạng thái nghỉ của CHV)
      }

      if (maVaiTro == 'vaitro_cuuhococc') {
        final profileDoc = await _firestore
            .collection('HoSoCuuHoCoCCHN')
            .doc(userId)
            .get();

        if (profileDoc.exists && profileDoc.data() != null) {
          final profileData = profileDoc.data()!;
          role =
              profileData['tenChuyenNganh'] ??
              profileData['chuyenNganh'] ??
              'Cứu hộ viên có CCHN';
        } else {
          role = 'Cứu hộ viên không có CCHN';
        }
      } else if (maVaiTro != null && maVaiTro!.isNotEmpty) {
        final roleDoc = await _firestore
            .collection('VaiTro')
            .doc(maVaiTro)
            .get();
        if (roleDoc.exists && roleDoc.data() != null) {
          role = roleDoc.data()!['vaiTro'] ?? 'Đang cập nhật';
        } else {
          role = 'Cứu hộ viên không CCHN';
        }
      } else {
        role = 'Đang cập nhật';
      }
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu Firestore: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> chuyenVaiTroNguoiDung() async {
    try {
      await _firestore.collection('NguoiDung').doc(_userID).update({
        'maVaiTro': 'vaitro_nguoidung',
      });
      maVaiTro = 'vaitro_nguoidung';
      await fetchFullUserData(_userID);
      return true;
    } catch (e) {
      debugPrint('Lỗi khi chuyển vai trò: $e');
      return false;
    }
  }

  /// Tải avatar 1 lần, cache dạng bytes (không query lại mỗi lần build).
  Future<void> _loadAvatar() async {
    if (_isDisposed) return;
    _avatarBytes = await compute(_decodeB64, await getAvatarBase64(_userID));
    notifyListeners();
  }

  Future<String?> getAvatarBase64(String maNguoiDung) async {
    try {
      final phanLoaiSnap = await _firestore
          .collection('PhanLoaiAnh')
          .where('tenPhanLoaiAnh', isEqualTo: 'Ảnh đại diện')
          .limit(1)
          .get();
      if (phanLoaiSnap.docs.isEmpty) return null;

      final maPhanLoaiAvatar = phanLoaiSnap.docs.first.id;
      final luuAnhSnap = await _firestore
          .collection('LuuAnh')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .where('maPhanLoaiAnh', isEqualTo: maPhanLoaiAvatar)
          .limit(1)
          .get();

      if (luuAnhSnap.docs.isNotEmpty) {
        final data = luuAnhSnap.docs.first.data();
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
      final clean = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(clean.trim());
    } catch (e) {
      debugPrint('Lỗi giải mã Base64: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // GỌI NGƯỜI THÂN
  // ---------------------------------------------------------------------------
  /// Trả về true nếu có ít nhất 1 cuộc gọi mới được tạo.
  /// Bỏ qua người thân đang trong trạng thái 'dangGoi' (chống bấm lặp).
  Future<bool> triggerEmergencyCallToRelative({
    required String victimUserId,
    required List<dynamic> danhSachNguoiThan,
    required String victimName,
  }) async {
    try {
      int created = 0;
      for (final nt in danhSachNguoiThan) {
        final maNguoiThan = (nt['maNguoiThan'] ?? '').toString();
        if (maNguoiThan.isEmpty) continue;

        final ref = _firestore
            .collection('CuocGoiKhoanCap')
            .doc(victimUserId)
            .collection('DanhSachNguoiThan')
            .doc(maNguoiThan);

        final existing = await ref.get();
        if (existing.exists && existing.data()?['trangThai'] == 'dangGoi') {
          continue;
        }

        await ref.set({
          'idCuocGoi': _firestore.collection('CuocGoiKhoanCap').doc().id,
          'maNguoiDung': victimUserId,
          'maNguoiThan': maNguoiThan,
          'maCuuHoVien': _userID, // truy vết ai kích hoạt
          'noiDungDoc':
              'Xin chào, đây là cuộc gọi tự động khẩn cấp. Người thân của bạn là $victimName đang cần sự trợ giúp gấp.',
          'trangThai': 'dangGoi',
          'thoiGianTao': FieldValue.serverTimestamp(),
        });
        created++;
      }
      return created > 0;
    } catch (e) {
      debugPrint('❌ [Controller] Lỗi Firestore: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // QUÉT NGƯỜI XUNG QUANH
  // ---------------------------------------------------------------------------
  int _nearbySeq = 0;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _onlineDocs = [];
  final Map<String, List<Map<String, dynamic>>> _relativesCache = {};

  void listenToNearbyUsers() {
    _usersNearbySubscription?.cancel();
    _usersNearbySubscription = null;

    if (!_isOnline) {
      _nearbyUsers = [];
      notifyListeners();
      return;
    }

    _usersNearbySubscription = _firestore
        .collection('NguoiDung')
        .where('isOnline', isEqualTo: true)
        .where('maVaiTro', isEqualTo: 'vaitro_nguoidung') // lọc ở server
        .snapshots()
        .listen((snapshot) {
          _onlineDocs = snapshot.docs;
          _recomputeNearby();
        }, onError: (e) => debugPrint('Lỗi quét người xung quanh: $e'));
  }

  Future<void> _recomputeNearby() async {
    if (_isDisposed || !_isOnline || _currentPosition == null) return;
    final seq = ++_nearbySeq;
    final me = _currentPosition!;
    final List<Map<String, dynamic>> temp = [];

    for (final doc in _onlineDocs) {
      if (doc.id == _userID) continue;
      final data = doc.data();
      if (data['viDo'] == null || data['kinhDo'] == null) continue;

      final userLat = (data['viDo'] as num).toDouble();
      final userLng = (data['kinhDo'] as num).toDouble();
      final dist = Geolocator.distanceBetween(
        me.latitude,
        me.longitude,
        userLat,
        userLng,
      );
      if (dist > kNearbyRadiusMeters) continue;

      // Cache người thân: tránh N+1 query mỗi lần snapshot / mỗi lần di chuyển
      List<Map<String, dynamic>>? relatives = _relativesCache[doc.id];
      if (relatives == null) {
        relatives = await _fetchRelatives(doc.id);
        _relativesCache[doc.id] = relatives;
      }

      temp.add({
        'userId': doc.id,
        'hoTen': data['hoTen'] ?? 'Người dùng',
        'soDienThoai': data['soDienThoai'] ?? 'Chưa cập nhật',
        'email': data['email'] ?? 'Chưa cập nhật',
        'diaChi': data['diaChi'] ?? 'Chưa cập nhật',
        'danhSachNguoiThan': relatives,
        'location': LatLng(userLat, userLng),
        'distance': dist,
      });
    }

    // Đã có lần tính mới hơn -> bỏ kết quả cũ (tránh ghi đè sai thứ tự)
    if (seq != _nearbySeq || _isDisposed) return;
    _nearbyUsers = temp;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _fetchRelatives(String userId) async {
    try {
      final nguoiThanSnap = await _firestore
          .collection('NguoiThan')
          .doc(userId)
          .collection('DanhSachNguoiThan')
          .get();

      final futures = nguoiThanSnap.docs.map((ntDoc) async {
        final maNguoiThan = ntDoc.id;
        final ntData = ntDoc.data();
        if (maNguoiThan.isEmpty) return null;

        final userRelativeDoc = await _firestore
            .collection('NguoiDung')
            .doc(maNguoiThan)
            .get();
        if (!userRelativeDoc.exists || userRelativeDoc.data() == null) {
          return null;
        }
        final relativeData = userRelativeDoc.data()!;
        return <String, dynamic>{
          'maNguoiThan': maNguoiThan,
          'hoTen': relativeData['hoTen'] ?? 'Chưa cập nhật',
          'soDienThoai': relativeData['soDienThoai'] ?? 'Chưa cập nhật',
          'moiQuanHe': ntData['moiQuanHe'] ?? '',
          'trangThai': ntData['trangThai'] ?? '',
          'ngayTao': ntData['ngayTao'],
        };
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Lỗi đọc NguoiThan/$userId/DanhSachNguoiThan: $e');
      return [];
    }
  }
}
