import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';

class MapNavigationCard extends StatelessWidget {
  const MapNavigationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyAlertController>();

    // 🟢 Truyền danh sách polylineCoordinates (tọa độ thực tế theo lòng đường)
    final Set<Polyline> polylines = {
      if (controller.polylineCoordinates.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('real_world_route'),
          points: controller
              .polylineCoordinates, // Mảng các điểm uốn lượn theo con đường
          color: const Color(0xFF00897B),
          width: 5,
        ),
    };

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('doctor'),
        position: controller.myLocation,
        infoWindow: const InfoWindow(title: 'BẠN Ở ĐÂY'),
      ),
      Marker(
        markerId: const MarkerId('victim'),
        position: controller.victimLocation,
        infoWindow: const InfoWindow(title: 'VỊ TRÍ NẠN NHÂN (SOS)'),
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🟢 Khung Google Map thật tự co giãn full chiều cao
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (controller.myLocation.latitude +
                                controller.victimLocation.latitude) /
                            2,
                        (controller.myLocation.longitude +
                                controller.victimLocation.longitude) /
                            2,
                      ),
                      zoom: 15.5,
                    ),
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    padding: const EdgeInsets.only(top: 30, right: 6),
                    onMapCreated: (mapCtrl) {
                      controller.mapController = mapCtrl;
                    },
                  ),

                  // Overlay Badge 1: Khoảng cách (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            size: 14,
                            color: Color(0xFF00897B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.distanceText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlay Badge 2: Thời gian xe đạp / đi bộ (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _buildTimeBadge(
                          Icons.directions_bike,
                          controller.bikeTime,
                        ),
                        const SizedBox(width: 6),
                        _buildTimeBadge(
                          Icons.directions_walk,
                          controller.walkTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Khung thông tin Địa chỉ Cấp cứu ở đáy
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐỊA CHỈ CẤP CỨU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.address,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00897B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
