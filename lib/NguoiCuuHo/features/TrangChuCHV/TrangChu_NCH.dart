import 'dart:async';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/ThongTinTaiKhoan.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/LichSuCaCuuHo/man_hinh_lich_su_ca.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/header.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/bottom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/map_section.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ManHinhChoTiepNhanCa/ManHinhCho.dart';

class Trangchunguoicuuho extends StatefulWidget {
  final String currentUserId;
  final String maThietBiMoi;
  const Trangchunguoicuuho({
    Key? key,
    required this.currentUserId,
    required this.maThietBiMoi,
  }) : super(key: key);

  @override
  State<Trangchunguoicuuho> createState() => _TrangchunguoicuuhoState();
}

class _TrangchunguoicuuhoState extends State<Trangchunguoicuuho> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<QuerySnapshot>? _assignmentSubscription;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isNavigating = false;
  bool _isKickedOut = false;

  // 🟢 BIẾN LƯU VỊ TRÍ TAB ĐANG ĐƯỢC CHỌN (0: Trực chiến, 1: Lịch sử,...)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenForRescueAssignments();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _firebaseService.capNhatTrangThaiOnline(widget.currentUserId, true);
    } else if (state == AppLifecycleState.detached) {
      _firebaseService.capNhatTrangThaiOnline(widget.currentUserId, false);
    }
  }

  void _listenForRescueAssignments() async {
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_isNavigating) return;
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

          if (snapshot.docs.isNotEmpty) {
            String targetMaYeuCau = '';
            bool hasDangTienTrinh = false;
            bool hasChoTiepNhan = false;

            for (var doc in snapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String trangThai = (data['maTrangThaiTiepNhan'] ?? '').toString();

              String maYeuCauTmp =
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

            if (hasDangTienTrinh && targetMaYeuCau.isNotEmpty) {
              _isNavigating = true;
              _assignmentSubscription?.cancel();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TienTrinhCuuHo(
                    currentUserId: widget.currentUserId,
                    maYeuCauCuuHo: targetMaYeuCau,
                  ),
                ),
              ).then((_) {
                _isNavigating = false;
                _listenForRescueAssignments();
              });
            } else if (hasChoTiepNhan && targetMaYeuCau.isNotEmpty) {
              _isNavigating = true;
              _assignmentSubscription?.cancel();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Manhinhcho(
                    currentUserId: widget.currentUserId,
                    maYeuCauCuuHo: targetMaYeuCau,
                  ),
                ),
              ).then((_) {
                _isNavigating = false;
                _listenForRescueAssignments();
              });
            }
          }
        });
  }

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    if (!_isKickedOut) {
      _firebaseService.capNhatTrangThaiOnline(widget.currentUserId, false);
    }
    super.dispose();
  }

  // Trong Trangchunguoicuuho.dart

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrangChuController(widget.currentUserId),
      child: Consumer<TrangChuController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // 🟢 1. BỌC ĐIỀU KIỆN: CHỈ HIỂN THỊ HEADER KHI Ở TAB 0 (TRỰC CHIẾN)
                      if (_currentTabIndex == 0)
                        FutureBuilder<String?>(
                          future: controller.getAvatarBase64(controller.userID),
                          builder: (context, avatarSnapshot) {
                            return LifeguardProfileHeader(
                              isOnline: controller.isOnline,
                              onOnlineChanged: (val) {
                                controller.toggleOnline(val);
                              },
                              name: controller.name,
                              role: controller.role,
                              maVaiTro: controller.maVaiTro,
                              base64Image: avatarSnapshot.data,
                            );
                          },
                        ),

                      // 2. NỘI DUNG THAY ĐỔI THEO TAB CHỌN
                      Expanded(
                        child: IndexedStack(
                          index: _currentTabIndex,
                          children: [
                            // TAB 0: MÀN HÌNH TRỰC CHIẾN (BẢN ĐỒ)
                            Stack(
                              children: [
                                MapSection(
                                  currentPosition: controller.currentPosition,
                                  isLoadingLocation:
                                      controller.isLoadingLocation,
                                  onMapCreated: controller.setMapController,
                                  isOnline: controller.isOnline,
                                  RefreshLocation:
                                      controller.initLocationService,
                                  nearbyUsers: controller.nearbyUsers,
                                  onCallAllRelatives:
                                      (user, danhSachNguoiThan) async {
                                        // ... giữ nguyên logic gọi người thân
                                      },
                                ),
                                Positioned(
                                  top: 16,
                                  right: 12,
                                  child: Column(
                                    children: [
                                      _buildMapActionButton(
                                        Icons.grid_view_rounded,
                                        const Color(0xFF059669),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildMapActionButton(
                                        Icons.local_fire_department_rounded,
                                        const Color(0xFFF97316),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildMapActionButton(
                                        Icons.layers_rounded,
                                        const Color(0xFF475569),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildMapActionButton(
                                        Icons.my_location_rounded,
                                        const Color(0xFF475569),
                                        onPressed: () {
                                          controller
                                              .centerMapOnCurrentPosition();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // TAB 1: MÀN HÌNH LỊCH SỬ CA CỨU HỘ
                            ManHinhLichSuCa(
                              currentUserId: controller.userID,
                            ), // Truyền currentUserId nếu cần
                            // TAB 2: MÀN HÌNH DỤNG CỤ
                            const Center(child: Text('Màn hình Dụng cụ')),

                            // TAB 3: MÀN HÌNH ĐIỀU PHỐI
                            const Center(child: Text('Màn hình Điều phối')),

                            // TAB 4: MÀN HÌNH HỒ SƠ / THÔNG TIN TÀI KHOẢN
                            controller.currentUserModel != null
                                ? ThongTinTaiKhoan(
                                    nguoiDung: controller.currentUserModel!,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ],
                        ),
                      ),

                      TrangChuBottomPanel(
                        isOnline: controller.isOnline,
                        soLuongCaTiepNhan: controller.soLuongCaTiepNhan,
                        currentTabIndex:
                            _currentTabIndex, // 🟢 Truyền chỉ số tab hiện tại vào đây
                        onTabSelected: (index) {
                          setState(() {
                            _currentTabIndex =
                                index; // Chuyển đổi tab hiển thị trong IndexedStack
                          });
                        },
                      ),
                    ],
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
