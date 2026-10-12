import 'package:cuhokhancap/NguoiCuuHo/features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/features/TrangChuCHV/widgets/header.dart';
import 'package:cuhokhancap/NguoiCuuHo/features/TrangChuCHV/widgets/bottom.dart';
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
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Header Bác sĩ
                  LifeguardProfileHeader(
                    isOnline: provider.isOnline,
                    onOnlineChanged: (val) {
                      provider.toggleOnline(
                        val,
                      ); // Truyền value mới từ Header về Controller
                    },
                    name: provider.name,
                    role: provider.role,
                    image: provider.image,
                  ),

                  // 2. Map Section
                  Expanded(
                    child: MapSection(
                      currentPosition: provider.currentPosition,
                      isLoadingLocation: provider.isLoadingLocation,
                      selectedRadius: provider.selectedRadius,
                      zoomLevel: provider.getZoomLevel(),
                      circleRadiusMeters: provider.getCircleRadiusInMeters(),
                      onMapCreated: provider.setMapController,
                      isOnline: provider.isOnline,
                      RefreshLocation: provider.initLocationService,
                    ),
                  ),

                  // 3. Bottom Panel
                  TrangChuBottomPanel(
                    selectedRadius: provider.selectedRadius,
                    onRadiusSelected: provider.updateSelectedRadius,
                    isOnline: provider.isOnline,
                    timer: provider.timer!,
                    soLuongCaTiepNhan: provider.soLuongCaTiepNhan,
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
