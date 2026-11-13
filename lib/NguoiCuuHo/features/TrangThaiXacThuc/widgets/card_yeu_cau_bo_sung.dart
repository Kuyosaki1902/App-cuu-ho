import 'package:flutter/material.dart';

import '../models/trang_thai_ho_so.dart';

/// Hiển thị lý do người duyệt ghi (bổ sung / từ chối / tạm khóa) và nút hành động.
class CardYeuCauBoSung extends StatelessWidget {
  final TrangThaiHoSo trangThai;
  final String tieuDe;
  final String? lyDo;
  final String loiMacDinh;
  final String? nutText;
  final VoidCallback? onPressed;

  const CardYeuCauBoSung({
    super.key,
    required this.trangThai,
    required this.tieuDe,
    required this.lyDo,
    this.loiMacDinh =
        'Người duyệt chưa ghi lý do cụ thể. Vui lòng liên hệ Ban điều phối 115 để được hướng dẫn.',
    this.nutText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final mau = trangThai.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trangThai.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mau.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tieuDe,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mau),
          ),
          const SizedBox(height: 6),
          Text(
            (lyDo == null || lyDo!.isEmpty) ? loiMacDinh : lyDo!,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
          if (nutText != null && onPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.edit_document, size: 18, color: Colors.white),
                label: Text(
                  nutText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mau,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
