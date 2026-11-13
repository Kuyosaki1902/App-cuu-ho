import 'package:flutter/material.dart';

class CardCanhBaoKhoaNhanCa extends StatelessWidget {
  final bool isCoCCHN;
  const CardCanhBaoKhoaNhanCa({super.key, this.isCoCCHN = false});

  @override
  Widget build(BuildContext context) {
    final text = isCoCCHN
        ? 'Trong thời gian thẩm định, quyền kích hoạt nhận ca trực ngoại viện tạm thời được khóa '
            'nhằm đảm bảo an toàn y khoa.'
        : 'Trong thời gian thẩm định, bạn chưa thể nhận ca. Sau khi được duyệt, bạn bắt đầu ở '
            'cấp uy tín 1 (chỉ nhận ca mức nhẹ, luôn nhắc gọi 115). Bạn là người hỗ trợ sơ cấp cứu, '
            'không phải nhân viên y tế.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
