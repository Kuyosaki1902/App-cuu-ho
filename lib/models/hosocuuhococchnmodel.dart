// lib/models/ho_so_cuu_ho_co_cchn_model.dart

import 'package:cuhokhancap/models/basemodel.dart';

class HoSoCuuHoCoCCHNModel implements BaseModel {
  final String? maNguoiDung;
  final String soCanCuoc;
  final DateTime ngayCapCanCuoc;
  final DateTime ngayHetHanCanCuoc;
  final String coQuanCapCanCuoc;
  final String maCCHN;
  final DateTime ngayCapCCHN;
  final String coQuanCapCCHN;
  final String maTheChuyenNganh;
  final String chucDanh;
  final String donViCongTac;
  final double diemDanhGia;
  final int tongLuotDanhGia;
  final String maTrangThaiHoSo;

  HoSoCuuHoCoCCHNModel({
    this.maNguoiDung,
    required this.soCanCuoc,
    required this.ngayCapCanCuoc,
    required this.ngayHetHanCanCuoc,
    required this.coQuanCapCanCuoc,
    required this.maCCHN,
    required this.ngayCapCCHN,
    required this.coQuanCapCCHN,
    required this.maTheChuyenNganh,
    required this.chucDanh,
    required this.donViCongTac,
    this.diemDanhGia = 0.0,
    this.tongLuotDanhGia = 0,
    required this.maTrangThaiHoSo,
  });
  @override
  String? get id => maNguoiDung;
  // Chuyển sang Map để đẩy lên Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'soCanCuoc': soCanCuoc,
      'ngayCapCanCuoc': ngayCapCanCuoc,
      'ngayHetHanCanCuoc': ngayHetHanCanCuoc,
      'coQuanCapCanCuoc': coQuanCapCanCuoc,
      'maCCHN': maCCHN,
      'ngayCapCCHN': ngayCapCCHN,
      'coQuanCapCCHN': coQuanCapCCHN,
      'maTheChuyenNganh': maTheChuyenNganh,
      'chucDanh': chucDanh,
      'donViCongTac': donViCongTac,
      'diemDanhGia': diemDanhGia,
      'tongLuotDanhGia': tongLuotDanhGia,
      'maTrangThaiHoSo': maTrangThaiHoSo,
    };
  }

  // Đọc từ Firestore về Model
  factory HoSoCuuHoCoCCHNModel.fromMap(Map<String, dynamic> map, String id) {
    return HoSoCuuHoCoCCHNModel(
      maNguoiDung: map['maNguoiDung'] ?? id,
      soCanCuoc: map['soCanCuoc'] ?? '',
      ngayCapCanCuoc: map['ngayCapCanCuoc'] != null
          ? (map['ngayCapCanCuoc'] as dynamic).toDate()
          : DateTime.now(),
      ngayHetHanCanCuoc: map['ngayHetHanCanCuoc'] != null
          ? (map['ngayHetHanCanCuoc'] as dynamic).toDate()
          : DateTime.now(),
      coQuanCapCanCuoc: map['coQuanCapCanCuoc'] ?? '',
      maCCHN: map['maCCHN'] ?? '',
      ngayCapCCHN: map['ngayCapCCHN'] != null
          ? (map['ngayCapCCHN'] as dynamic).toDate()
          : DateTime.now(),
      coQuanCapCCHN: map['coQuanCapCCHN'] ?? '',
      maTheChuyenNganh: map['maTheChuyenNganh'] ?? '',
      chucDanh: map['chucDanh'] ?? '',
      donViCongTac: map['donViCongTac'] ?? '',
      diemDanhGia: (map['diemDanhGia'] ?? 0.0).toDouble(),
      tongLuotDanhGia: (map['tongLuotDanhGia'] ?? 0).toInt(),
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? '',
    );
  }
}
