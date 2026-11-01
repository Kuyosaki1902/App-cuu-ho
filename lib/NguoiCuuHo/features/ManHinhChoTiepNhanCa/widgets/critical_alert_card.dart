import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';

class CriticalAlertCard extends StatelessWidget {
  const CriticalAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyAlertController>();

    // 🟢 Kiểm tra mức độ khẩn cấp để đổi màu linh hoạt (1: Đỏ, 2: Vàng/Cam)
    bool isLevel1 = controller.mucDoKhanCap == 1;
    Color themeColor = isLevel1 ? Colors.red : Colors.amber.shade800;
    Color bgColor = isLevel1
        ? const Color(0xFFFFF5F5)
        : const Color(0xFFFFFBEB);
    Color borderColor = isLevel1
        ? const Color(0xFFFFCDD2)
        : const Color(0xFFFDE68A);
    Color badgeBgColor = isLevel1
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFFEF3C7);
    String labelText = isLevel1 ? 'NGUY KỊCH' : 'CẤP ĐỘ 2';
    String titleText = isLevel1
        ? 'CẢNH BÁO CẤP NGUY KỊCH'
        : 'CẢNH BÁO CẤP ĐỘ 2';
    String descText = isLevel1
        ? 'Sự cố y tế nguy kịch đã đối soát năng lực phản ứng gần bạn'
        : 'Sự cố y tế cấp độ 2 đã đối soát năng lực phản ứng gần bạn';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: themeColor, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: themeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      controller.formattedTimer,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descText,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Progress Bar chạy theo Controller
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.progressValue,
              minHeight: 6,
              backgroundColor: isLevel1
                  ? Colors.red.shade100
                  : Colors.amber.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
        ],
      ),
    );
  }
}
