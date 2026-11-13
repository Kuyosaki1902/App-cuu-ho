import 'package:flutter/material.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThanhTich/thanh_tich_screen.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/xep_hang_screen.dart';

class ThanhTichEntryCard extends StatelessWidget {
  final String userId;
  const ThanhTichEntryCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final bam = userId.isEmpty;
    return Row(
      children: [
        Expanded(
          child: _Loi(
            icon: Icons.emoji_events_rounded,
            mau: const Color(0xFFCA8A04),
            nen: const Color(0xFFFEF3C7),
            tieuDe: 'Thành tích',
            moTa: 'Cấp bậc, huy hiệu',
            onTap: bam ? null : () => ThanhTichScreen.mo(context, userId),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Loi(
            icon: Icons.leaderboard_rounded,
            mau: const Color(0xFFDC2626),
            nen: const Color(0xFFFEE2E2),
            tieuDe: 'Xếp hạng',
            moTa: 'Tuần, tháng, mọi thời gian',
            onTap: bam ? null : () => XepHangScreen.mo(context, userId),
          ),
        ),
      ],
    );
  }
}

class _Loi extends StatelessWidget {
  final IconData icon;
  final Color mau;
  final Color nen;
  final String tieuDe;
  final String moTa;
  final VoidCallback? onTap;
  const _Loi({
    required this.icon,
    required this.mau,
    required this.nen,
    required this.tieuDe,
    required this.moTa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: nen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: mau, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                tieuDe,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                moTa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
