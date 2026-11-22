// lib/user/TongQuanBacSiTiepNhan/controllers/tongquancontroller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart';
import 'package:cuhokhancap/user/Models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

class RescuerOverviewController {
  final String maYeuCau;
  final double victimLat;
  final double victimLng;

  /// Gọi khi không còn cứu hộ viên nào tiếp nhận (đã xử lý xong dữ liệu)
  final void Function()? onNoRescuerLeft;

  final FirebaseService _fbService = FirebaseService();
  final ValueNotifier<List<TrackingRescuerModel>> trackingListNotifier =
      ValueNotifier([]);

  StreamSubscription? _phanCongSub;
  final Map<String, StreamSubscription> _userLocationSubs = {};

  final Map<String, ChiTietPhanCongCuuHoModel> _latestPhanCongMap = {};
  final List<String> _order = []; // thứ tự ổn định cho số thứ tự 1,2,3
  final Map<String, NguoiDungModel> _usersData = {};
  final Map<String, double> _lastBearings = {};
  final Map<String, double> _renderedBearings = {};
  final Map<String, BitmapDescriptor> _iconCache = {};
  final Map<String, String?> _avatarCache = {};
  final Map<String, String> _syncedStatuses = {};

  final List<String> _iconQueue = [];
  bool _iconWorkerRunning = false;

  bool _isBatchCancelTriggered = false;
  bool _everHadRescuer = false;
  bool _noRescuerHandled = false;
  bool _disposed = false;
  int _lastWrittenCount = -1;
  Timer? _noRescuerTimer;

  RescuerOverviewController({
    required this.maYeuCau,
    required this.victimLat,
    required this.victimLng,
    this.onNoRescuerLeft,
  });

  static const Set<String> _validStatuses = {
    'cuuho_trangthai_phancong_tiepnhan',
    'cuuho_trangthai_phancong_daden',
    'cuuho_trangthai_phancong_dangcuuho',
    'cuuho_trangthai_phancong_hoanthanh',
  };

  // Chỉ gỡ khỏi danh sách khi bản ghi THỰC SỰ rơi vào trạng thái này
  static const Set<String> _leftStatuses = {
    'cuuho_trangthai_phancong_tuchoi',
    'cuuho_trangthai_phancong_dahuy',
    'tuchoi',
    'dahuy',
  };

  void initController() {
    _preloadFromYeuCau();

    _phanCongSub = _fbService.streamPhanCongByYeuCau(maYeuCau).listen((
      danhSachPhanCong,
    ) {
      if (_disposed) return;

      for (var pc in danhSachPhanCong) {
        final uid = pc.maNguoiCuuHo;
        final status = pc.maTrangThaiTiepNhan;

        if (_syncedStatuses[uid] != status) {
          _syncedStatuses[uid] = status;
          _fbService.updateDanhSachPhanCongVien(
            maYeuCau: maYeuCau,
            maNguoiCuuHo: uid,
            trangThai: status,
          );
        }

        if (_validStatuses.contains(status)) {
          _addRescuer(uid, pc);
        } else if (_leftStatuses.contains(status) &&
            _latestPhanCongMap.containsKey(uid)) {
          _removeRescuer(uid); // chỉ gỡ khi bản ghi báo từ chối/hủy
        }
        // Vắng mặt trong snapshot hoặc trạng thái khác -> KHÔNG gỡ (tránh nhấp nháy)
      }

      final acceptedCount = _latestPhanCongMap.length;
      if (acceptedCount > 0 && acceptedCount != _lastWrittenCount) {
        _lastWrittenCount = acceptedCount;
        FirebaseFirestore.instance
            .collection('YeuCauCuuHo')
            .doc(maYeuCau)
            .update({'soNguoiCuuHo': acceptedCount});
      }
      if (acceptedCount >= 3 && !_isBatchCancelTriggered) {
        _isBatchCancelTriggered = true;
        _fbService.cancelRemainingAssignments(maYeuCau);
        _fbService.removeRequestFromRealtimeDB(maYeuCau);
      }

      _emitTrackingListSync();
      _checkNoRescuerLeft();
    });
  }

