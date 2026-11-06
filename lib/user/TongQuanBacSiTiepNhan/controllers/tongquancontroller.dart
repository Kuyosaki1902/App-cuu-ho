//lib/user/TongQuanBacSiTiepNhan/controllers/tongquancontroller.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'dart:convert';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RescuerOverviewController {
  final String maYeuCau;
  final double victimLat;
  final double victimLng;
  final FirebaseService _fbService = FirebaseService();

  // Biến chứa danh sách cứu hộ viên realtime để View lắng nghe
  final ValueNotifier<List<TrackingRescuerModel>> trackingListNotifier =
      ValueNotifier([]);

  StreamSubscription? _phanCongSub;
  final Map<String, StreamSubscription> _userLocationSubs = {};
  final Map<String, NguoiDungModel> _usersData = {};
  // Thêm 2 biến này vào đầu class RescuerOverviewController
  final Map<String, LatLng> _prevLocations = {};
  final Map<String, double> _lastBearings = {};
  RescuerOverviewController({
    required this.maYeuCau,
    required this.victimLat,
    required this.victimLng,
  });

  void initController() {
    _phanCongSub = _fbService.streamPhanCongByYeuCau(maYeuCau).listen((
      danhSachPhanCong,
    ) {
      final acceptedList = danhSachPhanCong
          .where(
            (pc) =>
                pc.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_tiepnhan' ||
                pc.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_daden',
          )
          .toList();

      int index = 1;

      for (var phanCong in acceptedList) {
        final rescuerId = phanCong.maNguoiCuuHo;

        if (!_userLocationSubs.containsKey(rescuerId)) {
          _userLocationSubs[rescuerId] = FirebaseFirestore.instance
              .collection('NguoiDung')
              .doc(rescuerId)
              .snapshots()
              .listen((docSnap) {
                if (docSnap.exists && docSnap.data() != null) {
                  final newData = NguoiDungModel.fromMap(docSnap.data()!);

                  // 🌟 LƯU LẠI VỊ TRÍ CŨ TRƯỚC KHI GHI ĐÈ VỊ TRÍ MỚI
                  if (_usersData.containsKey(rescuerId)) {
                    _prevLocations[rescuerId] = LatLng(
                      _usersData[rescuerId]!.viDo ?? 0,
                      _usersData[rescuerId]!.kinhDo ?? 0,
                    );
                  }

                  _usersData[rescuerId] = newData;
                  _updateTrackingList(acceptedList);
                }
              });
        }
      }

      final currentRescuerIds = acceptedList
          .map((e) => e.maNguoiCuuHo)
          .toList();
      _userLocationSubs.keys.toList().forEach((key) {
        if (!currentRescuerIds.contains(key)) {
          _userLocationSubs[key]?.cancel();
          _userLocationSubs.remove(key);
          _usersData.remove(key);
          _prevLocations.remove(key);
          _lastBearings.remove(key);
        }
      });

      _updateTrackingList(acceptedList);
    });
  }

  // Cập nhật lại hàm này
  Future<void> _updateTrackingList(List<dynamic> acceptedList) async {
    List<TrackingRescuerModel> newList = [];
    int index = 1;
    for (var phanCong in acceptedList) {
      final rescuerId = phanCong.maNguoiCuuHo;
      final user = _usersData[rescuerId];

      if (user != null && user.viDo != null && user.kinhDo != null) {
        double distance = calculateDistance(
          victimLat,
          victimLng,
          user.viDo!,
          user.kinhDo!,
        );
        int timeMin = (distance / 40.0 * 60).round();
        if (timeMin < 1) timeMin = 1;

        // 🌟 TÍNH HƯỚNG ĐI TỪ VỊ TRÍ CŨ ĐẾN VỊ TRÍ MỚI
        double bearing = 0.0;
        if (_prevLocations.containsKey(rescuerId)) {
          double pLat = _prevLocations[rescuerId]!.latitude;
          double pLng = _prevLocations[rescuerId]!.longitude;

          // Nếu có di chuyển thì mới tính góc mới
          if (pLat != user.viDo! || pLng != user.kinhDo!) {
            bearing = _calculateBearing(pLat, pLng, user.viDo!, user.kinhDo!);
            _lastBearings[rescuerId] = bearing;
          } else {
            // Đứng yên thì giữ nguyên hướng cũ
            bearing = _lastBearings[rescuerId] ?? 0.0;
          }
        } else {
          // Lần đầu xuất hiện chưa có vị trí cũ -> chỉ tạm về phía nạn nhân
          bearing = _calculateBearing(
            user.viDo!,
            user.kinhDo!,
            victimLat,
            victimLng,
          );
          _lastBearings[rescuerId] = bearing;
        }

        BitmapDescriptor icon = await _createRescuerIcon(user, bearing);

        newList.add(
          TrackingRescuerModel(
            index: index++,
            nguoiDung: user,
            phanCong: phanCong,
            distanceKm: distance,
            estimatedTimeMinutes: timeMin,
            markerIcon: icon,
          ),
        );
      }
    }
    trackingListNotifier.value = newList;
  }

  // 🌟 THUẬT TOÁN TÍNH GÓC CHỈ HƯỚNG TỪ BÁC SĨ TỚI NẠN NHÂN
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

  // 🌟 HÀM VẼ GIAO DIỆN MARKER (AVATAR + MŨI TÊN CHỈ HƯỚNG)
  Future<BitmapDescriptor> _createRescuerIcon(
    NguoiDungModel user,
    double bearing,
  ) async {
    String? avatarData = await _fbService.getUserAvatarUrl(user.maNguoiDung!);
    ImageProvider? avatarProvider;
    String initials = (user.hoTen.isNotEmpty)
        ? user.hoTen.substring(0, 1).toUpperCase()
        : '?';

    if (avatarData != null && avatarData.isNotEmpty) {
      if (avatarData.startsWith('http')) {
        avatarProvider = NetworkImage(avatarData);
      } else {
        String base64Str = avatarData.contains(',')
            ? avatarData.split(',').last
            : avatarData;
        try {
          avatarProvider = MemoryImage(base64Decode(base64Str));
        } catch (_) {}
      }
    }

    Widget markerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Mũi tên điều hướng (Xoay theo góc bearing)
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Transform.translate(
                offset: const Offset(0, -22), // Đẩy mũi tên nhô ra rìa trên
                child: const Icon(
                  Icons.navigation,
                  color: Color(0xFF006A55),
                  size: 36,
                ),
              ),
            ),
            // 2. Avatar tròn luôn nằm thẳng đứng ở giữa
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: avatarProvider != null
                    ? Colors.white
                    : const Color(0xFF006A55),
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
    return await markerWidget.toBitmapDescriptor();
  }

  // Thuật toán Haversine tính khoảng cách (Đường chim bay thực tế)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  void dispose() {
    _phanCongSub?.cancel();
    for (var sub in _userLocationSubs.values) {
      sub.cancel();
    }
    trackingListNotifier.dispose();
  }
}
