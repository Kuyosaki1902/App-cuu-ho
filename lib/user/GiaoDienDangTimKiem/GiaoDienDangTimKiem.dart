// lib/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'controllers/tim_kiem_cuu_ho_controller.dart';
import 'views/top_navigation_bar.dart';
import 'views/bottom_sheet_tim_kiem_ai.dart';

class GiaoDienDangTimKiem extends StatefulWidget {
  final String maYeuCau;

  const GiaoDienDangTimKiem({super.key, required this.maYeuCau});

  @override
  State<GiaoDienDangTimKiem> createState() => _GiaoDienDangTimKiemState();
}

class _GiaoDienDangTimKiemState extends State<GiaoDienDangTimKiem> {
  final TimKiemCuuHoController _controller = TimKiemCuuHoController();
  final Color primaryColor = const Color(0xFF006A55);

  @override
  void initState() {
    super.initState();
    _controller.initSearch(widget.maYeuCau, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              zoom: 14.5,
            ),
            onMapCreated: _controller.onMapCreated,
            circles: _controller.circles,
            markers: _controller.markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 300),
          ),

          // 2. Loading Indicator
          if (_controller.isLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),

          // 3. Navigation Bar
          const TopNavigationBarWidget(),

          // 4. BottomSheet Tim Kiem AI
          BottomSheetTimKiemAIWidget(
            primaryColor: primaryColor,
            controller: _controller,
          ),

          // 5. Nút Định vị
          Positioned(
            top: 450,
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
                icon: const Icon(Icons.my_location, color: Colors.black),
                onPressed: () {
                  _controller.moveToCurrentLocation();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
