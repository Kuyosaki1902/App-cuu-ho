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

  // 🌟 Biến quản lý trạng thái đóng/mở của Bottom Sheet
  bool _isBottomSheetExpanded = true;

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

  // 🌟 Hàm toggle trạng thái
  void _toggleBottomSheet(bool isExpanded) {
    setState(() {
      _isBottomSheetExpanded = isExpanded;
    });
  }

  // 🌟 Hàm gọi hiển thị danh sách (Dời từ BottomSheet sang đây)
  void _showRescuerListDialog() {
    final danhSachPhanCong =
        _controller.yeuCauCuuHo?.danhSachPhanCongVien ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.list_alt_rounded, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Lực lượng cứu hộ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: danhSachPhanCong.length,
              itemBuilder: (context, index) {
                String maNguoiCuuHo = danhSachPhanCong.keys.elementAt(index);
                String trangThaiCode = danhSachPhanCong[maNguoiCuuHo] ?? '';

                String statusText = 'Chờ xác nhận';
                Color statusColor = Colors.orange;
                IconData statusIcon = Icons.hourglass_top;

                if (trangThaiCode == 'cuuho_trangthai_phancong_tiepnhan' ||
                    trangThaiCode == 'tiepnhan') {
                  statusText = 'Đã nhận ca';
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                } else if (trangThaiCode == 'cuuho_trangthai_phancong_tuchoi' ||
                    trangThaiCode == 'tuchoi') {
                  statusText = 'Đã từ chối';
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                } else if (trangThaiCode == 'cuuho_trangthai_phancong_dahuy' ||
                    trangThaiCode == 'dahuy') {
                  statusText = 'Đã hủy ca';
                  statusColor = Colors.grey;
                  statusIcon = Icons.do_disturb_alt;
                }

                var rescuerInfo = _controller.rescuerList.firstWhere(
                  (element) => element['user'].maNguoiDung == maNguoiCuuHo,
                  orElse: () => {'user': null},
                );

                String hoTen = rescuerInfo['user'] != null
                    ? rescuerInfo['user'].hoTen
                    : 'Cứu hộ viên';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    hoTen,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Tính toán Padding cho Map và Vị trí của cụm nút bấm
    // Giả định chiều cao BottomSheet khi mở là ~460, khi đóng là ~180 (tuỳ thuộc vào kích thước màn hình, bác có thể tinh chỉnh số này)
    final double bottomSheetHeight = _isBottomSheetExpanded ? 390.0 : 180.0;

    // Kiểm tra có ai nhận đơn chưa để hiện nút Xem Danh Sách
    bool hasRescuersInList =
        _controller.yeuCauCuuHo?.danhSachPhanCongVien.isNotEmpty ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
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
            // BẢN ĐỒ
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
              // 🌟 Chỉnh Padding động theo trạng thái Bottom Sheet để tâm victim luôn ở giữa phần map nhìn thấy
              padding: EdgeInsets.only(bottom: bottomSheetHeight),
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

            // 🌟 CỤM NÚT NỔI (Định vị + Xem danh sách) - Di chuyển lên xuống mượt mà
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: bottomSheetHeight + 12, // Cách đỉnh bottom sheet 16px
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Xem Danh Sách (Chỉ hiện khi có người)
                  if (hasRescuersInList) ...[
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showRescuerListDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Danh sách',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Khoảng cách giữa 2 nút
                  ],

                  // Nút Định Vị
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
                      icon: const Icon(Icons.my_location, color: Colors.black),
                      onPressed: () {
                        _controller.moveToCurrentLocation();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM SHEET
            BottomSheetTimKiemAIWidget(
              primaryColor: primaryColor,
              controller: _controller,
              isExpanded: _isBottomSheetExpanded,
              onToggleExpanded: _toggleBottomSheet,
            ),
          ],
        ),
      ),
    );
  }
}
