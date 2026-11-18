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
  final String maYeuCau;
  const ChiTietDuongDiScreen({
    super.key,
    required this.maNguoiCuuHo,
    required this.startLat,
    required this.startLng,
    required this.victimLat,
    required this.victimLng,
    required this.tenBacSi,
    required this.maYeuCau,
  });

  @override
  State<ChiTietDuongDiScreen> createState() => _ChiTietDuongDiScreenState();
}

class _ChiTietDuongDiScreenState extends State<ChiTietDuongDiScreen> {
  late ChiTietDuongDiController _controller;
  final Color primaryColor = const Color(0xFF006A55);

  bool _isCollapsed = false;

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
      maYeuCau: widget.maYeuCau,
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
    final double bottomPadding = _isCollapsed ? 160.0 : 415.0;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps
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
            padding: EdgeInsets.only(bottom: bottomPadding),
            onCameraMoveStarted: () {
              _controller.disableAutoTracking();
            },
          ),

          // 2. Top Navigation Bar
          const ChiTietDuongDiTopNav(),

          // 3. Cụm nút điều khiển + Bottom Sheet xếp chồng tự động (không bao giờ bị che đè)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Column(
                    children: [
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

                ChiTietDuongDiBottomSheet(
                  controller: _controller,
                  tenBacSi: widget.tenBacSi,
                  primaryColor: primaryColor,
                  isCollapsed: _isCollapsed,
                  onCollapseChanged: (collapsed) {
                    setState(() {
                      _isCollapsed = collapsed;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
