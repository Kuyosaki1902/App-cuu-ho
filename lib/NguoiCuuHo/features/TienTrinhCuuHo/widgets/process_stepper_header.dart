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
          // 🔴 1. HEADER BÁC SĨ & TRẠNG THÁI (Theo đúng hình ảnh mẫu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Nút quay lại (Back Button)
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF1E293B),
                    ),
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
                              'Hanh',
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
                          Text(
                            ' • Live #08429',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icon Phát sóng (Live/SOS)
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
                const SizedBox(width: 8),

                // Avatar BS (Viền đỏ)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE52525),
                      width: 1.5,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Text(
                      'BS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE52525),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 🟢 2. THANH STEPPER 4 BƯỚC (Giữ nguyên logic điều hướng)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStepItem(
                  index: 0,
                  currentIndex: step,
                  title: '1. Di chuyển',
                  subtitle: step > 0 ? 'Đã tới' : 'Đang tới',
                  icon: Icons.directions_run,
                ),
                _buildLine(isActive: step >= 1),
                _buildStepItem(
                  index: 1,
                  currentIndex: step,
                  title: '2. Đến nơi',
                  subtitle: step > 1 ? '100%' : 'Tiếp cận',
                  icon: Icons.location_on,
                ),
                _buildLine(isActive: step >= 2),
                _buildStepItem(
                  index: 2,
                  currentIndex: step,
                  title: '3. Cứu nạn',
                  subtitle: step > 2 ? 'Sơ cứu xong' : 'Sơ cứu',
                  icon: Icons.medical_services,
                ),
                _buildLine(isActive: step >= 3),
                _buildStepItem(
                  index: 3,
                  currentIndex: step,
                  title: '4. Hoàn tất',
                  subtitle: step == 3 ? 'Bàn giao' : 'Bàn giao',
                  icon: Icons.local_shipping,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required int currentIndex,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;

    Color circleColor = Colors.grey.shade200;
    Color iconColor = Colors.grey;
    if (isDone) {
      circleColor = const Color(0xFF00C853);
      iconColor = Colors.white;
    } else if (isCurrent) {
      circleColor = const Color(0xFFE52525);
      iconColor = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: circleColor,
          child: Icon(isDone ? Icons.check : icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? const Color(0xFFE52525) : Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 8,
            color: isDone ? const Color(0xFF00C853) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF00C853) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }
}
