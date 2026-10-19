import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

class ChiTietPhanCongCuuHoModel implements BaseModel {
  final String maPhanCong;
  final String maYeuCau;
  final String? loaiPhanCong;
  final String maNguoiCuuHo;
  final DateTime? thoiGianGui;
  final DateTime? thoiGianPhanHoi;
  final String maLoaiPhanCong;
  final String maTrangThaiTiepNhan;

  ChiTietPhanCongCuuHoModel({
    required this.maPhanCong,
    required this.maYeuCau,
    this.loaiPhanCong,
    required this.maNguoiCuuHo,
    this.thoiGianGui,
    this.thoiGianPhanHoi,
    required this.maLoaiPhanCong,
    required this.maTrangThaiTiepNhan,
  });

  @override
  String? get id => maPhanCong;
  @override
  Map<String, dynamic> toMap() {
    return {
      'maPhanCong': maPhanCong,
      'maYeuCau': maYeuCau,
      'loaiPhanCong': loaiPhanCong,
      'maNguoiCuuHo': maNguoiCuuHo,
      'thoiGianGui': thoiGianGui,
      'thoiGianPhanHoi': thoiGianPhanHoi,
      'maLoaiPhanCong': maLoaiPhanCong,
      'maTrangThaiTiepNhan': maTrangThaiTiepNhan,
    };
  }

  factory ChiTietPhanCongCuuHoModel.fromMap(
    Map<String, dynamic> map, [
    String? id,
  ]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return ChiTietPhanCongCuuHoModel(
      maPhanCong: map['maPhanCong'] ?? id ?? '',
      maYeuCau: map['maYeuCau'] ?? '',
      loaiPhanCong: map['loaiPhanCong'],
      maNguoiCuuHo: map['maNguoiCuuHo'] ?? '',
      thoiGianGui: parseDateTime(map['thoiGianGui']),
      thoiGianPhanHoi: parseDateTime(map['thoiGianPhanHoi']),
      maLoaiPhanCong: map['maLoaiPhanCong'] ?? '',
      maTrangThaiTiepNhan: map['maTrangThaiTiepNhan'] ?? '',
    );
  }
}
