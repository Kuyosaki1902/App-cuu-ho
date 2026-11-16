import 'package:cloud_firestore/cloud_firestore.dart';

class DanhGiaModel {
  final String maDanhGia;
  final String maYeuCau;
  final String maNguoiDanhGia;
  final String maNguoiCuuHo;
  final int diemDanhGia;
  final String nhanXet;
  final DateTime ngayTao;

  DanhGiaModel({
    required this.maDanhGia,
    required this.maYeuCau,
    required this.maNguoiDanhGia,
    required this.maNguoiCuuHo,
    required this.diemDanhGia,
    required this.nhanXet,
    required this.ngayTao,
  });

  Map<String, dynamic> toMap() {
    return {
      'maDanhGia': maDanhGia,
      'maYeuCau': maYeuCau,
      'maNguoiDanhGia': maNguoiDanhGia,
      'maNguoiCuuHo': maNguoiCuuHo,
      'diemDanhGia': diemDanhGia,
      'nhanXet': nhanXet,
      'ngayTao': ngayTao,
    };
  }

  factory DanhGiaModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return DanhGiaModel(
      maDanhGia: map['maDanhGia'] ?? id ?? '',
      maYeuCau: map['maYeuCau'] ?? '',
      maNguoiDanhGia: map['maNguoiDanhGia'] ?? '',
      maNguoiCuuHo: map['maNguoiCuuHo'] ?? '',
      diemDanhGia: (map['diemDanhGia'] as num?)?.toInt() ?? 0,
      nhanXet: map['nhanXet'] ?? '',
      ngayTao: parseDateTime(map['ngayTao']),
    );
  }
}
