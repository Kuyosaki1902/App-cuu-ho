import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class TeamMembersCard extends StatelessWidget {
  const TeamMembersCard({super.key});

  // 🚀 HÀM HiỂN THỊ BOTTOM SHEET TRƯỢT TỪ DƯỚI LÊN
  void _showTeamBottomSheet(BuildContext context) {
    final controller = context.read<RescueProcessController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo gạch ngang phía trên Bottom Sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Tiêu đề Bottom Sheet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.groups, color: Color(0xFFE52525), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Danh sách lực lượng tiếp cận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // 👥 DANH SÁCH THÀNH VIÊN TRONG BOTTOM SHEET
              _buildMemberItemInSheet(
                avatarText: 'LN',
                avatarColor: const Color(0xFFE0F2FE),
                textColor: const Color(0xFF0369A1),
                name: 'BS. CKI Lê Nam',
                role: 'Ngoại chấn thương • Đã có mặt tại chỗ',
                statusTag: 'Tại chỗ',
                statusColor: const Color(0xFF10B981),
                phone: '0901234567',
                onCall: () {
                  Navigator.pop(modalContext);
                  controller.makePhoneCall('0901234567');
                },
              ),
              const SizedBox(height: 12),
              _buildMemberItemInSheet(
                avatarText: 'KO',
                avatarColor: const Color(0xFFF3E8FF),
                textColor: const Color(0xFF7E22CE),
                name: 'ĐĐ. Hoàng Kim Oanh',
                role: 'Hồi sức cấp cứu • Đang cách 150m',
                statusTag: 'Cách 150m',
                statusColor: const Color(0xFFF59E0B),
                phone: '0908765432',
                onCall: () {
                  Navigator.pop(modalContext);
                  controller.makePhoneCall('0908765432');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_outlined, color: Color(0xFFE52525), size: 20),
              SizedBox(width: 8),
              Text(
                'ĐỘI NGŨ CÙNG TIẾP CẬN (02 NGƯỜI)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          // 🟢 NÚT BẤM KÍCH HOẠT BOTTOM SHEET TRƯỢT TỪ DƯỚI LÊN
          InkWell(
            onTap: () => _showTeamBottomSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text(
                    'Xem danh sách',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Color(0xFF00897B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget dòng thông tin từng bác sĩ / điều dưỡng trong Bottom Sheet
  Widget _buildMemberItemInSheet({
    required String avatarText,
    required Color avatarColor,
    required Color textColor,
    required String name,
    required String role,
    required String statusTag,
    required Color statusColor,
    required String phone,
    required VoidCallback onCall,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(
              avatarText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusTag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF00897B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
