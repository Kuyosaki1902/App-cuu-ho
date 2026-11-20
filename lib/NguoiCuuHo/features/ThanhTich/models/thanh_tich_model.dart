import 'dart:math' as math;
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/quy_tac_diem.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThanhTichModel {
  final String maNguoiDung;
  final String tenHienThi;
  final String loaiHoSo;
  final int soCaHoanThanh;
  final int soCaDuocPhat;
  final int soCaDaNhan;
  final int soCaKhongNhan;
  final double saoTrungBinh;
  final int soLuotDanhGia;

  const ThanhTichModel({
    required this.maNguoiDung,
    required this.tenHienThi,
    required this.loaiHoSo,
    this.soCaHoanThanh = 0,
    this.soCaDuocPhat = 0,
    this.soCaDaNhan = 0,
    this.soCaKhongNhan = 0,
    this.saoTrungBinh = 0,
    this.soLuotDanhGia = 0,
  });

  static int _int(dynamic v) =>
      v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0.0);

  factory ThanhTichModel.tuHoSo(
    Map<String, dynamic> h, {
    required String maNguoiDung,
    required String tenHienThi,
    required String loaiHoSo,
    double? saoTrungBinh,
    int? soLuotDanhGia,
  }) {
    final hoanThanh = _int(h['soLuongCaHoanThanh']);
    final khongNhan = _int(h['soLuongCaKhongNhan']);
    final daNhan = math.max(_int(h['soLuongCaDaNhan']), hoanThanh);
    final duocPhat = math.max(_int(h['soLuongCaDuocPhat']), daNhan + khongNhan);

    return ThanhTichModel(
      maNguoiDung: maNguoiDung,
      tenHienThi: tenHienThi,
      loaiHoSo: loaiHoSo,
      soCaHoanThanh: hoanThanh,
      soCaDuocPhat: duocPhat,
      soCaDaNhan: daNhan,
      soCaKhongNhan: khongNhan,
      saoTrungBinh: saoTrungBinh ?? _double(h['diemDanhGia']),
      soLuotDanhGia: soLuotDanhGia ?? _int(h['tongLuotDanhGia']),
    );
  }

  double? get tyLeNhanCa =>
      soCaDuocPhat > 0 ? (soCaDaNhan / soCaDuocPhat).clamp(0.0, 1.0) : null;
  double? get tyLeHoanThanh =>
      soCaDaNhan > 0 ? (soCaHoanThanh / soCaDaNhan).clamp(0.0, 1.0) : null;

  int get diemCa => QuyTacDiem.diemMoiCa * soCaHoanThanh;

  int get diemChuyenCan {
    final t = tyLeNhanCa;
    if (t == null || soCaDuocPhat < QuyTacDiem.soCaToiThieuTinhChuyenCan)
      return 0;
    return (QuyTacDiem.diemChuyenCanToiDa * t).round();
  }

  int get diemChatLuong {
    if (soLuotDanhGia < QuyTacDiem.luotDanhGiaToiThieu) return 0;
    final v = (saoTrungBinh - QuyTacDiem.saoCoSo) * QuyTacDiem.heSoChatLuong;
    return v <= 0 ? 0 : v.round();
  }

  int get diemTru => math.min(
    QuyTacDiem.diemTruToiDa,
    QuyTacDiem.diemTruMoiCaBoLo * soCaKhongNhan,
  );
  int get diem => math.max(0, diemCa + diemChuyenCan + diemChatLuong - diemTru);

  CapBac get capBac => CapBac.tuDiem(diem);

  /// Chỉ các trường công khai ghi vào `ThanhTichCuuHo` (bảng xếp hạng đọc được).
  /// Số ca bỏ lỡ / được phân công / đánh giá là dữ liệu riêng, vẫn nằm ở hồ sơ cứu hộ.
  Map<String, dynamic> toBangXepHang() => {
    'maNguoiDung': maNguoiDung,
    'tenHienThi': tenHienThi,
    'loaiHoSo': loaiHoSo,
    'soCaHoanThanh': soCaHoanThanh,
    'soCaKhongNhan': soCaKhongNhan,
    'DanhGia': diemChatLuong,
    'diem': diem,
  };

  static Future<({double saoTrungBinh, int soLuotDanhGia})> layThongKeDanhGia(
    String maNguoiDung,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('DanhGia')
        .doc(maNguoiDung)
        .collection('DanhSachYeuCau')
        .get();

    if (snap.docs.isEmpty) {
      return (saoTrungBinh: 0.0, soLuotDanhGia: 0);
    }

    double tongSao = 0;
    int soLuot = 0;

    for (final doc in snap.docs) {
      final rawDiem = doc.data()['diemDanhGia'];
      if (rawDiem != null) {
        tongSao += _double(rawDiem);
        soLuot++;
      }
    }

    return (
      saoTrungBinh: soLuot > 0 ? tongSao / soLuot : 0.0,
      soLuotDanhGia: soLuot,
    );
  }
}

