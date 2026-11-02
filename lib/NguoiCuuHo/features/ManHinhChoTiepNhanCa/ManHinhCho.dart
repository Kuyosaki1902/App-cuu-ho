import 'dart:async';

import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/emergency_alert_controller.dart';
import 'widgets/doctor_header_card.dart';
import 'widgets/critical_alert_card.dart';
import 'widgets/map_navigation_card.dart';
import 'widgets/victim_info_card.dart';

class Manhinhcho extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;

  const Manhinhcho({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = EmergencyAlertController();
        //Kích hoạt lắng nghe dữ liệu từ YeuCauCuuHo và ChiTietPhanCongCuuHo
        controller.listenForNewAssignment(currentUserId, context);
        return controller;
      },
      child: Consumer<EmergencyAlertController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const DoctorHeaderCard(),
                              const SizedBox(height: 10),
                              const CriticalAlertCard(),
                              const SizedBox(height: 10),
                              const Expanded(child: MapNavigationCard()),
                              const SizedBox(height: 10),
                              const VictimInfoCard(),
                              const SizedBox(height: 12),
                              // Trong tệp ManHinhCho.dart (hoặc ManHinhCho_2.dart)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    // 🟢 Chuyển màu nút dựa vào mức độ khẩn cấp (1: Đỏ, 2: Vàng đậm/Cam)
                                    backgroundColor:
                                        controller.mucDoKhanCap == 1
                                        ? const Color(0xFFE52525)
                                        : Colors.amber.shade800,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () async {
                                    String doctorId =
                                        controller.currentDoctorId;
                                    String maYeuCau =
                                        controller.currentMaYeuCau;

                                    // 🟢 Gọi hàm nhận ca (hàm này đã được bổ sung hủy timer ở trên)
                                    await controller.acceptAssignment();

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TienTrinhCuuHo(
                                            currentUserId: doctorId,
                                            maYeuCauCuuHo: maYeuCau,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'CỨU HỘ NGAY',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
