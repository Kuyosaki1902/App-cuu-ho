//lib/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/chitietphancongcuuhomodel%20.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 🌟 THÊM IMPORT NÀY

class TrackingRescuerModel {
  final int index;
  final NguoiDungModel nguoiDung;
  final ChiTietPhanCongCuuHoModel phanCong;
  final double distanceKm;
  final int estimatedTimeMinutes;
  final BitmapDescriptor? markerIcon; // 🌟 BỔ SUNG TRƯỜNG NÀY

  TrackingRescuerModel({
    required this.index,
    required this.nguoiDung,
    required this.phanCong,
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    this.markerIcon, // 🌟 BỔ SUNG VÀO ĐÂY
  });
}