  void _addRescuer(String uid, ChiTietPhanCongCuuHoModel pc) {
    if (!_order.contains(uid)) _order.add(uid);
    _latestPhanCongMap[uid] = pc;
    _everHadRescuer = true;
    _noRescuerTimer?.cancel();
    _ensureUserLocationListener(uid);
  }

  Future<void> _preloadFromYeuCau() async {
    try {
      final yeuCau = await _fbService.getYeuCauCuuHoById(maYeuCau);
      if (yeuCau == null || _disposed) return;

      yeuCau.danhSachPhanCongVien.forEach((uid, status) {
        if (_validStatuses.contains(status) &&
            !_latestPhanCongMap.containsKey(uid)) {
          _syncedStatuses[uid] = status;
          _addRescuer(
            uid,
            ChiTietPhanCongCuuHoModel(
              maPhanCong: 'pc_$uid',
              maYeuCau: maYeuCau,
              loaiPhanCong: 'Hệ thống',
              maNguoiCuuHo: uid,
              thoiGianGui: DateTime.now(),
              maLoaiPhanCong: 'auto',
              maTrangThaiTiepNhan: status,
            ),
          );
        }
      });
      _emitTrackingListSync();
    } catch (e) {
      debugPrint('Lỗi preload YeuCauCuuHo: $e');
    }
  }

  void _ensureUserLocationListener(String rescuerId) {
    if (_userLocationSubs.containsKey(rescuerId)) return;

    if (!_usersData.containsKey(rescuerId)) {
      _fbService.getUserById(rescuerId).then((user) {
        // chỉ dùng nếu snapshot realtime chưa kịp về (tránh ghi đè dữ liệu mới)
        if (user != null &&
            !_disposed &&
            !_usersData.containsKey(rescuerId) &&
            _latestPhanCongMap.containsKey(rescuerId)) {
          _usersData[rescuerId] = user;
          _lastBearings.putIfAbsent(
            rescuerId,
            () => _calculateBearing(
              user.viDo ?? victimLat,
              user.kinhDo ?? victimLng,
              victimLat,
              victimLng,
            ),
          );
          _scheduleIcon(rescuerId);
          _emitTrackingListSync();
        }
      });
    }

    _userLocationSubs[rescuerId] = FirebaseFirestore.instance
        .collection('NguoiDung')
        .doc(rescuerId)
        .snapshots()
        .listen((docSnap) {
          if (_disposed || !docSnap.exists || docSnap.data() == null) return;
          if (!_latestPhanCongMap.containsKey(rescuerId)) return;

          final newData = NguoiDungModel.fromMap(docSnap.data()!);
          final old = _usersData[rescuerId];

          if (newData.viDo != null && newData.kinhDo != null) {
            if (old?.viDo != null && old?.kinhDo != null) {
              final movedMeters =
                  calculateDistance(
                    old!.viDo!,
                    old.kinhDo!,
                    newData.viDo!,
                    newData.kinhDo!,
                  ) *
                  1000;
              if (movedMeters > 3) {
                _lastBearings[rescuerId] = _calculateBearing(
                  old.viDo!,
                  old.kinhDo!,
                  newData.viDo!,
                  newData.kinhDo!,
                );
              }
            }
            _lastBearings.putIfAbsent(
              rescuerId,
              () => _calculateBearing(
                newData.viDo!,
                newData.kinhDo!,
                victimLat,
                victimLng,
              ),
            );
          }

          _usersData[rescuerId] = newData;
          _scheduleIcon(rescuerId);
          _emitTrackingListSync();
        });
  }

  void _removeRescuer(String rescuerId) {
    _latestPhanCongMap.remove(rescuerId);
    _order.remove(rescuerId);
    _userLocationSubs.remove(rescuerId)?.cancel();
    _usersData.remove(rescuerId);
    _lastBearings.remove(rescuerId);
    _renderedBearings.remove(rescuerId);
    _iconCache.remove(rescuerId);
    _iconQueue.remove(rescuerId);
  }

