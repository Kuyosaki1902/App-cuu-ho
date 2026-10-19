// lib/GiaoDienDangTimKiem/controllers/tim_kiem_cuu_ho_controller.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TimKiemCuuHoController {
  GoogleMapController? mapController;

  bool isLoading = true;

  // Tọa độ mặc định (Sẽ cập nhật ngay khi lấy xong GPS)
  LatLng currentDeviceLocation = const LatLng(10.7769, 106.6993);

  final Set<Circle> circles = {};
  final Set<Marker> markers = {}; // 🌟 Danh sách Marker định vị

  // Hàm lấy vị trí GPS thực tế từ thiết bị
  Future<void> fetchCurrentLocation(Function() onComplete) async {
    isLoading = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        isLoading = false;
        onComplete();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoading = false;
          onComplete();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        isLoading = false;
        onComplete();
        return;
      }

      // Lấy vị trí thực tế hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentDeviceLocation = LatLng(position.latitude, position.longitude);
      updateMapOverlays();
      moveToCurrentLocation();
    } catch (e) {
      debugPrint('Lỗi lấy GPS: $e');
    } finally {
      isLoading = false;
      onComplete();
    }
  }

  // Cập nhật Vòng tròn bán kính và Marker vị trí thiết bị hiện tại
  void updateMapOverlays() {
    circles.clear();
    markers.clear();

    // 1. Thêm Marker điểm cấp cứu (Chấm đỏ/xanh biểu tượng vị trí của bạn)
    markers.add(
      Marker(
        markerId: const MarkerId('current_device_marker'),
        position: currentDeviceLocation,
        infoWindow: const InfoWindow(
          title: 'Vị trí cấp cứu của bạn',
          snippet: 'Đang phát tín hiệu tìm cứu hộ...',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // 2. Vòng tròn bán kính quét 1.2km
    circles.add(
      Circle(
        circleId: const CircleId('scan_radius_outer'),
        center: currentDeviceLocation,
        radius: 1200,
        fillColor: const Color(0xFF006A55).withOpacity(0.12),
        strokeColor: const Color(0xFF006A55).withOpacity(0.3),
        strokeWidth: 2,
      ),
    );

    // 3. Vòng tròn tâm nhỏ ngay vị trí hiện tại
    circles.add(
      Circle(
        circleId: const CircleId('scan_radius_inner'),
        center: currentDeviceLocation,
        radius: 400,
        fillColor: const Color(0xFF006A55).withOpacity(0.2),
        strokeColor: Colors.transparent,
        strokeWidth: 0,
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    moveToCurrentLocation();
  }

  void moveToCurrentLocation() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentDeviceLocation, zoom: 15.5),
      ),
    );
  }
}
