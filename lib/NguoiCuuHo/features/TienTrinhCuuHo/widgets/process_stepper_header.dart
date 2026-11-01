import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class ProcessStepperHeader extends StatelessWidget {
  const ProcessStepperHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();
    final int step = controller.currentStep;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴 1. HEADER BÁC SĨ & TRẠNG THÁI (Đã đổi Avatar sang bên trái tên)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // 🟢 ĐẶT AVATAR BÊN TRÁI TÊN
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE52525),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        (controller.doctorAvatarUrl != null &&
                            controller.doctorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(controller.doctorAvatarUrl!)
                        : null,
                    child:
                        (controller.doctorAvatarUrl == null ||
                            controller.doctorAvatarUrl!.isEmpty)
                        ? const Text(
                            'BS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE52525),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Thông tin Bác sĩ & Tag 115
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.doctorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFCDD2),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              '115',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE52525),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Đang trực cứu hộ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icon Phát sóng / Sẵn sàng bên phải (nếu cần)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors,
                    size: 20,
                    color: Color(0xFFE52525),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 🟢 2. THANH STEPPER 4 BƯỚC
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStepItem(0, step, '1. Di chuyển', Icons.directions_run),
                _buildLine(step >= 1),
                _buildStepItem(1, step, '2. Đến nơi', Icons.location_on),
                _buildLine(step >= 2),
                _buildStepItem(2, step, '3. Cứu nạn', Icons.medical_services),
                _buildLine(step >= 3),
                _buildStepItem(3, step, '4. Hoàn tất', Icons.local_shipping),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    int index,
    int currentIndex,
    String title,
    IconData icon,
  ) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDone
              ? const Color(0xFF00C853)
              : (isCurrent ? const Color(0xFFE52525) : Colors.grey.shade200),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF00C853) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }
}
