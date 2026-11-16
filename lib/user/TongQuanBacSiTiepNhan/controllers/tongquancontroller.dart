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

  final ValueNotifier<List<TrackingRescuerModel>> trackingListNotifier =
      ValueNotifier([]);

  StreamSubscription? _phanCongSub;
  final Map<String, StreamSubscription> _userLocationSubs = {};
  final Map<String, NguoiDungModel> _usersData = {};
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
      const validStatuses = {
        'cuuho_trangthai_phancong_tiepnhan',
        'cuuho_trangthai_phancong_daden',
        'cuuho_trangthai_phancong_dangcuuho',
        'cuuho_trangthai_phancong_hoanthanh',
      };
      final acceptedList = danhSachPhanCong
          .where((pc) => validStatuses.contains(pc.maTrangThaiTiepNhan))
          .toList();

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

        double bearing = 0.0;
        if (_prevLocations.containsKey(rescuerId)) {
          double pLat = _prevLocations[rescuerId]!.latitude;
          double pLng = _prevLocations[rescuerId]!.longitude;

          if (pLat != user.viDo! || pLng != user.kinhDo!) {
            bearing = _calculateBearing(pLat, pLng, user.viDo!, user.kinhDo!);
            _lastBearings[rescuerId] = bearing;
          } else {
            bearing = _lastBearings[rescuerId] ?? 0.0;
          }
        } else {
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

  // 🌟 VẼ MARKER (AVATAR + MŨI TÊN CHỈ HƯỚNG) KHÔNG BỊ TRẮNG
  Future<BitmapDescriptor> _createRescuerIcon(
    NguoiDungModel user,
    double bearing,
  ) async {
    String? avatarData = await _fbService.getUserAvatarUrl(user.maNguoiDung!);
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
    _phanCongSub?.cancel();
    for (var sub in _userLocationSubs.values) {
      sub.cancel();
    }
    trackingListNotifier.dispose();
  }
}
