import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';

class CriticalAlertCard extends StatelessWidget {
  const CriticalAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyAlertController>();

    bool isLevel1 = controller.mucDoKhanCap == 1;
    Color themeColor = isLevel1
        ? const Color(0xFFDC2626)
        : Colors.amber.shade800;
    Color borderColor = isLevel1
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFDE68A);
    Color badgeBgColor = isLevel1
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    String labelText = isLevel1 ? 'NGUY KỊCH (TRIAGE RED)' : 'CẤP ĐỘ 2';
    String titleText = isLevel1
        ? 'CẢNH BÁO CẤP NGUY KỊCH'
        : 'CẢNH BÁO CẤP ĐỘ 2';

    int percent = (controller.progressValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isLevel1
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 15, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      controller.formattedTimer,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF475569),
              ),
              children: [
                const TextSpan(
                  text:
                      'Sự cố y tế khẩn cấp đã đối soát năng lực và vị trí trực chiến gần nhất với bạn (Bán kính ',
                ),
                TextSpan(
                  text: controller.distanceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const TextSpan(text: ').'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thời hạn phản hồi chấp nhận ca',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: controller.progressValue,
              minHeight: 6,
              backgroundColor: isLevel1
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFFEF3C7),
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
        ],
      ),
    );
  }
}
