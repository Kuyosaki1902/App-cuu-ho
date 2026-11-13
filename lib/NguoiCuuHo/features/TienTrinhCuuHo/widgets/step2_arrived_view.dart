import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Bước 2: đã có mặt tại hiện trường. Toàn bộ số liệu là dữ liệu thật.
class Step2ArrivedHeader extends StatelessWidget {
  const Step2ArrivedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final acc = c.gpsAccuracyMeters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RC.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đã đến hiện trường',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                clock(c.arrivedAt),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  fontFeatures: RC.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            c.victimAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (c.hasVictimLocation)
                'Toạ độ ${c.victimLocation.latitude.toStringAsFixed(5)}, '
                    '${c.victimLocation.longitude.toStringAsFixed(5)}',
              if (acc != null) 'GPS sai số ±${acc.round()} m',
            ].join('   '),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFeatures: RC.tabular,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kiểm tra an toàn hiện trường trước khi tiếp cận nạn nhân.',
                    style: TextStyle(fontSize: 12.5, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
