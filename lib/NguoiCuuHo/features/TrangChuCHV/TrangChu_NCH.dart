import 'dart:async';
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
  const Trangchunguoicuuho({Key? key}) : super(key: key);

  @override
  State<Trangchunguoicuuho> createState() => _TrangchunguoicuuhoState();
}

class _TrangchunguoicuuhoState extends State<Trangchunguoicuuho> {
  StreamSubscription<QuerySnapshot>? _assignmentSubscription;

  @override
  void initState() {
    super.initState();
    // 🟢 1. ĐẶT ĐOẠN CODE LẮNG NGHE Ở ĐÂY
    _listenForRescueAssignments();
  }

  // 🟢 HÀM LẮNG NGHE PHÂN CÔNG CỨU HỘ VÀ TỰ ĐỘNG NHẢY SANG MANHINHCHO
  // 🟢 Nhớ import intl để lấy ngày định dạng yyyy-MM-dd

  void _listenForRescueAssignments() {
    String currentUserId = 'nguoidung2'; // ID của cứu hộ viên hiện tại
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 🟢 TRUY VẤN VÀO NÚT: ChiTietPhanCongCuuHo -> maNguoiDung -> DanhSachNgay -> yyyy-MM-dd -> DanhSachPhanCong
    _assignmentSubscription = FirebaseFirestore.instance
        .collection('ChiTietPhanCongCuuHo')
        .doc(currentUserId)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty && mounted) {
            bool coCaChoPhanHoi = false;

            // 🟢 Duyệt qua toàn bộ các maYeuCau trong sub-collection DanhSachPhanCong
            for (var doc in snapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String trangThai = (data['maTrangThaiTiepNhan'] ?? '').toString();

              // Kiểm tra xem có ca nào đang ở trạng thái chờ phản hồi không
              if (trangThai == 'cuuho_trangthai_chophanhoi') {
                coCaChoPhanHoi = true;
                break; // Tìm thấy ca đầu tiên thì dừng vòng lặp
              }
            }

            // 🟢 Nếu có ca chờ phản hồi -> Mở màn hình Manhinhcho
            if (coCaChoPhanHoi) {
              // Hủy lắng nghe tạm thời để tránh mở đè nhiều màn hình trùng lặp
              _assignmentSubscription?.cancel();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Manhinhcho(currentUserId: currentUserId),
                ),
              ).then((_) {
                // Lắng nghe lại khi cứu hộ viên đóng hoặc quay về từ Manhinhcho
                _listenForRescueAssignments();
              });
            }
          }
        });
  }

  @override
  void dispose() {
    // 🟢 HỦY LẮNG NGHE KHỦI MEMORY LEAK KHI DISPOSE WIDGET
    _assignmentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrangChuController(),
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
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/user_home',
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
