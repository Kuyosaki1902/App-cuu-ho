// lib/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'controllers/tim_kiem_cuu_ho_controller.dart';
import 'views/top_navigation_bar.dart';
import 'views/bottom_sheet_tim_kiem_ai.dart';

class GiaoDienDangTimKiem extends StatefulWidget {
  const GiaoDienDangTimKiem({super.key});

  @override
  State<GiaoDienDangTimKiem> createState() => _GiaoDienDangTimKiemState();
}

class _GiaoDienDangTimKiemState extends State<GiaoDienDangTimKiem> {
  final TimKiemCuuHoController _controller = TimKiemCuuHoController();
  final Color primaryColor = const Color(0xFF006A55);

  @override
  void initState() {
    super.initState();
    _controller.fetchCurrentLocation(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _controller.currentDeviceLocation,
              zoom: 15.5,
            ),
            onMapCreated: _controller.onMapCreated,
            circles: _controller.circles,
            markers: _controller.markers, // 🌟 Hiện Marker điểm cấp cứu thực tế
            myLocationEnabled:
                true, // 🌟 Bật chấm xanh GPS mặc định của Google Maps
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // 🔄 2. Màn hình chờ xoay nhẹ ở chính giữa khi đang định vị
          if (_controller.isLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'Đang định vị vị trí cấp cứu...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Thanh Navigation & Status phía trên
          const TopNavigationBarWidget(),

          // 4. Nút định vị GPS
          Positioned(
            right: 16,
            bottom: 390,
            child: Material(
              elevation: 3,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.my_location,
                    color: Colors.black87,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.fetchCurrentLocation(() {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ),
            ),
          ),

          // 5. BottomSheet Tìm kiếm AI phía dưới
          BottomSheetTimKiemAIWidget(primaryColor: primaryColor),
        ],
      ),
    );
  }
}
