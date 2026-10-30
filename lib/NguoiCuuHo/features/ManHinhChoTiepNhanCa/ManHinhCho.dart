import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/emergency_alert_controller.dart';
import 'widgets/doctor_header_card.dart';
import 'widgets/critical_alert_card.dart';
import 'widgets/map_navigation_card.dart';
import 'widgets/victim_info_card.dart';

class Manhinhcho extends StatelessWidget {
  final String currentUserId; // 🟢 Truyền mã cứu hộ viên vào màn hình

  const Manhinhcho({super.key, this.currentUserId = 'nguoidung2'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = EmergencyAlertController();
        // 🟢 Kích hoạt lắng nghe dữ liệu từ YeuCauCuuHo và ChiTietPhanCongCuuHo
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
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE52525),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TienTrinhCuuHo(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'NHẬN CỨU HỘ',
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
