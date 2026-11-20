import 'package:flutter/material.dart';

/// Quy tắc tính điểm và cấp bậc, một nơi duy nhất.
/// Thành tích dùng để tính điểm, Xếp hạng chỉ đọc hằng số `diemMoiCa`;
/// văn bản giải thích cũng sinh từ các hằng số này nên không lệch với công thức.
class QuyTacDiem {
  QuyTacDiem._();

  static const int diemMoiCa = 10;

  static const int soCaToiThieuTinhChuyenCan = 5;
  static const int diemChuyenCanToiDa = 20;

  static const int luotDanhGiaToiThieu = 3;
  static const double saoCoSo = 3;
  static const double heSoChatLuong = 10;

  static const int diemTruMoiCaBoLo = 2;
  static const int diemTruToiDa = 20;
}

class CapBac {
  final String ten;
  final int diemToiThieu;
  final Color mau;
  final IconData icon;

  const CapBac(this.ten, this.diemToiThieu, this.mau, this.icon);

  static const List<CapBac> tatCa = [
    CapBac('Đồng', 0, Color(0xFF9A5B2E), Icons.military_tech_rounded),
    CapBac('Bạc', 50, Color(0xFF64748B), Icons.military_tech_rounded),
    CapBac('Vàng', 150, Color(0xFFCA8A04), Icons.workspace_premium_rounded),
    CapBac('Bạch kim', 400, Color(0xFF0D9488), Icons.workspace_premium_rounded),
    CapBac('Kim cương', 1000, Color(0xFF7C3AED), Icons.diamond_rounded),
  ];

  static CapBac tuDiem(int diem) {
    var kq = tatCa.first;
    for (final c in tatCa) {
      if (diem >= c.diemToiThieu) kq = c;
    }
    return kq;
  }

  CapBac? get capTiepTheo {
    final i = tatCa.indexOf(this);
    return (i >= 0 && i + 1 < tatCa.length) ? tatCa[i + 1] : null;
  }
}
