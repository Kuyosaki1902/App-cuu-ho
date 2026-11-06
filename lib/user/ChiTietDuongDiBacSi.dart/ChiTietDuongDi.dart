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
          // 1. Google Maps hiển thị lộ trình (🌟 Tăng padding bottom lên 350 để không bị che khuất)
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
            padding: const EdgeInsets.only(bottom: 350),
            onCameraMoveStarted: () {
              _controller.disableAutoTracking();
            },
          ),

          // 2. Top Navigation Bar
          const ChiTietDuongDiTopNav(),

          // 3. Bottom Sheet cố định kích thước
          ChiTietDuongDiBottomSheet(
            controller: _controller,
            tenBacSi: widget.tenBacSi,
            primaryColor: primaryColor,
          ),

          // 4. Cụm nút điều khiển bản đồ
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                // Nút 1: Auto-Fit (Bao quát lộ trình)
                GestureDetector(
                  onTap: () {
                    _controller.enableAutoTracking();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
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
                    child: Icon(
                      _controller.isAutoTracking
                          ? Icons.zoom_out_map
                          : Icons.center_focus_strong,
                      color: _controller.isAutoTracking
                          ? Colors.blue
                          : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút 2: Vị trí nạn nhân (Giữ nguyên mức zoom hiện tại)
                GestureDetector(
                  onTap: () async {
                    await _controller.moveToVictim();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
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
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.black87,
                      size: 20,
                    ),
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
