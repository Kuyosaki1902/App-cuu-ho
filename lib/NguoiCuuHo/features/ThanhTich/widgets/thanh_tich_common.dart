import 'package:flutter/material.dart';

const kDo = Color(0xFFDC2626);
const kXam = Color(0xFF64748B);
const kXamNhat = Color(0xFF94A3B8);
const kDen = Color(0xFF0F172A);
const kVien = Color(0xFFE2E8F0);

String chuCai(String ten) => ten.trim().isEmpty ? '?' : ten.trim().substring(0, 1).toUpperCase();

class NhanLoai extends StatelessWidget {
  final String loai;
  final bool tren; 
  const NhanLoai({super.key, required this.loai, this.tren = false});

  @override
  Widget build(BuildContext context) {
    final coCCHN = loai == 'cchn';
    final mau = coCCHN ? const Color(0xFF0D9488) : const Color(0xFFEA580C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tren ? Colors.white : mau.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        coCCHN ? 'Y tế (CCHN)' : 'Tình nguyện',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: mau,
        ),
      ),
    );
  }
}

class TrangThaiRong extends StatelessWidget {
  final IconData icon;
  final String tieuDe;
  final String? moTa;
  final String? nutText;
  final VoidCallback? onNut;
  const TrangThaiRong({
    super.key,
    required this.icon,
    required this.tieuDe,
    this.moTa,
    this.nutText,
    this.onNut,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: kXamNhat),
            const SizedBox(height: 12),
            Text(
              tieuDe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kDen,
              ),
            ),
            if (moTa != null) ...[
              const SizedBox(height: 6),
              Text(
                moTa!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: kXam,
                ),
              ),
            ],
            if (nutText != null && onNut != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onNut, child: Text(nutText!)),
            ],
          ],
        ),
      ),
    );
  }
}
