import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatelessWidget {
  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final String selectedRadius;
  final double zoomLevel;
  final bool isOnline;
  final double circleRadiusMeters;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback RefreshLocation;

  const MapSection({
    super.key,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.selectedRadius,
    required this.zoomLevel,
    required this.circleRadiusMeters,
    required this.onMapCreated,
    required this.RefreshLocation,
    required this.isOnline,
  });

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

    return Stack(
      children: [
        GoogleMap(
          key: ValueKey(
            '${currentPosition!.latitude}_${currentPosition!.longitude}',
          ),
          initialCameraPosition: CameraPosition(
            target: currentPosition!,
            zoom: 12,
          ),
          onMapCreated: onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('current_user_location'),
              position: currentPosition!,
              infoWindow: const InfoWindow(
                title: 'Vị trí của bạn',
                snippet: 'Đang trực cứu hộ',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          circles: {
            //Vòng tròn khoảng cách quét
            Circle(
              circleId: const CircleId('scan_radius'),
              center: currentPosition!,
              radius: circleRadiusMeters,
              fillColor: isOnline
                  ? ColorCHV.tiep_nhan_yeu_cau.withOpacity(0.15)
                  : ColorCHV.ngung_tiep_nhan_yeu_cau.withOpacity(0.15),
              strokeColor: isOnline
                  ? ColorCHV.tiep_nhan_yeu_cau.withOpacity(0.6)
                  : ColorCHV.ngung_tiep_nhan_yeu_cau.withOpacity(0.6),
              strokeWidth: 2,
            ),
          },
        ),
        // Badge hiển thị bán kính
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau,
                  size: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bán kính quét: ${selectedRadius.split(' ')[0]} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Các nút thao tác nhanh
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              // _buildActionButton(Icons.layers_outlined, onTap: () {}),
              // const SizedBox(height: 8),
              // _buildActionButton(Icons.tune, onTap: () {}),
              // const SizedBox(height: 8),
              //Nút quay về vị trí hiện tại
              _buildActionButton(
                Icons.my_location,
                iconColor: isOnline
                    ? ColorCHV.tiep_nhan_yeu_cau
                    : ColorCHV.ngung_tiep_nhan_yeu_cau,
                onTap: RefreshLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon, {
    Color iconColor = Colors.black87,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}
