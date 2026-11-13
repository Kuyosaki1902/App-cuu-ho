import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/emergency_alert_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';

/// Thẻ nổi phía trên bản đồ: cứu hộ viên + nút tắt chuông + cảnh báo GPS.
class DoctorHeaderCard extends StatelessWidget {
  const DoctorHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyAlertController>();
    final hasUrl = c.doctorAvatarUrl != null && c.doctorAvatarUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RC.line),
            boxShadow: RC.shadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: RC.blueSoft,
                backgroundImage: hasUrl ? NetworkImage(c.doctorAvatarUrl!) : null,
                onBackgroundImageError: hasUrl ? (_, __) {} : null,
                child: hasUrl
                    ? null
                    : Text(
                        c.doctorInitials,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RC.blue,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        // Dấu xác thực chỉ hiện khi có chứng chỉ hành nghề thật.
                        if (c.doctorHasLicense) ...[
                          const Icon(Icons.verified, size: 14, color: RC.green),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            c.doctorRoleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: RC.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (c.isSoundOn)
                IconButton(
                  tooltip: 'Tắt chuông',
                  onPressed: c.stopEmergencySound,
                  icon: const Icon(Icons.volume_off_outlined, color: RC.ink),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
            ],
          ),
        ),
        if (c.locationWarning != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RC.amberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RC.amberLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_off, size: 16, color: RC.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.locationWarning!,
                      style: const TextStyle(fontSize: 12.5, color: RC.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
