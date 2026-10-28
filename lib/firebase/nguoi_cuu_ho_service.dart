import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart'; // Thay đúng đường dẫn model của dự án

class ThongTinCuuHoData {
  final Set<Marker> markers;
  final int soLuong;
  final String thongBaoTrangThai;
  final String thoiGianUocTinh;

  ThongTinCuuHoData({
    required this.markers,
    required this.soLuong,
    required this.thongBaoTrangThai,
    required this.thoiGianUocTinh,
  });
}

class NguoiCuuHoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<ThongTinCuuHoData> langNgheNguoiCuuHo(LatLng myPosition, double currentRadius) {
    return _firestore
        .collection('NguoiDung')
        .where('isOnline', isEqualTo: true)
        .where('maVaiTro', whereIn: ['vaitro_cuuhochuacocc', 'vaitro_cuuhococc'])
        .snapshots()
        .asyncMap((snapshot) async {
      
      List<NguoiDungModel> validRescuers = [];
      List<double> distances = [];
      Set<Marker> generatedMarkers = {};

      for (var doc in snapshot.docs) {
        var user = NguoiDungModel.fromMap(doc.data());
        
        if (user.viDo != null && user.kinhDo != null) {
          double distance = Geolocator.distanceBetween(
            myPosition.latitude, myPosition.longitude,
            user.viDo!, user.kinhDo!
          );

          if (distance <= currentRadius) {
            validRescuers.add(user);
            distances.add(distance);
          }
        }
      }

      // Xử lý chống đè (Spiderfier)
      List<LatLng> processedPositions = [];
      for (int i = 0; i < validRescuers.length; i++) {
        var user = validRescuers[i];
        double distance = distances[i];
        
        LatLng position = LatLng(user.viDo!, user.kinhDo!);
        
        int overlapCount = 0;
        for (var p in processedPositions) {
          if (Geolocator.distanceBetween(position.latitude, position.longitude, p.latitude, p.longitude) < 20) {
            overlapCount++;
          }
        }

        if (overlapCount > 0) {
          double offsetMeters = 25.0 * overlapCount;
          double angle = overlapCount * (pi / 3);
          
          double latOffset = offsetMeters / 111320.0;
          double lngOffset = offsetMeters / (111320.0 * cos(position.latitude * pi / 180.0));
          
          position = LatLng(
            position.latitude + (latOffset * cos(angle)),
            position.longitude + (lngOffset * sin(angle))
          );
        }
        processedPositions.add(position);

        String distanceStr = distance > 1000 
            ? "${(distance / 1000).toStringAsFixed(1)} km" 
            : "${distance.toInt()} m";
            
        final icon = await _taohinhAnhMarker(distanceStr);
        
        generatedMarkers.add(
          Marker(
            markerId: MarkerId(user.maNguoiDung ?? 'rescuer_$i'),
            position: position,
            icon: icon,
            infoWindow: InfoWindow(title: user.hoTen, snippet: distanceStr),
          )
        );
      }

      int soLuong = validRescuers.length;
      String thongBao = soLuong > 0 
          ? "$soLuong bác sĩ sẵn sàng nhận" 
          : "Hiện chưa có người nào trong khu vực";
          
      String thoiGian = "";
      if (soLuong > 0) {
        double minDistance = distances.reduce(min);
        double maxDistance = distances.reduce(max);
        
        int minTime = (minDistance / 666).ceil();
        int maxTime = (maxDistance / 666).ceil();
        
        if (minTime < 1) minTime = 1;
        if (maxTime < 1) maxTime = 1;

        thoiGian = minTime == maxTime 
            ? "Tốc độ ${minTime}p" 
            : "Tốc độ ${minTime}p - ${maxTime}p";
      }

      return ThongTinCuuHoData(
        markers: generatedMarkers,
        soLuong: soLuong,
        thongBaoTrangThai: thongBao,
        thoiGianUocTinh: thoiGian,
      );
    });
  }

  // Hàm vẽ Marker custom nhỏ gọn, vừa vặn trên bản đồ
  Future<BitmapDescriptor> _taohinhAnhMarker(String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // Kích thước chuẩn nhỏ gọn: 80x100 (thay vì 140x180 như cũ)
    const double width = 80;
    const double height = 100;

    // 1. Hình tròn Avatar xanh ở trên
    paint.color = const Color(0xFF00695C);
    canvas.drawCircle(const Offset(width / 2, 28), 26, paint);
    
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(width / 2, 28), 22.5, paint);

    // Icon người nhỏ gọn bên trong
    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(0xe491), // Icons.person
      style: const TextStyle(
        fontSize: 30, 
        fontFamily: 'MaterialIcons', 
        color: Color(0xFF00695C),
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas, 
      Offset((width / 2) - (iconPainter.width / 2), 28 - (iconPainter.height / 2)),
    );

    // 2. Bảng bo góc hiển thị số mét
    paint.color = const Color(0xFF00695C);
    RRect rrectBorder = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6, 56, 68, 28), 
      const Radius.circular(14),
    );
    canvas.drawRRect(rrectBorder, paint);

    paint.color = Colors.white;
    RRect rrectBg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 58, 64, 24), 
      const Radius.circular(12),
    );
    canvas.drawRRect(rrectBg, paint);

    // 3. Mũi tên chỉ xuống điểm tọa độ
    Path path = Path();
    path.moveTo(width / 2 - 7, 84);
    path.lineTo(width / 2 + 7, 84);
    path.lineTo(width / 2, 95);
    path.close();
    paint.color = const Color(0xFF00695C);
    canvas.drawPath(path, paint);

    // 4. Chữ khoảng cách (VD: 81 m, 1.2 km)
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 13, 
        fontWeight: FontWeight.bold, 
        color: Color(0xFF004D40),
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: 64);
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, 62),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }
}