// lib/user/ChiTietDuongDi/controllers/chi_tiet_duong_di_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';

class ChiTietDuongDiController {
  final String maNguoiCuuHo;
  final double startLat;
  final double startLng;
  final double victimLat;
  final double victimLng;
  final String tenBacSi;

  final FirebaseService _fbService = FirebaseService();
  GoogleMapController? mapController;
  StreamSubscription? _locationSub;
  StreamSubscription? _phanCongSub;

  late double currentCurLat;
  late double currentCurLng;

  double khoangCachBanDau_OSRM = 0.0;
  double progressValue = 0.05;
  bool _isAlreadyArrived = false;

  bool isAutoTracking = true;
  Function()? _uiUpdateCallback;

  double _lastBearing = 0.0; // Lưu góc hướng di chuyển trước đó

  String trangthaiText = "ĐANG TÍNH TOÁN LỘ TRÌNH...";
  String estimatedTime = "-- phút";
  String distanceText = "-- km";
  String arrivalTime = "--:--";

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  ChiTietDuongDiController({
    required this.maNguoiCuuHo,
    required this.startLat,
    required this.startLng,
    required this.victimLat,
    required this.victimLng,
    required this.tenBacSi,
  }) {
    currentCurLat = startLat;
    currentCurLng = startLng;
  }

  Future<void> initTracking(Function() onUpdate) async {
    _uiUpdateCallback = onUpdate;
    _initVictimMarker();

    khoangCachBanDau_OSRM = await _fetchOSRMRoute(startLat, startLng);

    final String todayStr = DateTime.now().toString().substring(0, 10);
    _phanCongSub = FirebaseFirestore.instance
        .collection('ChiTietPhanCongCuuHo')
        .doc(maNguoiCuuHo)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['maYeuCau'] != null) {
              String trangThai = data['maTrangThaiTiepNhan'] ?? '';
              if (trangThai == 'cuuho_trangthai_phancong_daden') {
                _isAlreadyArrived = true;
                progressValue = 1.0;
                trangthaiText = "CỨU HỘ VIÊN ĐÃ ĐẾN NƠI";
                estimatedTime = "0 phút";
                _uiUpdateCallback?.call();
              }
            }
          }
        });

    _locationSub = FirebaseFirestore.instance
        .collection('NguoiDung')
        .doc(maNguoiCuuHo)
        .snapshots()
        .listen((docSnap) async {
          if (docSnap.exists && docSnap.data() != null) {
            double curLat = docSnap.data()?['viDo'] ?? startLat;
            double curLng = docSnap.data()?['kinhDo'] ?? startLng;

            // Tính góc hướng di chuyển từ vị trí cũ sang vị trí mới
            double bearing = _calculateBearing(
              currentCurLat,
              currentCurLng,
              curLat,
              curLng,
            );
            if (curLat != currentCurLat || curLng != currentCurLng) {
              _lastBearing = bearing;
            }

            currentCurLat = curLat;
            currentCurLng = curLng;

            NguoiDungModel userModel = NguoiDungModel.fromMap(docSnap.data()!);
            await _updateRouteAndProgress(
              curLat,
              curLng,
              userModel,
              _lastBearing,
              () {
                _uiUpdateCallback?.call();
              },
            );
          }
        });
  }

  void _initVictimMarker() {
    markers.add(
      Marker(
        markerId: const MarkerId('victim_location'),
        position: LatLng(victimLat, victimLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Vị trí nạn nhân'),
      ),
    );
  }

  Future<void> _updateRouteAndProgress(
    double curLat,
    double curLng,
    NguoiDungModel userModel,
    double bearing,
    Function() onUpdate,
  ) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$curLng,$curLat;$victimLng,$victimLat?overview=full&geometries=polyline',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          double distanceMeters = route['distance'].toDouble();
          double durationSeconds = route['duration'].toDouble();
          String encodedPolyline = route['geometry'];

          double distanceKm = distanceMeters / 1000;
          distanceText = "${distanceKm.toStringAsFixed(1)} km";

          int minutes = (durationSeconds / 60).round();
          if (minutes < 1) minutes = 1;

          if (!_isAlreadyArrived) {
            estimatedTime = "$minutes phút";
          }

          DateTime arrival = DateTime.now().add(
            Duration(seconds: durationSeconds.toInt()),
          );
          arrivalTime =
              "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";

          if (!_isAlreadyArrived) {
            if (khoangCachBanDau_OSRM > 0) {
              double currentProgress =
                  (khoangCachBanDau_OSRM - distanceMeters) /
                  khoangCachBanDau_OSRM;
              if (currentProgress > progressValue) {
                progressValue = currentProgress;
              }
              if (progressValue >= 0.99) progressValue = 0.99;
            }
            trangthaiText = progressValue > 0.8
                ? "SẮP ĐẾN NƠI"
                : "ĐANG DI CHUYỂN TỚI ĐỊA ĐIỂM";
          }

          // 🌟 Tạo custom marker dạng Avatar tròn + Mũi tên chỉ hướng giống màn hình tổng quan
          BitmapDescriptor rescuerIcon = await _createRescuerIcon(
            userModel,
            bearing,
          );

          markers.removeWhere((m) => m.markerId.value == 'rescuer_location');
          markers.add(
            Marker(
              markerId: const MarkerId('rescuer_location'),
              position: LatLng(curLat, curLng),
              icon: rescuerIcon,
              anchor: const Offset(0.5, 0.5),
              infoWindow: InfoWindow(title: tenBacSi),
            ),
          );

          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId('osrm_route'),
              points: _decodePolyline(encodedPolyline),
              color: const Color(0xFF006A55),
              width: 5,
            ),
          );

          onUpdate();

          if (isAutoTracking) {
            fitRouteBounds();
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi OSRM: $e");
    }
  }

  // Thuật toán tính góc hướng di chuyển
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

  // Hàm render Widget ra BitmapDescriptor cho Marker
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

  Future<double> _fetchOSRMRoute(double lat, double lng) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$lng,$lat;$victimLng,$victimLat?overview=false',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return data['routes'][0]['distance'].toDouble();
        }
      }
    } catch (e) {}
    return Geolocator.distanceBetween(lat, lng, victimLng, victimLat);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  void disableAutoTracking() {
    if (isAutoTracking) {
      isAutoTracking = false;
      _uiUpdateCallback?.call();
    }
  }

  void enableAutoTracking() {
    isAutoTracking = true;
    fitRouteBounds();
    _uiUpdateCallback?.call();
  }

  // 🌟 Đẩy padding bounds rộng hơn (120 thay vì 80) để bản đồ tự động lùi lên trên, không bị che bởi bottom sheet
  void fitRouteBounds() {
    if (mapController == null) return;
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            currentCurLat < victimLat ? currentCurLat : victimLat,
            currentCurLng < victimLng ? currentCurLng : victimLng,
          ),
          northeast: LatLng(
            currentCurLat > victimLat ? currentCurLat : victimLat,
            currentCurLng > victimLng ? currentCurLng : victimLng,
          ),
        ),
        120, // Tăng khoảng đệm để không bị bottom sheet che lấp
      ),
    );
  }

  Future<void> moveToVictim() async {
    disableAutoTracking();
    if (mapController != null) {
      double currentZoom = await mapController!.getZoomLevel();
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(victimLat, victimLng),
            zoom: currentZoom,
          ),
        ),
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    Future.delayed(const Duration(milliseconds: 500), () {
      enableAutoTracking();
    });
  }

  void dispose() {
    _locationSub?.cancel();
    _phanCongSub?.cancel();
    mapController?.dispose();
  }
}
