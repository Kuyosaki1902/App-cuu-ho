import 'package:flutter/material.dart';

class CardCanhBaoKhoaNhanCa extends StatelessWidget {
  const CardCanhBaoKhoaNhanCa({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trong thời gian thẩm định, quyền kích hoạt nhận ca trực ngoại viện tạm thời được khóa nhằm đảm bảo an toàn y khoa.',
              style: TextStyle(
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
