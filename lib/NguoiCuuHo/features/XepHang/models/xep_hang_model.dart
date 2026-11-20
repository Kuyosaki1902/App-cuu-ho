import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/quy_tac_diem.dart';

enum KyXepHang { tuan, thang, tatCa }

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

  /// [theoKy] = true (tuần/tháng): điểm = số ca × điểm mỗi ca.
  /// false (tất cả): đọc tổng điểm đã tính sẵn ở `ThanhTichCuuHo`.
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
      diem: theoKy
          ? ca * QuyTacDiem.diemMoiCa
          : (int.tryParse('${m['diem'] ?? 0}') ?? 0),
    );
  }
}
