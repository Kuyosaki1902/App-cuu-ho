// lib/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart

import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/TongQuanBacSiTiepNhan.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'controllers/tim_kiem_cuu_ho_controller.dart';
import 'views/top_navigation_bar.dart';
import 'views/bottom_sheet_tim_kiem_ai.dart';

class GiaoDienDangTimKiem extends StatefulWidget {
  final String maYeuCau;
  final List<String>? danhSachChiDinh;
  const GiaoDienDangTimKiem({
    super.key,
    required this.maYeuCau,
    this.danhSachChiDinh,
  });

  @override
  State<GiaoDienDangTimKiem> createState() => _GiaoDienDangTimKiemState();
}

class _GiaoDienDangTimKiemState extends State<GiaoDienDangTimKiem> {
  final TimKiemCuuHoController _controller = TimKiemCuuHoController();
  final Color primaryColor = const Color(0xFF006A55);

  @override
  void initState() {
    super.initState();
    _controller.initSearch(
      widget.maYeuCau,
      danhSachChiDinh: widget.danhSachChiDinh,
      () {
        if (mounted) setState(() {});
      },
      onRescuerAccepted: (initialLocations) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TongQuanBacSiTiepNhan(
                maYeuCau: widget.maYeuCau,
                currentUserId: _controller.yeuCauCuuHo?.maNguoiYeuCau ?? '',
                victimLat: _controller.currentDeviceLocation.latitude,
                victimLng: _controller.currentDeviceLocation.longitude,
                initialLocations: initialLocations,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Bọc PopScope để xử lý nút Back cứng trên điện thoại
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Khi bấm Back, tiến hành hủy đơn và dọn dẹp
        if (_controller.yeuCauCuuHo != null) {
          await _controller.cancelSearch(_controller.yeuCauCuuHo!.maYeuCau);
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
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
            if (_controller.isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
            TopNavigationBarWidget(
              onBackPressed: () async {
                // 🌟 Gọi hàm hủy đơn và dọn dẹp dữ liệu trước khi thoát
                if (_controller.yeuCauCuuHo != null) {
                  await _controller.cancelSearch(
                    _controller.yeuCauCuuHo!.maYeuCau,
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            BottomSheetTimKiemAIWidget(
              primaryColor: primaryColor,
              controller: _controller,
            ),
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
      ),
    );
  }
}
