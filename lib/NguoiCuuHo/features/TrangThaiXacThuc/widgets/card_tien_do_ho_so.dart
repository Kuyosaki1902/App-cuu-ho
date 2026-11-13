import 'package:flutter/material.dart';

import '../controllers/trang_thai_xac_thuc_controller.dart';

/// Checklist tiến độ: người dùng biết hồ sơ đang kẹt ở mục nào.
class CardTienDoHoSo extends StatelessWidget {
  final List<MucKiemTra> items;
  const CardTienDoHoSo({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ thẩm định',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < items.length; i++) ...[
            _Dong(muc: items[i]),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Dong extends StatelessWidget {
  final MucKiemTra muc;
  const _Dong({required this.muc});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color mau;
    switch (muc.trangThai) {
      case MucTienDo.dat:
        icon = Icons.check_circle;
        mau = const Color(0xFF137333);
        break;
      case MucTienDo.canXuLy:
        icon = Icons.error;
        mau = const Color(0xFFB91C1C);
        break;
      case MucTienDo.dangCho:
        icon = Icons.schedule;
        mau = const Color(0xFF64748B);
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: mau),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                muc.tieuDe,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                muc.moTa,
                style: TextStyle(fontSize: 11.5, color: mau, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
