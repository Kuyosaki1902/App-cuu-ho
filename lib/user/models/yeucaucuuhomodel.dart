import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

class YeuCauCuuHoModel implements BaseModel {
  final String maYeuCau;
  final DateTime thoiGianTao;
  final double viDo;
  final double kinhDo;
  final int mucDoKhanCap;
  final int? soNguoiCanCuuHo;
  final int soNguoiCuuHo;
  final String maNguoiYeuCau;
  final String? maAdminDieuPhoi;
  final DateTime? thoiGianPhanCong;
  final DateTime? thoiGianHoanThanh;
  final String maLoaiYeuCau;
  final String maTinhTrangYeuCau;

  // 🌟 Trường mới: Lưu danh sách cứu hộ viên đã quét/phân công kèm trạng thái
  // Ví dụ: {"nguoidung1": "chotiepnhan", "nguoidung2": "datuchoi", "nguoidung3": "tiepnhan"}
  final Map<String, String> danhSachPhanCongVien;

  YeuCauCuuHoModel({
    required this.maYeuCau,
    required this.thoiGianTao,
    required this.viDo,
    required this.kinhDo,
    required this.mucDoKhanCap,
    this.soNguoiCanCuuHo,
    this.soNguoiCuuHo = 0,
    required this.maNguoiYeuCau,
    this.maAdminDieuPhoi,
    this.thoiGianPhanCong,
    this.thoiGianHoanThanh,
    required this.maLoaiYeuCau,
    required this.maTinhTrangYeuCau,
    this.danhSachPhanCongVien = const {}, // Mặc định là map rỗng
  });

  @override
  String? get id => maYeuCau;

  @override
  Map<String, dynamic> toMap() {
    return {
      'maYeuCau': maYeuCau,
      'thoiGianTao': thoiGianTao,
      'viDo': viDo,
      'kinhDo': kinhDo,
      'mucDoKhanCap': mucDoKhanCap,
      'soNguoiCanCuuHo': soNguoiCanCuuHo,
      'soNguoiCuuHo': soNguoiCuuHo,
      'maNguoiYeuCau': maNguoiYeuCau,
      'maAdminDieuPhoi': maAdminDieuPhoi,
      'thoiGianPhanCong': thoiGianPhanCong,
      'thoiGianHoanThanh': thoiGianHoanThanh,
      'maLoaiYeuCau': maLoaiYeuCau,
      'maTinhTrangYeuCau': maTinhTrangYeuCau,
      'danhSachPhanCongVien':
          danhSachPhanCongVien, // 🌟 Lưu Map này lên Firestore
    };
  }

  factory YeuCauCuuHoModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    // Xử lý parse an toàn cho Map<String, String> từ Firestore
    Map<String, String> parseDanhSach(dynamic value) {
      if (value == null || value is! Map) return {};
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return YeuCauCuuHoModel(
      maYeuCau: map['maYeuCau'] ?? id ?? '',
      thoiGianTao: parseDateTime(map['thoiGianTao']) ?? DateTime.now(),
      viDo: (map['viDo'] as num?)?.toDouble() ?? 0.0,
      kinhDo: (map['kinhDo'] as num?)?.toDouble() ?? 0.0,
      mucDoKhanCap: (map['mucDoKhanCap'] as num?)?.toInt() ?? 1,
      soNguoiCanCuuHo: (map['soNguoiCanCuuHo'] as num?)?.toInt(),
      soNguoiCuuHo: (map['soNguoiCuuHo'] as num?)?.toInt() ?? 0,
      maNguoiYeuCau: map['maNguoiYeuCau'] ?? '',
      maAdminDieuPhoi: map['maAdminDieuPhoi'],
      thoiGianPhanCong: parseDateTime(map['thoiGianPhanCong']),
      thoiGianHoanThanh: parseDateTime(map['thoiGianHoanThanh']),
      maLoaiYeuCau: map['maLoaiYeuCau'] ?? '',
      maTinhTrangYeuCau: map['maTinhTrangYeuCau'] ?? '',
      danhSachPhanCongVien: parseDanhSach(
        map['danhSachPhanCongVien'],
      ), // 🌟 Đọc từ Firestore
    );
  }
}
