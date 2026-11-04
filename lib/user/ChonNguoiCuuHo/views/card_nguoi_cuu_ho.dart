// views/card_nguoi_cuu_ho.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/controllers/chon_nguoi_cuu_ho_controller.dart';

class CardNguoiCuuHoWidget extends StatelessWidget {
  final ItemNguoiCuuHo item;
  final bool isSelected;
  final VoidCallback onTap;

  const CardNguoiCuuHoWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarBg = item.coCCHN
        ? const Color(0xFFD2F5EC)
        : const Color(0xFFFEF3C7);
    final avatarText = item.coCCHN
        ? const Color(0xFF0C5C4D)
        : const Color(0xFFB45309);
    final badgeBg = item.coCCHN
        ? const Color(0xFFE2F7F2)
        : const Color(0xFFFFFBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C5C4D) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: avatarBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          item.initials,
                          style: TextStyle(
                            color: avatarText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (item.coCCHN)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0C5C4D),
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nguoiDung.hoTen,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.tenChuyenNganh,
                              style: TextStyle(
                                color: avatarText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${item.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            ' (${item.reviewsCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.formattedDistance,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.timeArrival,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0C5C4D)
                          : Colors.grey[300]!,
                      width: isSelected ? 6 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.nguoiDung.soDienThoai,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.coCCHN ? 'Sẵn sàng ngay' : 'Tình nguyện viên',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
