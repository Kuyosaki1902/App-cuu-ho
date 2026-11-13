// lib/services/presence_service.dart
//
// Thay thế toàn bộ logic online / đá phiên đang rải rác trong
// FirebaseService.thietLapTrangThaiOnline, Trangchunguoicuuho (_gianhQuyenDangNhap,
// _langNgheBiDaVang, dispose, lifecycle) và DangNhap (ghi maThietBi + delay 4s).
//
// Nguyên tắc:
//  1. Mã thiết bị ỔN ĐỊNH theo lần cài app (không sinh bằng thời gian mỗi lần build/đăng nhập).
//  2. Chỉ MỘT nơi (singleton này) ghi maThietBi / isOnline, gọi 1 lần khi đăng nhập,
//     và stop() 1 lần khi đăng xuất. KHÔNG gọi trong initState/dispose của màn hình.
//  3. Máy bị đá tuyệt đối không ghi isOnline=false (sẽ đè lên máy mới).
//  4. Khi kết nối lại chỉ báo isOnline=true, KHÔNG ghi lại maThietBi (tránh "giành" lại phiên).
//
// LƯU Ý: file này chưa được biên dịch/chạy thử trong môi trường của tôi, hãy chạy
// `flutter analyze` và thử với 2 thiết bị trước khi dùng.

import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mã thiết bị ổn định cho mỗi lần cài app. Gọi [init] một lần trong main()
/// (sau WidgetsFlutterBinding.ensureInitialized()).
class DeviceSession {
  static String? _id;
  static const double kNearbyRadiusMeters = 10;

  static String get id {
    final v = _id;
    if (v == null) {
      throw StateError('Chưa gọi DeviceSession.init() trong main()');
    }
    return v;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var v = prefs.getString('thiet_bi_id');
    if (v == null || v.isEmpty) {
      final r = Random.secure();
      v = List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
      await prefs.setString('thiet_bi_id', v);
    }
    _id = v;
  }
}

class PresenceService {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  factory PresenceService() => _instance;

  static const String _dbUrl =
      'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app';

  FirebaseDatabase get _db =>
      FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: _dbUrl);

  DatabaseReference _userRef(String uid) => _db.ref('NguoiDung/$uid');

  String? _uid;
  bool _kicked = false;
  StreamSubscription<DatabaseEvent>? _deviceSub;
  StreamSubscription<DatabaseEvent>? _connSub;
  VoidCallback? _onKicked;

  /// Tài khoản đang online trên MỘT THIẾT BỊ KHÁC? (dùng ở màn đăng nhập để
  /// quyết định có hiện hộp thoại "đang dùng ở nơi khác" hay không).
  Future<bool> dangOnlineODeviceKhac(String uid) async {
    try {
      final snap = await _userRef(uid).get();
      final v = snap.value;
      if (v is! Map) return false;
      final maThietBi = v['maThietBi']?.toString();
      return v['isOnline'] == true &&
          maThietBi != null &&
          maThietBi != DeviceSession.id;
    } catch (_) {
      return false;
    }
  }

  /// Gọi MỘT lần sau khi đăng nhập thành công / khi tự đăng nhập.
  /// Gọi lại với cùng uid thì chỉ cập nhật callback, không tạo listener mới.
  /// [onKicked] chạy khi có thiết bị khác giành phiên: chỉ nên điều hướng về
  /// màn đăng nhập, KHÔNG ghi gì lên isOnline.
  Future<void> start(String uid, {required VoidCallback onKicked}) async {
    _onKicked = onKicked;
    if (_uid == uid && _deviceSub != null && !_kicked) return;

    await _dungListener();
    _uid = uid;
    _kicked = false;

    final me = DeviceSession.id;
    final ref = _userRef(uid);

    // 1) Giành phiên: ghi mã thiết bị đúng một lần.
    await ref.child('maThietBi').set(me);

    // 2) Nếu server đổi sang mã khác => thiết bị khác đã đăng nhập => mình bị đá.
    _deviceSub = ref.child('maThietBi').onValue.listen((event) async {
      final server = event.snapshot.value?.toString();
      if (server == null || server == me || _kicked) return;
      _kicked = true;
      await _dungListener();
      try {
        // onDisconnect đăng ký theo từng KẾT NỐI: phải hủy ở đây, nếu không khi máy
        // này tắt app nó sẽ ghi isOnline=false đè lên máy mới.
        await ref.child('isOnline').onDisconnect().cancel();
      } catch (_) {}
      _onKicked?.call();
    });

    // 3) Theo dõi kết nối: mỗi lần (kết nối lại) đăng ký onDisconnect rồi báo online.
    //    Mất kết nối (tắt màn hình lâu, đổi mạng) => server tự đặt isOnline=false.
    //    Có mạng lại => đặt true. Không ghi lại maThietBi.
    _connSub = _db.ref('.info/connected').onValue.listen((event) async {
      if (event.snapshot.value != true || _kicked) return;
      try {
        await ref.child('isOnline').onDisconnect().set(false);
        await ref.child('isOnline').set(true);
      } catch (e) {
        debugPrint('Presence: lỗi báo online: $e');
      }
    });
  }

  /// Gọi khi ĐĂNG XUẤT (không gọi trong dispose của màn hình).
  Future<void> stop() async {
    final uid = _uid;
    final biDa = _kicked;
    await _dungListener();
    _uid = null;
    _kicked = false;
    if (uid == null || biDa)
      return; // bị đá: máy mới đang giữ phiên, không đụng vào

    try {
      final ref = _userRef(uid);
      await ref.child('isOnline').onDisconnect().cancel();
      // Chỉ đặt offline nếu phiên vẫn là của thiết bị này.
      await ref.runTransaction((current) {
        final m = (current is Map)
            ? Map<String, dynamic>.from(current)
            : <String, dynamic>{};
        if (m['maThietBi']?.toString() == DeviceSession.id) {
          m['isOnline'] = false;
        }
        return Transaction.success(m);
      });
    } catch (e) {
      debugPrint('Presence.stop: $e');
    }
  }

  Future<void> _dungListener() async {
    await _deviceSub?.cancel();
    await _connSub?.cancel();
    _deviceSub = null;
    _connSub = null;
  }
}
