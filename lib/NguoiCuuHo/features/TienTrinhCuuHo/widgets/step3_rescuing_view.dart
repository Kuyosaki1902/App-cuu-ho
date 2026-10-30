import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class Step3RescuingHeader extends StatelessWidget {
  const Step3RescuingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();

    return Container(
      width: double.infinity, // 🟢 Full Width
      height: 95, // 🟢 Chiều cao đồng nhất
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE52525),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'THỜI GIAN CAN THIỆP TRỰC TIẾP',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            controller.formattedRescueTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Đang sơ cứu & cố định vết thương tại chỗ',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
