// lib/BangXepHangCuuHo/views/rescuer_card_item.dart

import 'package:cuhokhancap/user/BangXepHangCuuHo/controllers/bang_xep_hang_controller.dart';
import 'package:flutter/material.dart';

class RescuerCardItemWidget extends StatelessWidget {
  final RescuerLeaderboardItemModel item;

  const RescuerCardItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Color? cardBgColor;
    Color borderColor = Colors.transparent;

    if (item.rank == 1) {
      cardBgColor = const Color(0xFFFFFDF0);
      borderColor = const Color(0xFFFEF08A);
    } else if (item.rank == 2) {
      cardBgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
    } else if (item.rank == 3) {
      cardBgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFFEDD5);
    } else {
      cardBgColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Vương miện / Thứ hạng
          SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.rank == 1)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 20,
                  )
                else if (item.rank == 2)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  )
                else if (item.rank == 3)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                const SizedBox(height: 2),
                Text(
                  '#${item.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.rank <= 3 ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 2. Avatar & Badge Đánh giá
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.rank == 1
                        ? Colors.amber
                        : item.rank == 2
                        ? const Color(0xFF94A3B8)
                        : item.rank == 3
                        ? const Color(0xFFD97706)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.rating}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' (${item.reviewsCount})',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // 3. Thông tin tên, số ca & tổ chức
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.user.hoTen,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.casesCount} ca hỗ trợ',
                    style: const TextStyle(
                      color: Color(0xFF0C5C4D),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.specialty,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.organization,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 4. Nút Nhắn tin
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[100],
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: Colors.black54,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
