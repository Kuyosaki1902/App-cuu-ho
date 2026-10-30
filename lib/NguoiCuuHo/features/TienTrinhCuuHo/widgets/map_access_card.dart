import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class MapAccessCard extends StatelessWidget {
  const MapAccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();

    // 🟢 1. Cấu hình Marker Bác sĩ & Nạn nhân kèm nhãn thông tin
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('doctor'),
        position: controller.doctorLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Bạn (BS. Tuấn)'),
      ),
      Marker(
        markerId: const MarkerId('victim'),
        position: controller.victimLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(title: 'Hẻm 142/18 (Nạn nhân)'),
      ),
    };

    // 🟢 2. Đường nét đứt (Dashed Polyline) màu đỏ nối 2 điểm
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('dashed_route'),
        points: [
          controller.doctorLocation,
          const LatLng(10.7330, 106.7195),
          const LatLng(10.7342, 106.7215),
          controller.victimLocation,
        ],
        color: const Color(0xFFDC2626), // Màu đỏ tươi chuẩn nét đứt
        width: 5,
        patterns: [
          PatternItem.dash(20), // Độ dài nét đứt
          PatternItem.gap(10), // Khoảng hở giữa các nét
        ],
        jointType: JointType.round,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 HEADER THẺ BẢN ĐỒ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.my_location, color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BẢN ĐỒ GPS TIẾP CẬN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              // Badge trạng thái GPS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                ),
                child: const Text(
                  'GPS Tín hiệu mạnh',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🗺️ KHUNG GOOGLE MAPS VỚI CÁC BADGE OVERLAY
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (controller.doctorLocation.latitude +
                                controller.victimLocation.latitude) /
                            2,
                        (controller.doctorLocation.longitude +
                                controller.victimLocation.longitude) /
                            2,
                      ),
                      zoom: 15.5,
                    ),
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: (mapCtrl) {
                      controller.mapController = mapCtrl;
                    },
                  ),

                  // 🏷️ Badge Nhãn Bác sĩ (Bên trái dưới)
                  Positioned(
                    bottom: 30,
                    left: 35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'Bạn (BS. Tuấn)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 🏷️ Badge Nhãn Nạn nhân (Nằm chính giữa đường đi)
                  Positioned(
                    top: 85,
                    right: 45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB91C1C),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'Hẻm 142/18 (Nạn nhân)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 🧭 Nút Mũi tên Định vị (Bottom Right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () {
                        if (controller.mapController != null) {
                          controller.mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              controller.doctorLocation,
                              16,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.near_me_outlined,
                          color: Color(0xFF1E293B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
