import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/emergency_alert_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/alert_style.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';

/// Vòng đếm ngược + thông tin quyết định (khoảng cách, thời gian ước tính).
class CriticalAlertCard extends StatelessWidget {
  const CriticalAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyAlertController>();
    final style = AlertStyle.of(c.mucDoKhanCap);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Chỉ vòng đếm ngược rebuild mỗi giây.
              ValueListenableBuilder<int>(
                valueListenable: c.remainingSeconds,
                builder: (_, left, __) {
                  final urgent = left <= 30;
                  final ringColor = urgent ? RC.red : style.color;
                  return SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: CircularProgressIndicator(
                            value: left / EmergencyAlertController.totalSeconds,
                            strokeWidth: 6,
                            backgroundColor: style.soft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ringColor,
                            ),
                          ),
                        ),
                        Text(
                          EmergencyAlertController.formatCountdown(left),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: urgent ? RC.red : RC.ink,
                            fontFeatures: RC.tabular,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RcPill(
                      text: style.label,
                      fg: style.color,
                      bg: style.soft,
                      icon: Icons.priority_high,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Có ca cấp cứu gần bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cách bạn ${c.distanceText}'
                      '${c.isMyLocationApproximate ? ' (ước tính)' : ''}',
                      style: const TextStyle(fontSize: 13.5, color: RC.body),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Thời gian di chuyển ước tính',
            style: TextStyle(fontSize: 12.5, color: RC.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(
                mode: 'moto',
                icon: Icons.two_wheeler_rounded,
                label: 'Xe máy',
                controller: c,
                color: style.color,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                mode: 'car',
                icon: Icons.directions_car_filled_outlined,
                label: 'Ô tô',
                controller: c,
                color: style.color,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                mode: 'walk',
                icon: Icons.directions_walk_rounded,
                label: 'Đi bộ',
                controller: c,
                color: style.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Nếu không phản hồi trước khi hết giờ, ca sẽ chuyển cho người khác.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: RC.muted),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String mode;
  final IconData icon;
  final String label;
  final EmergencyAlertController controller;
  final Color color;

  const _ModeChip({
    required this.mode,
    required this.icon,
    required this.label,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedTravelMode == mode;
    return Expanded(
      child: Material(
        color: selected ? color : RC.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.changeTravelMode(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : RC.muted),
                const SizedBox(height: 4),
                Text(
                  controller.etaText(mode),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : RC.ink,
                    fontFeatures: RC.tabular,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: selected ? Colors.white70 : RC.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
