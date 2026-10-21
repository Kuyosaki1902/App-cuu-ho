import 'dart:math';
import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart'; // Thư viện cảm biến la bàn

class MapSection extends StatelessWidget {
  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final bool isOnline;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback RefreshLocation;

  const MapSection({
    super.key,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.onMapCreated,
    required this.RefreshLocation,
    required this.isOnline,
  });

  Polygon buildRadarSectorPolygon({
    required LatLng center,
    required double headingInDegrees, // Góc hướng máy (0° - 360°)
    double radiusInMeters = 70.0, // Bán kính quạt
    double sweepAngleDegrees = 72.0, // 15% của 360 độ = 54 độ
  }) {
    const double earthRadius = 6371000.0; // Bán kính trái đất tính bằng mét
    List<LatLng> points = [center];

    double startAngle = headingInDegrees - (sweepAngleDegrees / 2);
    double endAngle = headingInDegrees + (sweepAngleDegrees / 2);

    // Lấy các điểm tạo thành cung tròn của hình quạt
    for (double angle = startAngle; angle <= endAngle; angle += 3) {
      double rad = angle * pi / 180.0;
      num latRad = center.latitude * pi / 180.0;
      num lngRad = center.longitude * pi / 180.0;
      num dByR = radiusInMeters / earthRadius;

      num destLatRad = asin(
        sin(latRad) * cos(dByR) + cos(latRad) * sin(dByR) * cos(rad),
      );
      num destLngRad =
          lngRad +
          atan2(
            sin(rad) * sin(dByR) * cos(latRad),
            cos(dByR) - sin(latRad) * sin(destLatRad),
          );
      points.add(LatLng(destLatRad * 180.0 / pi, destLngRad * 180.0 / pi));
    }
    points.add(center); // Đóng hình quạt về tâm
    return Polygon(
      polygonId: const PolygonId('radar_sector_15percent'),
      points: points,
      fillColor: Colors.blue.withOpacity(0.25), // Màu xanh mờ 15-25%
      strokeColor: Colors.transparent,
      strokeWidth: 0,
      zIndex: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFC80815)),
            const SizedBox(height: 12),
            Text(
              isLoadingLocation
                  ? 'Đang định vị vị trí thực tế...'
                  : 'Chưa thể lấy vị trí. Vui lòng bật GPS và thử lại.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (!isLoadingLocation)
              TextButton.icon(
                onPressed: RefreshLocation,
                icon: const Icon(Icons.refresh, color: Color(0xFFC80815)),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(color: Color(0xFFC80815)),
                ),
              ),
          ],
        ),
      );
    }

    // 🟢 Lắng nghe cảm biến la bàn xoay điện thoại
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        // Lấy góc hướng máy (mặc định 0° nếu chưa có dữ liệu cảm biến)
        double heading = snapshot.data?.heading ?? 0.0;

        return Stack(
          children: [
            GoogleMap(
              key: ValueKey(
                '${currentPosition!.latitude}_${currentPosition!.longitude}',
              ),
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 15.5,
              ),
              onMapCreated: onMapCreated,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,

              // 🟢 VẼ HÌNH QUẠT 15% (54 ĐỘ) THEO HƯỚNG XOAY MÁY
              polygons: {
                buildRadarSectorPolygon(
                  center: currentPosition!,
                  headingInDegrees: heading,
                  radiusInMeters: 70.0, // Bán kính quạt
                  sweepAngleDegrees: 72.0, // Góc rộng 54° = 15% của 360°
                ),
              },

              // 🟢 VÒNG TRÒN VỊ TRÍ TÂM (LỚP 2 VÀ LỚP 3)
              circles: {
                // LỚP 2: Viền trắng bao quanh tâm
                Circle(
                  circleId: const CircleId('center_white_border'),
                  center: currentPosition!,
                  radius: 23,
                  fillColor: Colors.white,
                  strokeColor: const Color(0xFFD1D5DB),
                  strokeWidth: 1,
                  zIndex: 2,
                ),

                // LỚP 3: Chấm xanh ở tâm
                Circle(
                  circleId: const CircleId('center_green_dot'),
                  center: currentPosition!,
                  radius: 20,
                  fillColor: Colors.blue.shade600,
                  strokeColor: Colors.transparent,
                  strokeWidth: 0,
                  zIndex: 3,
                ),
              },
            ),

            // Nút định vị vị trí hiện tại
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: isOnline
                        ? ColorCHV.tiep_nhan_yeu_cau
                        : ColorCHV.ngung_tiep_nhan_yeu_cau,
                  ),
                  onPressed: RefreshLocation,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
