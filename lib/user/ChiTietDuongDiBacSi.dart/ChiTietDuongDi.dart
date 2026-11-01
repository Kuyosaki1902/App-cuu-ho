// lib/user/ChiTietDuongDi/ChiTietDuongDi.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'controllers/chi_tiet_duong_di_controller.dart';
import 'views/top_navigation_bar.dart';
import 'views/bottom_sheet_duong_di.dart';

class ChiTietDuongDiScreen extends StatefulWidget {
  final String maNguoiCuuHo; // 🌟 Thêm biến này để hết đỏ
  final double startLat;
  final double startLng;
  final double victimLat;
  final double victimLng;
  final String tenBacSi;

  const ChiTietDuongDiScreen({
    super.key,
    required this.maNguoiCuuHo, // 🌟 Khai báo required
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
      maNguoiCuuHo: widget.maNguoiCuuHo, // 🌟 Truyền xuống Controller
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
            padding: const EdgeInsets.only(bottom: 350),
          ),

          // 2. Top Navigation Bar
          const ChiTietDuongDiTopNav(),

          // 3. Bottom Sheet
          ChiTietDuongDiBottomSheet(
            controller: _controller,
            tenBacSi: widget.tenBacSi,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }
}
