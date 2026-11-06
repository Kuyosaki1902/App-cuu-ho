import 'dart:async';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:cuhokhancap/user/TrangChuNguoiDung.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/header.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/bottom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/map_section.dart';
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
  bool _isNavigating = false; // Biến cờ ngăn việc gọi Navigator.push liên tục

  @override
  void initState() {
    super.initState();
    // 🟢 Khởi động lắng nghe thời gian thực phân công cứu hộ
    _listenForRescueAssignments();
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

              debugPrint(
                '📄 Quét thấy ca: $maYeuCauTmp | Trạng thái: $trangThai',
              );

              // 🟢 1. CHỐT CHẶN AN TOÀN: Bỏ qua ngay lập tức các ca đã kết thúc
              if (trangThai == 'cuuho_trangthai_phancong_hoanthanh' ||
                  trangThai == 'cuuho_trangthai_phancong_dahuy' ||
                  trangThai == 'cuuho_trangthai_phancong_tuchoi') {
                continue; // Lờ đi ca này và quét tiếp ca khác
              }

              // 🚀 2. ƯU TIÊN 1: Ca đang trong tiến trình cứu hộ (Step 1, 2, 3)
              if (trangThai == 'cuuho_trangthai_phancong_tiepnhan' ||
                  trangThai == 'cuuho_trangthai_phancong_daden' ||
                  trangThai == 'cuuho_trangthai_phancong_dangcuuho') {
                hasDangTienTrinh = true;
                targetMaYeuCau = maYeuCauTmp;
                break;
              }

              // ⏳ 3. Trạng thái chờ đổ chuông
              if (trangThai == 'cuuho_trangthai_phancong_chotiepnhan' ||
                  trangThai.isEmpty) {
                hasChoTiepNhan = true;
                targetMaYeuCau = maYeuCauTmp;
              }
            }

            // Điều hướng
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
    // 🟢 Hủy lắng nghe để tránh rò rỉ bộ nhớ (Memory Leak)
    _assignmentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String maThietBiMoi = DateTime.now().millisecondsSinceEpoch.toString();
    return ChangeNotifierProvider(
      create: (_) => TrangChuController(widget.currentUserId),
      child: Consumer<TrangChuController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Header Cứu hộ viên
                  FutureBuilder<String?>(
                    future: controller.getAvatarBase64(controller.userID),
                    builder: (context, avatarSnapshot) {
                      String? avatarBase64 = avatarSnapshot.data;

                      return LifeguardProfileHeader(
                        isOnline: controller.isOnline,
                        onOnlineChanged: (val) {
                          controller.toggleOnline(val);
                        },
                        name: controller.name,
                        role: controller.role,
                        base64Image: avatarBase64,
                        onExitToUserMode: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrangChuNguoiDung(
                                maNguoiDung: controller.userID,
                                maThietBi: maThietBiMoi,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                      );
                    },
                  ),

                  // 2. Map Section
                  Expanded(
                    child: MapSection(
                      currentPosition: controller.currentPosition,
                      isLoadingLocation: controller.isLoadingLocation,
                      onMapCreated: controller.setMapController,
                      isOnline: controller.isOnline,
                      RefreshLocation: controller.initLocationService,
                      nearbyUsers: controller.nearbyUsers,
                      onCallAllRelatives: (user, danhSachNguoiThan) async {
                        debugPrint(
                          '👉 [TrangChu] Đã nhận callback onCallAllRelatives!',
                        );

                        String victimUserId = user['userId'] ?? '';
                        String victimName = user['hoTen'] ?? 'Người dùng';

                        if (victimUserId.isEmpty) {
                          debugPrint('❌ Lỗi: victimUserId bị trống!');
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đang kích hoạt cuộc gọi khẩn cấp tới toàn bộ người thân...',
                            ),
                          ),
                        );

                        try {
                          await controller.triggerEmergencyCallToRelative(
                            victimUserId: victimUserId,
                            danhSachNguoiThan: danhSachNguoiThan,
                            victimName: victimName,
                          );
                        } catch (e) {
                          debugPrint('❌ [TrangChu] Lỗi khi gọi controller: $e');
                        }
                      },
                    ),
                  ),

                  // 3. Bottom Panel
                  TrangChuBottomPanel(
                    isOnline: controller.isOnline,
                    soLuongCaTiepNhan: controller.soLuongCaTiepNhan,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
