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
        controller.listenForNewAssignment(currentUserId, context);
        return controller;
      },
      child: Consumer<EmergencyAlertController>(
        builder: (context, controller, child) {
          bool isLevel1 = controller.mucDoKhanCap == 1;
          Color themeColor = isLevel1
              ? const Color(0xFFDC2626)
              : Colors.amber.shade800;

          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            body: SafeArea(
              child: Column(
                children: [
                  // Nội dung cuộn chính
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          DoctorHeaderCard(),
                          SizedBox(height: 14),
                          CriticalAlertCard(),
                          SizedBox(height: 14),
                          MapNavigationCard(),
                          SizedBox(height: 14),
                          VictimInfoCard(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Thanh hành động cố định bên dưới
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              String doctorId = controller.currentDoctorId;
                              String maYeuCau = controller.currentMaYeuCau;

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
                              Icons.arrow_drop_up_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'TIẾP NHẬN & CỨU HỘ NGAY',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: themeColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
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
