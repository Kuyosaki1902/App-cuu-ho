// lib/user/ChiTietDuongDi/ChiTietDuongDi.dart
import 'package:cuhokhancap/user/ThongTInHoanThanhCuuHo/HoanThanhCuuHo.dart';
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
  final String soDienThoai;
  final String currentUserId;

  const ChiTietDuongDiScreen({
    super.key,
    required this.maNguoiCuuHo,
    required this.startLat,
    required this.startLng,
    required this.victimLat,
    required this.victimLng,
    required this.tenBacSi,
    required this.maYeuCau,
    this.soDienThoai = '',
    this.currentUserId = '',
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
      soDienThoai: widget.soDienThoai,
      onStatusChangedFromAccepted: _handleRescuerStatusChanged,
    );
    _controller.initTracking(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleRescuerStatusChanged(String newStatus) async {
    if (!mounted) return;

    final bool isCompleted = newStatus == 'cuuho_trangthai_phancong_hoanthanh';

    String title = 'Cập nhật trạng thái cứu hộ';
    String message =
        'Cứu hộ viên ${widget.tenBacSi} đã cập nhật trạng thái hỗ trợ.';

    if (newStatus == 'cuuho_trangthai_phancong_daden') {
      title = 'Cứu hộ viên đã đến nơi';
      message =
          '${widget.tenBacSi} đã đến vị trí của bạn. Bạn có thể quay lại danh sách để xem các cứu hộ viên tiếp nhận khác hoặc ở lại màn hình này để liên hệ.';
    } else if (newStatus == 'cuuho_trangthai_phancong_dangcuuho') {
      title = 'Đang tiến hành cứu hộ';
      message =
          '${widget.tenBacSi} đã tiếp cận và đang tiến hành cứu hộ. Bạn có thể quay lại xem danh sách các cứu hộ viên tiếp nhận khác.';
    } else if (isCompleted) {
      title = 'Cứu hộ viên đã hoàn thành';
      message =
          '${widget.tenBacSi} đã xác nhận hoàn thành nhiệm vụ cứu hộ. Vui lòng chuyển sang màn hình hoàn thành để xác nhận đơn.';
    }

    await showDialog(
      context: context,
      barrierDismissible: !isCompleted,
      builder: (ctx) => PopScope(
        canPop: !isCompleted,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF006A55)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            if (!isCompleted)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Ở lại đây',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                if (isCompleted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HoanThanhDonCuuHoScreen(
                        maYeuCau: widget.maYeuCau,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                isCompleted ? 'Đi đến Hoàn thành' : 'Xem danh sách cứu hộ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

          const ChiTietDuongDiTopNav(),

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
