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
      'soNguoiCuuHo': soNguoiCuuHo, // 🌟 Lưu vào Firestore
      'maNguoiYeuCau': maNguoiYeuCau,
      'maAdminDieuPhoi': maAdminDieuPhoi,
      'thoiGianPhanCong': thoiGianPhanCong,
      'thoiGianHoanThanh': thoiGianHoanThanh,
      'maLoaiYeuCau': maLoaiYeuCau,
      'maTinhTrangYeuCau': maTinhTrangYeuCau,
    };
  }

  factory YeuCauCuuHoModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return YeuCauCuuHoModel(
      maYeuCau: map['maYeuCau'] ?? id ?? '',
      thoiGianTao: parseDateTime(map['thoiGianTao']) ?? DateTime.now(),
      viDo: (map['viDo'] as num?)?.toDouble() ?? 0.0,
      kinhDo: (map['kinhDo'] as num?)?.toDouble() ?? 0.0,
      mucDoKhanCap: (map['mucDoKhanCap'] as num?)?.toInt() ?? 1,
      soNguoiCanCuuHo: (map['soNguoiCanCuuHo'] as num?)?.toInt(),
      soNguoiCuuHo:
          (map['soNguoiCuuHo'] as num?)?.toInt() ??
          0, // 🌟 Đọc từ Firestore (mặc định 0)
      maNguoiYeuCau: map['maNguoiYeuCau'] ?? '',
      maAdminDieuPhoi: map['maAdminDieuPhoi'],
      thoiGianPhanCong: parseDateTime(map['thoiGianPhanCong']),
      thoiGianHoanThanh: parseDateTime(map['thoiGianHoanThanh']),
      maLoaiYeuCau: map['maLoaiYeuCau'] ?? '',
      maTinhTrangYeuCau: map['maTinhTrangYeuCau'] ?? '',
    );
  }
}
