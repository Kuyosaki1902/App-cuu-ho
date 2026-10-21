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

                  // 2. Map Section (Đã bỏ thiết lập phạm vi)
                  Expanded(
                    child: MapSection(
                      currentPosition: controller.currentPosition,
                      isLoadingLocation: controller.isLoadingLocation,
                      onMapCreated: controller.setMapController,
                      isOnline: controller.isOnline,
                      RefreshLocation: controller.initLocationService,
                    ),
                  ),

                  // 3. Bottom Panel (Đã bỏ các nút chọn bán kính)
                  TrangChuBottomPanel(
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
