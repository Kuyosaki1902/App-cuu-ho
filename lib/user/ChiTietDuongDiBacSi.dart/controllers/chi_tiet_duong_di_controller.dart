// lib/user/ChiTietDuongDi/controllers/chi_tiet_duong_di_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Để backup đo đường chim bay nếu OSRM lỗi

class ChiTietDuongDiController {
  final String maNguoiCuuHo;
  final double startLat;
  final double startLng;
  final double victimLat;
  final double victimLng;
  final String tenBacSi;

  GoogleMapController? mapController;
  StreamSubscription? _locationSub;

  double khoangCachBanDau_OSRM = 0.0;
  double progressValue = 0.05; // Khởi đầu mốc 5% (Đã tiếp nhận)

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
  });

  Future<void> initTracking(Function() onUpdate) async {
    _initVictimMarker();

    // 1. Gọi OSRM lần đầu để chốt Khoảng cách gốc
    khoangCachBanDau_OSRM = await _fetchOSRMRoute(startLat, startLng);

    // 2. Stream vị trí di chuyển thực tế từ Firebase
    _locationSub = FirebaseFirestore.instance
        .collection('NguoiDung')
        .doc(maNguoiCuuHo)
        .snapshots()
        .listen((docSnap) async {
          if (docSnap.exists && docSnap.data() != null) {
            double curLat = docSnap.data()?['viDo'] ?? startLat;
            double curLng = docSnap.data()?['kinhDo'] ?? startLng;

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

          double distanceMeters = route['distance'].toDouble(); // Đo bằng OSRM
          double durationSeconds = route['duration'].toDouble();
          String encodedPolyline = route['geometry'];

          // 1. TEXT UI
          double distanceKm = distanceMeters / 1000;
          distanceText = "${distanceKm.toStringAsFixed(1)} km";

          int minutes = (durationSeconds / 60).round();
          if (minutes < 1) minutes = 1;
          estimatedTime = "$minutes phút";

          DateTime arrival = DateTime.now().add(
            Duration(seconds: durationSeconds.toInt()),
          );
          arrivalTime =
              "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";

          // 2. TÍNH TIẾN TRÌNH & CHẶN LÙI
          if (distanceMeters <= 15.0) {
            progressValue = 1.0;
            trangthaiText = "CỨU HỘ VIÊN ĐÃ ĐẾN NƠI";
            estimatedTime = "0 phút";
          } else {
            if (khoangCachBanDau_OSRM > 0) {
              double currentProgress =
                  (khoangCachBanDau_OSRM - distanceMeters) /
                  khoangCachBanDau_OSRM;
              // 🌟 Clamp chặn lùi
              if (currentProgress > progressValue) {
                progressValue = currentProgress;
              }
              if (progressValue >= 0.99) progressValue = 0.99; // Khóa trần
            }
            trangthaiText = progressValue > 0.8
                ? "SẮP ĐẾN NƠI"
                : "ĐANG DI CHUYỂN TỚI ĐỊA ĐIỂM";
          }

          // 3. VẼ MARKER CỨU HỘ & ĐƯỜNG ĐI OSRM
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
    // Backup dùng đường chim bay nếu API chết
    return Geolocator.distanceBetween(lat, lng, victimLat, victimLng);
  }

  // Thuật toán decode mã Polyline từ Google/OSRM
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

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    Future.delayed(const Duration(milliseconds: 500), () {
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              startLat < victimLat ? startLat : victimLat,
              startLng < victimLng ? startLng : victimLng,
            ),
            northeast: LatLng(
              startLat > victimLat ? startLat : victimLat,
              startLng > victimLng ? startLng : victimLng,
            ),
          ),
          80,
        ),
      );
    });
  }

  void dispose() {
    _locationSub?.cancel();
    mapController?.dispose();
  }
}
