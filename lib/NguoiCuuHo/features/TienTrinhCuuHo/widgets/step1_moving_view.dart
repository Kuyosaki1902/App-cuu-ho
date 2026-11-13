import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Bước 1: khoảng cách còn lại, thời gian dự kiến và tiến độ tiếp cận.
class Step1MovingHeader extends StatelessWidget {
  const Step1MovingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final near = c.isNearVictim;
    final progress = c.approachProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RC.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Còn lại đến nạn nhân',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.remainingDistanceText,
                      style: const TextStyle(
                        fontSize: 38,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFeatures: RC.tabular,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, size: 15, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      '${c.currentSpeedKmH.round()} km/h',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFeatures: RC.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.etaText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: near ? FontWeight.w700 : FontWeight.w400,
              color: near ? RC.greenLight : Colors.white70,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  near ? RC.greenLight : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