class HuyHieu {
  final String id, ten, moTa;
  final IconData icon;
  final Color mau;
  final bool Function(ThanhTichModel) daDat;
  final String Function(ThanhTichModel) tienDo;

  const HuyHieu({
    required this.id,
    required this.ten,
    required this.moTa,
    required this.icon,
    required this.mau,
    required this.daDat,
    required this.tienDo,
  });

  static String _caTheo(int hienTai, int mucTieu) =>
      '${math.min(hienTai, mucTieu)}/$mucTieu ca';
  static String _phanTram(double? v) =>
      v == null ? '--' : '${(v * 100).round()}%';

  static final List<HuyHieu> tatCa = [
    HuyHieu(
      id: 'ca_dau_tien',
      ten: 'Ca đầu tiên',
      moTa: 'Hoàn thành ca cứu hộ đầu tiên.',
      icon: Icons.flag_rounded,
      mau: const Color(0xFF0D9488),
      daDat: (t) => t.soCaHoanThanh >= 1,
      tienDo: (t) => _caTheo(t.soCaHoanThanh, 1),
    ),
    HuyHieu(
      id: 'ca_5',
      ten: '5 ca cứu hộ',
      moTa: 'Hoàn thành 5 ca cứu hộ.',
      icon: Icons.local_fire_department_rounded,
      mau: const Color(0xFFEA580C),
      daDat: (t) => t.soCaHoanThanh >= 5,
      tienDo: (t) => _caTheo(t.soCaHoanThanh, 5),
    ),
    HuyHieu(
      id: 'ca_10',
      ten: '10 ca cứu hộ',
      moTa: 'Hoàn thành 10 ca cứu hộ.',
      icon: Icons.military_tech_rounded,
      mau: const Color(0xFF2563EB),
      daDat: (t) => t.soCaHoanThanh >= 10,
      tienDo: (t) => _caTheo(t.soCaHoanThanh, 10),
    ),
    HuyHieu(
      id: 'ca_25',
      ten: '25 ca cứu hộ',
      moTa: 'Hoàn thành 25 ca cứu hộ.',
      icon: Icons.workspace_premium_rounded,
      mau: const Color(0xFF7C3AED),
      daDat: (t) => t.soCaHoanThanh >= 25,
      tienDo: (t) => _caTheo(t.soCaHoanThanh, 25),
    ),
    HuyHieu(
      id: 'phan_hoi_nhanh',
      ten: 'Phản hồi nhanh',
      moTa: 'Nhận từ 90% số ca được phân công (tối thiểu 5 ca được phân công).',
      icon: Icons.bolt_rounded,
      mau: const Color(0xFFCA8A04),
      daDat: (t) => t.soCaDuocPhat >= 5 && (t.tyLeNhanCa ?? 0) >= 0.9,
      tienDo: (t) => t.soCaDuocPhat < 5
          ? '${t.soCaDuocPhat}/5 ca được phân công'
          : 'Tỷ lệ nhận ${_phanTram(t.tyLeNhanCa)} / 90%',
    ),
    HuyHieu(
      id: 'khong_bo_lo',
      ten: 'Không bỏ lỡ',
      moTa: 'Không bỏ lỡ ca nào (tối thiểu 5 ca được phân công).',
      icon: Icons.shield_rounded,
      mau: const Color(0xFF059669),
      daDat: (t) => t.soCaDuocPhat >= 5 && t.soCaKhongNhan == 0,
      tienDo: (t) => t.soCaDuocPhat < 5
          ? '${t.soCaDuocPhat}/5 ca được phân công'
          : '${t.soCaKhongNhan} ca đã bỏ lỡ',
    ),
    HuyHieu(
      id: 'hoan_thanh_tot',
      ten: 'Hoàn thành tốt',
      moTa: 'Hoàn thành từ 90% số ca đã nhận (tối thiểu 5 ca đã nhận).',
      icon: Icons.task_alt_rounded,
      mau: const Color(0xFF0284C7),
      daDat: (t) => t.soCaDaNhan >= 5 && (t.tyLeHoanThanh ?? 0) >= 0.9,
      tienDo: (t) => t.soCaDaNhan < 5
          ? '${t.soCaDaNhan}/5 ca đã nhận'
          : 'Tỷ lệ hoàn thành ${_phanTram(t.tyLeHoanThanh)} / 90%',
    ),
    HuyHieu(
      id: 'duoc_tin_cay',
      ten: 'Được tin cậy',
      moTa: 'Điểm đánh giá từ 4,5 sao (tối thiểu 5 lượt đánh giá).',
      icon: Icons.verified_rounded,
      mau: const Color(0xFFDB2777),
      daDat: (t) => t.soLuotDanhGia >= 5 && t.saoTrungBinh >= 4.5,
      tienDo: (t) => t.soLuotDanhGia < 5
          ? '${t.soLuotDanhGia}/5 lượt đánh giá'
          : '${t.saoTrungBinh.toStringAsFixed(1)} / 4,5 sao',
    ),
  ];
}
