import 'dart:async';
import 'package:cuhokhancap/BackgroundService/background_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/DangNhap.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/ThongTinTaiKhoan.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/LichSuCaCuuHo/man_hinh_lich_su_ca.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/thanh_tich_screen.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/xep_hang_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/header.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/bottom.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'widgets/map_section.dart';
import 'package:cuhokhancap/firebase/presence_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ManHinhChoTiepNhanCa/ManHinhCho.dart';

class Trangchunguoicuuho extends StatefulWidget {
  final String currentUserId;
  const Trangchunguoicuuho({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  State<Trangchunguoicuuho> createState() => _TrangchunguoicuuhoState();
}

class _TrangchunguoicuuhoState extends State<Trangchunguoicuuho> {
  StreamSubscription<QuerySnapshot>? _assignmentSubscription;
  Timer? _midnightTimer;
  bool _isNavigating = false;
  // thêm vào _TrangchunguoicuuhoState
  final Set<int> _builtTabs = {0};

  // Tab đang chọn (0: Trực chiến, 1: Lịch sử, 2: Dụng cụ, 3: Điều phối, 4: Hồ sơ)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    PresenceService()
        .start(widget.currentUserId, onKicked: _hienThiThongBaoBiDaVang)
        .catchError((Object e) {
          debugPrint('Presence.start lỗi: $e');
        });
    _listenForRescueAssignments();
    _scheduleMidnightRefresh();
    EmergencyNotificationService().startListening(widget.currentUserId);
  }

  /// Bị thiết bị khác giành phiên. CHỈ điều hướng, KHÔNG ghi isOnline
  /// (nếu ghi false sẽ đè lên phiên của máy mới).
  Future<void> _hienThiThongBaoBiDaVang() async {
    // 🟢 Dừng nghe thông báo khẩn của tài khoản này trên máy cũ.
    // An toàn vì trang kế tiếp là DangNhap (không dựng listener mới).
    try {
      EmergencyNotificationService().stopListening();
    } catch (e) {
      debugPrint('stopListening lỗi: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('maNguoiDung_daLuu');
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const DangNhap(hienThongBaoBiDaVang: true),
      ),
      (route) => false,
    );
  }

  /// 🟢 Qua 00:00 listener phải trỏ sang doc của ngày mới, nếu không CHV
  /// trực đêm sẽ không nhận được ca nào sau nửa đêm.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      _listenForRescueAssignments(); // tính lại todayStr
      _scheduleMidnightRefresh();
    });
  }

  void _listenForRescueAssignments() {
    if (_isNavigating) return; // sẽ nghe lại khi quay về từ màn hình ca
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _assignmentSubscription?.cancel();
    _assignmentSubscription = FirebaseFirestore.instance
        .collection('ChiTietPhanCongCuuHo')
        .doc(widget.currentUserId)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .snapshots()
        .listen((snapshot) {
          if (!mounted || _isNavigating) return;
          if (snapshot.docs.isEmpty) return;

          String targetMaYeuCau = '';
          bool hasDangTienTrinh = false;
          bool hasChoTiepNhan = false;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final String trangThai = (data['maTrangThaiTiepNhan'] ?? '')
                .toString();

            final String maYeuCauTmp =
                (data['maYeuCau'] ?? '').toString().isNotEmpty
                ? data['maYeuCau'].toString()
                : doc.id;

            if (trangThai == 'cuuho_trangthai_phancong_hoanthanh' ||
                trangThai == 'cuuho_trangthai_phancong_dahuy' ||
                trangThai == 'cuuho_trangthai_phancong_tuchoi') {
              continue;
            }

            if (trangThai == 'cuuho_trangthai_phancong_tiepnhan' ||
                trangThai == 'cuuho_trangthai_phancong_daden' ||
                trangThai == 'cuuho_trangthai_phancong_dangcuuho') {
              hasDangTienTrinh = true;
              targetMaYeuCau = maYeuCauTmp;
              break;
            }

            if (trangThai == 'cuuho_trangthai_phancong_chotiepnhan' ||
                trangThai.isEmpty) {
              hasChoTiepNhan = true;
              targetMaYeuCau = maYeuCauTmp;
            }
          }

          if (targetMaYeuCau.isEmpty) return;

          if (hasDangTienTrinh) {
            _openCaScreen(
              TienTrinhCuuHo(
                currentUserId: widget.currentUserId,
                maYeuCauCuuHo: targetMaYeuCau,
              ),
            );
          } else if (hasChoTiepNhan) {
            _openCaScreen(
              Manhinhcho(
                currentUserId: widget.currentUserId,
                maYeuCauCuuHo: targetMaYeuCau,
              ),
            );
          }
        }, onError: (e) => debugPrint('Lỗi nghe phân công: $e'));
  }

  void _openCaScreen(Widget screen) {
    _isNavigating = true;
    _assignmentSubscription?.cancel();

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      _isNavigating = false;
      if (mounted) _listenForRescueAssignments();
    });
  }

  Widget _lazyTab(int index, Widget Function() builder) =>
      _builtTabs.contains(index) ? builder() : const SizedBox.shrink();

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    _midnightTimer?.cancel();
    // KHÔNG stopListening()/đặt offline ở đây: pushAndRemoveUntil dựng trang mới
    // (initState) TRƯỚC khi trang cũ dispose, nên sẽ tắt nhầm listener của trang mới.
    // Gọi EmergencyNotificationService().stopListening() và
    // PresenceService().stop() khi ĐĂNG XUẤT.
    super.dispose();
  }

  Future<void> _xuLyGoiNguoiThan(
    TrangChuController controller,
    Map<String, dynamic> user,
    List<dynamic> danhSachNguoiThan,
  ) async {
    final String hoTen = (user['hoTen'] ?? 'Người dùng').toString();

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gọi toàn bộ người thân?'),
        content: Text(
          'Hệ thống sẽ gọi tự động khẩn cấp cho ${danhSachNguoiThan.length} người thân của $hoTen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gọi ngay'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final bool created = await controller.triggerEmergencyCallToRelative(
      victimUserId: (user['userId'] ?? '').toString(),
      danhSachNguoiThan: danhSachNguoiThan,
      victimName: hoTen,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Đã gửi yêu cầu gọi người thân của $hoTen'
              : 'Đang gọi người thân hoặc gửi yêu cầu thất bại',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrangChuController(widget.currentUserId),
      child: Consumer<TrangChuController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  // Header chỉ hiển thị ở tab Trực chiến
                  if (_currentTabIndex == 0)
                    LifeguardProfileHeader(
                      isOnline: controller.isOnline,
                      onOnlineChanged: controller.toggleOnline,
                      name: controller.name,
                      role: controller.role,
                      maVaiTro: controller.maVaiTro,
                      capDoUyTin: controller.capDoUyTin,
                      // 🟢 avatar đã cache ở controller, không còn FutureBuilder
                      avatarBytes: controller.avatarBytes,
                    ),

                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        // TAB 0: TRỰC CHIẾN (BẢN ĐỒ)
                        Stack(
                          children: [
                            MapSection(
                              currentPosition: controller.currentPosition,
                              isLoadingLocation: controller.isLoadingLocation,
                              onMapCreated: controller.setMapController,
                              isOnline: controller.isOnline,
                              onRefreshLocation: controller.initLocationService,
                              nearbyUsers: controller.nearbyUsers,
                              // 🟢 Đã nối vào controller (trước đây là stub rỗng)
                              onCallAllRelatives: (user, danhSachNguoiThan) =>
                                  _xuLyGoiNguoiThan(
                                    controller,
                                    user,
                                    danhSachNguoiThan,
                                  ),
                            ),
                            Positioned(
                              top: 16,
                              right: 12,
                              child: Column(
                                children: [
                                  _buildMapActionButton(
                                    Icons.my_location_rounded,
                                    const Color(0xFF475569),
                                    onPressed:
                                        controller.currentPosition == null
                                        ? controller.initLocationService
                                        : controller.centerMapOnCurrentPosition,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        _lazyTab(
                          1,
                          () =>
                              ManHinhLichSuCa(currentUserId: controller.userID),
                        ),
                        _lazyTab(
                          2,
                          () => ThanhTichScreen(userId: controller.userID),
                        ),
                        _lazyTab(
                          3,
                          () => XepHangScreen(userId: controller.userID),
                        ),
                        _lazyTab(
                          4,
                          () => controller.currentUserModel != null
                              ? ThongTinTaiKhoan(
                                  nguoiDung: controller.currentUserModel!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ],
                    ),
                  ),

                  TrangChuBottomPanel(
                    isOnline: controller.isOnline,
                    soLuongCaHoanThanh: controller.soLuongCaHoanThanh,
                    currentTabIndex: _currentTabIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _currentTabIndex = index;
                        _builtTabs.add(index);
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapActionButton(
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}
