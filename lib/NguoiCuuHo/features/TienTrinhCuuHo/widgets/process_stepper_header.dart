import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Thẻ nổi: cứu hộ viên + mã ca + tiến trình 4 bước.
class ProcessStepperHeader extends StatelessWidget {
  const ProcessStepperHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final code = c.maYeuCau.length > 8
        ? c.maYeuCau.substring(c.maYeuCau.length - 8)
        : c.maYeuCau;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RC.line),
        boxShadow: RC.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Avatar(url: c.doctorAvatarUrl, initials: c.doctorInitials),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: RC.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Đang trực · ${c.doctorRoleLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RC.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mã ca',
                    style: TextStyle(fontSize: 11, color: RC.muted),
                  ),
                  Text(
                    '#$code',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: RC.ink,
                      fontFeatures: RC.tabular,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StepRow(step: c.currentStep),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String initials;
  const _Avatar({required this.url, required this.initials});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RC.red, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 19,
        backgroundColor: RC.redSoft,
        backgroundImage: hasUrl ? NetworkImage(url!) : null,
        onBackgroundImageError: hasUrl ? (_, __) {} : null,
        child: hasUrl
            ? null
            : Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RC.red,
                ),
              ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int step;
  const _StepRow({required this.step});

  static const _labels = ['Di chuyển', 'Đến nơi', 'Cứu nạn', 'Hoàn tất'];
  static const _icons = [
    Icons.directions_run,
    Icons.place_outlined,
    Icons.medical_services_outlined,
    Icons.task_alt,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++) ...[
          _StepNode(
            label: _labels[i],
            icon: _icons[i],
            done: i < step,
            current: i == step,
          ),
          if (i < 3)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 13),
                height: 2,
                color: step > i ? RC.green : RC.line,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool done;
  final bool current;

  const _StepNode({
    required this.label,
    required this.icon,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? RC.green : (current ? RC.red : RC.surface),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: RC.red.withOpacity(0.2),
                        spreadRadius: 4,
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              done ? Icons.check : icon,
              size: 16,
              color: (done || current) ? Colors.white : RC.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              color: current ? RC.ink : RC.muted,
            ),
          ),
        ],
      ),
    );
  }
}
