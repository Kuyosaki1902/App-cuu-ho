import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart'; // Kiểm tra đúng đường dẫn model của bạn

class ChiTietNguoiCuuHoCard extends StatelessWidget {
  final NguoiDungModel rescuer;
  final String distanceText;
  final VoidCallback onSendRequest;
  final VoidCallback onClose;

  const ChiTietNguoiCuuHoCard({
    super.key,
    required this.rescuer,
    required this.distanceText,
    required this.onSendRequest,
    required this.onClose,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "CH";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String initials = _getInitials(rescuer.hoTen);
    String nameDisplay = rescuer.hoTen.isNotEmpty
        ? rescuer.hoTen
        : "Người cứu hộ";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00695C).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF00695C),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00C853),
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Thông tin người cứu hộ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nameDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Sẵn sàng cứu hộ",
                            style: TextStyle(
                              color: Color(0xFF00695C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.near_me,
                          size: 12,
                          color: Color(0xFF00695C),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            color: Color(0xFF004D40),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Nút Gửi yêu cầu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSendRequest,
              icon: const Icon(
                Icons.send_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                "GỬI YÊU CẦU BÁC SĨ / CỨU HỘ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
