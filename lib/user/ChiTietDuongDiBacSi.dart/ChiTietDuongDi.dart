// lib/user/ChiTietDuongDi/ChiTietDuongDi.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'controllers/chi_tiet_duong_di_controller.dart';
import 'views/top_navigation_bar.dart';
import 'views/bottom_sheet_duong_di.dart';

class ChiTietDuongDiScreen extends StatefulWidget {
  final String maNguoiCuuHo;
  final double startLat;
  final double startLng;
  final double victimLat;
  final double victimLng;
  final String tenBacSi;

  const ChiTietDuongDiScreen({
    super.key,
    required this.maNguoiCuuHo,
    required this.startLat,
    required this.startLng,
    required this.victimLat,
    required this.victimLng,
    required this.tenBacSi,
  });

  @override
  State<ChiTietDuongDiScreen> createState() => _ChiTietDuongDiScreenState();
}

class _ChiTietDuongDiScreenState extends State<ChiTietDuongDiScreen> {
  late ChiTietDuongDiController _controller;
  final Color primaryColor = const Color(0xFF006A55);

  @override
  void initState() {
    super.initState();
    _controller = ChiTietDuongDiController(
      maNguoiCuuHo: widget.maNguoiCuuHo,
      startLat: widget.startLat,
      startLng: widget.startLng,
      victimLat: widget.victimLat,
      victimLng: widget.victimLng,
      tenBacSi: widget.tenBacSi,
    );
    _controller.initTracking(() {
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
          // 1. Google Maps hiển thị lộ trình
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.victimLat, widget.victimLng),
              zoom: 14.5,
            ),
            onMapCreated: _controller.onMapCreated,
            markers: _controller.markers,
            polylines: _controller.polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.only(bottom: 300),
          ),

          // 2. Top Navigation Bar
          const ChiTietDuongDiTopNav(),

          // 3. Bottom Sheet
          ChiTietDuongDiBottomSheet(
            controller: _controller,
            tenBacSi: widget.tenBacSi,
            primaryColor: primaryColor,
          ),

          // 🌟 4. Cụm nút điều khiển bản đồ (Nút Ghim bao quát & Nút về vị trí nạn nhân)
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                // Nút Ghim (Bao quát lộ trình giữa cứu hộ viên và nạn nhân)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.zoom_out_map,
                      color: Color(0xFF006A55),
                    ),
                    tooltip: 'Bao quát lộ trình',
                    onPressed: () {
                      _controller.fitRouteBounds();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Nút Quay lại vị trí nạn nhân
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_pin_circle,
                      color: Color(0xFFC81E1E),
                    ),
                    tooltip: 'Vị trí nạn nhân',
                    onPressed: () {
                      _controller.moveToVictim();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