  // ---------------- ICON: hàng đợi tuần tự ----------------
  double _angleDiff(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  void _scheduleIcon(String id) {
    if (_disposed || !_usersData.containsKey(id)) return;
    final bearing = _lastBearings[id] ?? 0.0;
    final rendered = _renderedBearings[id];
    final need =
        !_iconCache.containsKey(id) ||
        (rendered != null && _angleDiff(rendered, bearing) > 15);
    if (!need || _iconQueue.contains(id)) return;
    _iconQueue.add(id);
    _runIconWorker();
  }

  Future<void> _runIconWorker() async {
    if (_iconWorkerRunning) return;
    _iconWorkerRunning = true;
    try {
      while (_iconQueue.isNotEmpty && !_disposed) {
        final id = _iconQueue.removeAt(0);
        final user = _usersData[id];
        if (user == null || !_latestPhanCongMap.containsKey(id)) continue;
        final bearing = _lastBearings[id] ?? 0.0;
        try {
          final icon = await _createRescuerIcon(user, bearing);
          if (_disposed || !_latestPhanCongMap.containsKey(id)) continue;
          _iconCache[id] = icon;
          _renderedBearings[id] = bearing;
          _emitTrackingListSync();
        } catch (e) {
          debugPrint('Lỗi render icon $id: $e');
        }
      }
    } finally {
      _iconWorkerRunning = false;
    }
  }

  Future<String?> _getAvatar(String uid) async {
    if (_avatarCache.containsKey(uid)) return _avatarCache[uid];
    final raw = await _fbService.getUserAvatarUrl(uid);
    _avatarCache[uid] = raw;
    return raw;
  }

  // ---------------- PHÁT DỮ LIỆU RA UI ----------------
  void _emitTrackingListSync() {
    if (_disposed) return;
    final List<TrackingRescuerModel> newList = [];
    int index = 1;

    for (final rescuerId in _order) {
      final phanCong = _latestPhanCongMap[rescuerId];
      final user = _usersData[rescuerId];
      if (phanCong == null || user == null) continue;

      final uLat = user.viDo ?? victimLat;
      final uLng = user.kinhDo ?? victimLng;
      final distance = calculateDistance(victimLat, victimLng, uLat, uLng);
      int timeMin = (distance / 40.0 * 60).round();
      if (timeMin < 1) timeMin = 1;

      newList.add(
        TrackingRescuerModel(
          index: index++,
          nguoiDung: user,
          phanCong: phanCong,
          distanceKm: distance,
          estimatedTimeMinutes: timeMin,
          markerIcon: _iconCache[rescuerId],
        ),
      );
    }
    trackingListNotifier.value = newList;
  }

  // ---------------- KHÔNG CÒN AI TIẾP NHẬN ----------------
  void _checkNoRescuerLeft() {
    if (_noRescuerHandled || !_everHadRescuer) return;
    if (_latestPhanCongMap.isNotEmpty) {
      _noRescuerTimer?.cancel();
      return;
    }
    // Chờ 1s xác nhận để không kích hoạt nhầm vì snapshot chập chờn.
    // (Chỉ gỡ người khi bản ghi báo từ chối/hủy nên không cần chờ lâu.)
    _noRescuerTimer?.cancel();
    _noRescuerTimer = Timer(const Duration(seconds: 1), () {
      if (_latestPhanCongMap.isEmpty) _handleNoRescuerLeft();
    });
  }

  Future<void> _handleNoRescuerLeft() async {
    if (_noRescuerHandled || _disposed) return;
    _noRescuerHandled = true;
    _phanCongSub?.cancel(); // tránh vòng lặp khi ta tự cập nhật trạng thái

    // 🌟 Báo cho giao diện NGAY (trước đây phải chờ xong cả chục lệnh Firestore
    // nên dialog hiện chậm vài giây). Việc dọn dẹp chạy nền bên dưới và KHÔNG
    // phụ thuộc màn hình còn sống hay không.
    onNoRescuerLeft?.call();

    // Mỗi bước độc lập: một bước lỗi không làm hỏng các bước khác
    Future<void> safe(Future<dynamic> Function() job) async {
      try {
        await job();
      } catch (e) {
        debugPrint('Lỗi dọn dẹp khi không còn người tiếp nhận: $e');
      }
    }

    try {
      final yc = await _fbService.getYeuCauCuuHoById(maYeuCau);

      // Những người còn đang "chờ tiếp nhận" = lời mời đã phát mà chưa ai nhận
      final pendingIds = <String>[
        for (final e in (yc?.danhSachPhanCongVien ?? <String, String>{}).entries)
          if (e.value == 'cuuho_trangthai_phancong_chotiepnhan') e.key,
      ];
      final maNanNhan = yc?.maNguoiYeuCau;

      await Future.wait([
        safe(() => _fbService.cancelRemainingAssignments(maYeuCau)),
        safe(
          () => FirebaseFirestore.instance
              .collection('YeuCauCuuHo')
              .doc(maYeuCau)
              .update({'soNguoiCuuHo': 0}),
        ),
        safe(
          () => _fbService.updateTinhTrangYeuCau(maYeuCau, 'user_tinhtrang_dahuy'),
        ),
        safe(() => _fbService.removeRequestFromRealtimeDB(maYeuCau)),
        if (maNanNhan != null && maNanNhan.isNotEmpty)
          safe(() => _fbService.removeEmergencyNotification(maNanNhan: maNanNhan)),
        safe(() => YeuCauStorageService.clearActiveRequest()),
        // Giải phóng những người bị thu hồi lời mời (chạy song song, không tuần tự)
        for (final uid in pendingIds)
          safe(() async {
            await _fbService.updateDanhSachPhanCongVien(
              maYeuCau: maYeuCau,
              maNguoiCuuHo: uid,
              trangThai: 'cuuho_trangthai_phancong_dahuy',
            );
            await _fbService.updateUserOnlineStatus(
              userId: uid,
              isOnline: true,
              nhanCaCuuHo: false,
            );
          }),
      ]);
    } catch (e) {
      debugPrint('Lỗi xử lý không còn người tiếp nhận: $e');
    }
  }

  // ---------------- TIỆN ÍCH ----------------
  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    double lat1 = startLat * math.pi / 180;
    double lng1 = startLng * math.pi / 180;
    double lat2 = endLat * math.pi / 180;
    double lng2 = endLng * math.pi / 180;
    double dLng = lng2 - lng1;
    double y = math.sin(dLng) * math.cos(lat2);
    double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // _createRescuerIcon(...) GIỮ NGUYÊN, chỉ đổi dòng đầu sang:
  // String? avatarData = await _getAvatar(user.maNguoiDung!);
  Future<BitmapDescriptor> _createRescuerIcon(
    NguoiDungModel user,
    double bearing,
  ) async {
    String? avatarData = await _getAvatar(user.maNguoiDung!);
    String initials = (user.hoTen.isNotEmpty)
        ? user.hoTen.substring(0, 1).toUpperCase()
        : '?';

    Widget avatarContent;
    bool hasImage = false;

    if (avatarData != null && avatarData.trim().isNotEmpty) {
      final cleaned = avatarData.trim();
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        hasImage = true;
        avatarContent = Image.network(
          cleaned,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else {
        final base64Str = cleaned.contains(',')
            ? cleaned.split(',').last.trim()
            : cleaned;
        try {
          final bytes = base64Decode(base64Str);
          hasImage = true;
          avatarContent = Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } catch (_) {
          avatarContent = Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }
    } else {
      avatarContent = Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget markerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: const Icon(
                  Icons.navigation,
                  color: Color(0xFF006A55),
                  size: 36,
                ),
              ),
            ),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasImage ? Colors.white : const Color(0xFF006A55),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: ClipOval(child: avatarContent),
            ),
          ],
        ),
      ),
    );
    return await markerWidget.toBitmapDescriptor(
      waitToRender: const Duration(milliseconds: 150),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void dispose() {
    _disposed = true;
    _noRescuerTimer?.cancel();
    _phanCongSub?.cancel();
    for (var sub in _userLocationSubs.values) {
      sub.cancel();
    }
    trackingListNotifier.dispose();
  }
}
