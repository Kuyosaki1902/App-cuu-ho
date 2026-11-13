import 'package:flutter/material.dart';

enum KyXepHang { tuan, thang, tatCa }

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

class XepHangItem {
  final String maNguoiDung, tenHienThi, loaiHoSo;
  final int soCaHoanThanh, diem;
  int hang;

  XepHangItem({
    required this.maNguoiDung,
    required this.tenHienThi,
    required this.loaiHoSo,
    required this.soCaHoanThanh,
    required this.diem,
    this.hang = 0,
  });

  CapBac get capBac => CapBac.tuDiem(diem);

  factory XepHangItem.fromMap(
    Map<String, dynamic> m,
    String id, {
    required bool theoKy,
  }) {
    final ca = int.tryParse('${m['soCaHoanThanh'] ?? 0}') ?? 0;
    return XepHangItem(
      maNguoiDung: (m['maNguoiDung'] ?? id).toString(),
      tenHienThi: (m['tenHienThi'] ?? 'Cứu hộ viên').toString(),
      loaiHoSo: (m['loaiHoSo'] ?? 'khongcchn').toString(),
      soCaHoanThanh: ca,
      diem: theoKy ? ca * 10 : (int.tryParse('${m['diem'] ?? 0}') ?? 0),
    );
  }
}
