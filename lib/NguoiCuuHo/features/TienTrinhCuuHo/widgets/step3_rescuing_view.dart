import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Bước 3: đồng hồ can thiệp. Đồng hồ tính theo mốc thời gian thực nên
/// không sai khi app ở nền, và chỉ phần số này rebuild mỗi giây.
class Step3RescuingHeader extends StatelessWidget {
  const Step3RescuingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<RescueProcessController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RC.redDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thời gian can thiệp',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Đang cứu nạn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<int>(
            valueListenable: c.ticker,
            builder: (_, __, ___) => Text(
              c.formattedRescueTime,
              style: const TextStyle(
                fontSize: 46,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: RC.tabular,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bắt đầu lúc ${clock(c.rescueStartedAt)}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
