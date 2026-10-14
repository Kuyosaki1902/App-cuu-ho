import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/emergency_alert_controller.dart';
import 'widgets/doctor_header_card.dart';
import 'widgets/critical_alert_card.dart';
import 'widgets/map_navigation_card.dart';
import 'widgets/victim_info_card.dart';

class Manhinhcho extends StatelessWidget {
  const Manhinhcho({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyAlertController(),
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
                      // 🟢 Ép chiều cao tối thiểu bằng chính chiều cao màn hình khả dụng
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Header Bác sĩ
                              const DoctorHeaderCard(),
                              const SizedBox(height: 10),

                              // 2. Thẻ Cảnh Báo Nguy Kịch
                              const CriticalAlertCard(),
                              const SizedBox(height: 10),

                              // 3. Khung Bản đồ & Địa chỉ (🟢 Tự co giãn để lấp đầy khoảng trống)
                              const Expanded(child: MapNavigationCard()),
                              const SizedBox(height: 10),

                              // 4. Thông tin Nạn nhân & Video
                              const VictimInfoCard(),
                              const SizedBox(height: 12),

                              // 5. Nút Dẫn Đường Ngay
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
                                  onPressed: () => controller.startNavigation(),
                                  icon: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'DẪN ĐƯỜNG NGAY',
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
