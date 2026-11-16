// lib/GiaoDienDangTimKiem/GiaoDienDangTimKiem.dart

import 'dart:convert';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/ChatVoiAI.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/TongQuanBacSiTiepNhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  // Cache chuỗi base64/URL avatar theo maNguoiDung để mở dialog mượt mà
  final Map<String, String?> _rescuerAvatarCache = {};

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

  Future<String?> _getCachedRescuerAvatar(String maNguoiCuuHo) async {
    if (_rescuerAvatarCache.containsKey(maNguoiCuuHo)) {
      return _rescuerAvatarCache[maNguoiCuuHo];
    }
    final raw = await FirebaseService().getUserAvatarUrl(maNguoiCuuHo);
    _rescuerAvatarCache[maNguoiCuuHo] = raw;
    return raw;
  }

  ImageProvider? _decodeAvatarProvider(String? rawAvatar) {
    if (rawAvatar == null || rawAvatar.trim().isEmpty) return null;
    final cleaned = rawAvatar.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return NetworkImage(cleaned);
    }
    try {
      final base64Part = cleaned.contains(',')
          ? cleaned.split(',').last.trim()
          : cleaned;
      return MemoryImage(base64Decode(base64Part));
    } catch (_) {
      return null;
    }
  }

  String _getShortInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CH';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
  }

  // 🌟 Hộp thoại hiển thị danh sách lực lượng cứu hộ
  void _showRescuerListDialog() {
    final danhSachPhanCong =
        _controller.yeuCauCuuHo?.danhSachPhanCongVien ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER HỘP THOẠI
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lực lượng cứu hộ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đã gửi tín hiệu tới ${danhSachPhanCong.length} người',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${danhSachPhanCong.length}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // 2. DANH SÁCH THẺ CỨU HỘ VIÊN
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: danhSachPhanCong.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      String maNguoiCuuHo = danhSachPhanCong.keys.elementAt(
                        index,
                      );
                      String trangThaiCode =
                          danhSachPhanCong[maNguoiCuuHo] ?? '';

                      String statusText = 'Chờ xác nhận';
                      Color statusColor = const Color(0xFFD97706);
                      Color statusBg = const Color(0xFFFEF3C7);
                      IconData statusIcon = Icons.hourglass_top_rounded;

                      if (trangThaiCode ==
                              'cuuho_trangthai_phancong_tiepnhan' ||
                          trangThaiCode == 'tiepnhan') {
                        statusText = 'Đã nhận ca';
                        statusColor = const Color(0xFF059669);
                        statusBg = const Color(0xFFD1FAE5);
                        statusIcon = Icons.check_circle_rounded;
                      } else if (trangThaiCode ==
                              'cuuho_trangthai_phancong_tuchoi' ||
                          trangThaiCode == 'tuchoi') {
                        statusText = 'Đã từ chối';
                        statusColor = const Color(0xFFDC2626);
                        statusBg = const Color(0xFFFEE2E2);
                        statusIcon = Icons.cancel_rounded;
                      } else if (trangThaiCode ==
                              'cuuho_trangthai_phancong_dahuy' ||
                          trangThaiCode == 'dahuy') {
                        statusText = 'Đã hủy ca';
                        statusColor = const Color(0xFF64748B);
                        statusBg = const Color(0xFFF1F5F9);
                        statusIcon = Icons.do_disturb_alt_rounded;
                      }

                      var rescuerInfo = _controller.rescuerList.firstWhere(
                        (element) =>
                            element['user']?.maNguoiDung == maNguoiCuuHo,
                        orElse: () => {'user': null, 'distanceKm': null},
                      );

                      final user = rescuerInfo['user'];
                      String hoTen = user != null ? user.hoTen : 'Cứu hộ viên';

                      String distanceLabel = '';
                      if (user != null &&
                          user.viDo != null &&
                          user.kinhDo != null) {
                        double meters = Geolocator.distanceBetween(
                          _controller.currentDeviceLocation.latitude,
                          _controller.currentDeviceLocation.longitude,
                          user.viDo!,
                          user.kinhDo!,
                        );
                        distanceLabel = meters < 1000
                            ? '${meters.round()} m'
                            : '${(meters / 1000).toStringAsFixed(1)} km';
                      } else if (rescuerInfo['distanceKm'] != null) {
                        distanceLabel = '${rescuerInfo['distanceKm']} km';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // AVATAR TRÒN CÓ VIỀN + ICON TRẠNG THÁI
                            FutureBuilder<String?>(
                              future: _getCachedRescuerAvatar(maNguoiCuuHo),
                              builder: (context, snapshot) {
                                final avatarImg = _decodeAvatarProvider(
                                  snapshot.data,
                                );
                                return Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 23,
                                        backgroundColor: const Color(
                                          0xFFE2F7F2,
                                        ),
                                        backgroundImage: avatarImg,
                                        child: avatarImg == null
                                            ? Text(
                                                _getShortInitials(hoTen),
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          statusIcon,
                                          color: statusColor,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(width: 12),

                            // THÔNG TIN TÊN + TRẠNG THÁI + KHOẢNG CÁCH
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hoTen,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              size: 12,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (distanceLabel.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2F7F2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.near_me_rounded,
                                                size: 11,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                distanceLabel,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // 3. NÚT ĐÓNG
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double mapBottomPadding = _isBottomSheetExpanded ? 410.0 : 180.0;

    bool hasRescuersInList =
        _controller.yeuCauCuuHo?.danhSachPhanCongVien.isNotEmpty ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
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
              padding: EdgeInsets.only(bottom: mapBottomPadding),
            ),

            if (_controller.isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),

            TopNavigationBarWidget(
              onBackPressed: () {
                _controller.stopSearchWithoutCanceling();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              onChatAIPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatVoiAIScreen(),
                  ),
                );
              },
            ),

            // 🌟 CỤM NÚT NỔI + BOTTOM SHEET XẾP CHỒNG TỰ ĐỘNG (LUÔN NẰM TRÊN MÉP SHEET 12PX)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          const SizedBox(width: 12),
                        ],
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
                              Icons.my_location,
                              color: Colors.black,
                            ),
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
          ],
        ),
      ),
    );
  }
}
