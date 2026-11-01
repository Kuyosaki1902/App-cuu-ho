import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class Step2ArrivedHeader extends StatelessWidget {
  const Step2ArrivedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 Lấy controller để đọc địa chỉ và tọa độ thực tế của nạn nhân
    final controller = context.watch<RescueProcessController>();

    return Container(
      width: double.infinity,
      height: 95,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '📍 ĐÃ ĐẾN VỊ TRÍ NẠN NHÂN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tiếp cận 100%',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 🟢 Hiển thị tọa độ thực tế từ controller của nạn nhân
          Text(
            'Tọa độ: ${controller.victimLocation.latitude.toStringAsFixed(4)}° N, ${controller.victimLocation.longitude.toStringAsFixed(4)}° E (Sai số: ±3m)',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          // 🟢 Hiển thị địa chỉ text thực tế đã geocode từ Firestore
          Text(
            controller.victimAddress,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
