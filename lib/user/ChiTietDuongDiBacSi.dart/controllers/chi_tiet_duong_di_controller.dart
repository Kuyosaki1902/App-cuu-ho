// lib/user/ChiTietDuongDi/controllers/chi_tiet_duong_di_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ChiTietDuongDiController {
  final String maNguoiCuuHo;
  final double startLat;
  final double startLng;
  final double victimLat;
  final double victimLng;
  final String tenBacSi;

  GoogleMapController? mapController;
  StreamSubscription? _locationSub;
  StreamSubscription?
  _phanCongSub; // 🌟 Thêm stream lắng nghe trạng thái phân công

  late double currentCurLat;
  late double currentCurLng;

  double khoangCachBanDau_OSRM = 0.0;
  double progressValue = 0.05; // Khởi đầu mốc 5% (Đã tiếp nhận)
  bool _isAlreadyArrived = false; // 🌟 Biến cờ kiểm tra đã đến nơi chưa

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
    _initVictimMarker();

    // 1. Gọi OSRM lần đầu để chốt Khoảng cách gốc
    khoangCachBanDau_OSRM = await _fetchOSRMRoute(startLat, startLng);

    // 🌟 2. LẮNG NGHE TRẠNG THÁI TỪ PHÂN CÔNG (ChiTietPhanCongCuuHo)
    // Truy vấn theo cấu trúc subcollection chuẩn của dự án bác
    final String todayStr = DateTime.now().toString().substring(0, 10);
    _phanCongSub = FirebaseFirestore.instance
        .collection('ChiTietPhanCongCuuHo')
        .doc(maNguoiCuuHo)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        // Nếu cấu trúc phân công lưu theo maYeuCau hoặc maPhanCong, ta lắng nghe doc tương ứng.
        // Ở đây ta dùng snapshots trực tiếp trên collection DanhSachPhanCong lọc theo maNguoiCuuHo & maYeuCau
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Kiểm tra đúng yêu cầu cứu hộ hiện tại không
            if (data['maYeuCau'] != null) {
              String trangThai = data['maTrangThaiTiepNhan'] ?? '';
              if (trangThai == 'cuuho_trangthai_phancong_daden') {
                _isAlreadyArrived = true;
                progressValue = 1.0;
                trangthaiText = "CỨU HỘ VIÊN ĐÃ ĐẾN NƠI";
                estimatedTime = "0 phút";
                onUpdate();
              }
            }
          }
        });

    // 3. Stream vị trí di chuyển thực tế từ Firebase (NguoiDung)
    _locationSub = FirebaseFirestore.instance
        .collection('NguoiDung')
        .doc(maNguoiCuuHo)
        .snapshots()
        .listen((docSnap) async {
          if (docSnap.exists && docSnap.data() != null) {
            double curLat = docSnap.data()?['viDo'] ?? startLat;
            double curLng = docSnap.data()?['kinhDo'] ?? startLng;

            currentCurLat = curLat;
            currentCurLng = curLng;

            await _updateRouteAndProgress(curLat, curLng, onUpdate);
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

          // Nếu chưa đến nơi theo trạng thái Firebase thì mới cập nhật ETA theo OSRM
          if (!_isAlreadyArrived) {
            estimatedTime = "$minutes phút";
          }

          DateTime arrival = DateTime.now().add(
            Duration(seconds: durationSeconds.toInt()),
          );
          arrivalTime =
              "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";

          // 🌟 BỎ HOÀN TOÀN LOGIC TỰ ĐỘNG ÉP 15M -> CHỈ TÍNH TIẾN TRÌNH THEO OSRM KHI CHƯA ĐẾN
          if (!_isAlreadyArrived) {
            if (khoangCachBanDau_OSRM > 0) {
              double currentProgress =
                  (khoangCachBanDau_OSRM - distanceMeters) /
                  khoangCachBanDau_OSRM;
              if (currentProgress > progressValue) {
                progressValue = currentProgress;
              }
              // Khóa trần ở 0.99 nếu chưa có tín hiệu "Đã đến" từ cứu hộ viên
              if (progressValue >= 0.99) progressValue = 0.99;
            }
            trangthaiText = progressValue > 0.8
                ? "SẮP ĐẾN NƠI"
                : "ĐANG DI CHUYỂN TỚI ĐỊA ĐIỂM";
          }

          // VẼ MARKER CỨU HỘ & ĐƯỜNG ĐI OSRM
          markers.removeWhere((m) => m.markerId.value == 'rescuer_location');
          markers.add(
            Marker(
              markerId: const MarkerId('rescuer_location'),
              position: LatLng(curLat, curLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
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
        }
      }
    } catch (e) {
      debugPrint("Lỗi OSRM: $e");
    }
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
        80,
      ),
    );
  }

  void moveToVictim() {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(victimLat, victimLng), 16.0),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    Future.delayed(const Duration(milliseconds: 500), () {
      fitRouteBounds();
    });
  }

  void dispose() {
    _locationSub?.cancel();
    _phanCongSub?.cancel(); // 🌟 Hủy stream phân công khi đóng màn hình
    mapController?.dispose();
  }
}
