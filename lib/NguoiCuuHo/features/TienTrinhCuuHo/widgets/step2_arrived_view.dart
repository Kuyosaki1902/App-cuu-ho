import 'package:flutter/material.dart';

class Step2ArrivedHeader extends StatelessWidget {
  const Step2ArrivedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 🟢 Full Width
      height: 95, // 🟢 Chiều cao đồng nhất
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '📍 ĐÃ ĐẾN VỊ TRÍ NẠN NHÂN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tiếp cận 100%',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tọa độ: 10.7324° N, 106.7218° E (Sai số: ±3m)',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hẻm 142/18 Huỳnh Tấn Phát, P. Tân Thuận Tây, Q.7',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
