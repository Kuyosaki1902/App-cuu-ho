import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/header.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/widgets/bottom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/map_section.dart';

class Trangchunguoicuuho extends StatelessWidget {
  const Trangchunguoicuuho({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Khởi tạo Provider cho màn hình này
    return ChangeNotifierProvider(
      create: (_) => TrangChuController(),
      child: Consumer<TrangChuController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Header Bác sĩ
                  FutureBuilder<String?>(
                    future: controller.getAvatarBase64(controller.userID),
                    builder: (context, avatarSnapshot) {
                      String? avatarBase64 = avatarSnapshot.data;

                      return LifeguardProfileHeader(
                        isOnline: controller.isOnline,
                        onOnlineChanged: (val) {
                          controller.toggleOnline(
                            val,
                          ); // Truyền giá trị từ Header về Controller
                        },
                        name: controller.name,
                        role: controller.role,
                        base64Image:
                            avatarBase64, // 🟢 Truyền dữ liệu Base64 đã giải mã từ LuuAnh & PhanLoaiAnh
                        onExitToUserMode: () {
                          // Điều hướng thoát chế độ Cứu hộ viên về Màn hình người dùng
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/user_home', // Thay đường dẫn bằng Route Màn hình người dùng của bạn
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
                      selectedRadius: controller.selectedRadius,
                      zoomLevel: controller.getZoomLevel(),
                      circleRadiusMeters: controller.getCircleRadiusInMeters(),
                      onMapCreated: controller.setMapController,
                      isOnline: controller.isOnline,
                      RefreshLocation: controller.initLocationService,
                    ),
                  ),

                  // 3. Bottom Panel
                  TrangChuBottomPanel(
                    selectedRadius: controller.selectedRadius,
                    onRadiusSelected: controller.updateSelectedRadius,
                    isOnline: controller.isOnline,
                    timer: controller.timer!,
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
