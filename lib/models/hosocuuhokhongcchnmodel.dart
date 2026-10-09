// lib/models/ho_so_cuu_ho_khong_cchn_model.dart

import 'package:cuhokhancap/models/basemodel.dart';

class HoSoCuuHoKhongCCHNModel implements BaseModel {
  final String? maNguoiDung;
  final String soCanCuoc;
  final DateTime ngayCapCanCuoc;
  final DateTime ngayHetHanCanCuoc;
  final String coQuanCapCanCuoc;
  final String? doiNhom;
  final int soNamHoatDongCuuHo;
  final int soLanThamGiaCuuHo;
  final double diemDanhGia;
  final int tongLuotDanhGia;
  final String? ghiChu;
  final String maTrangThaiHoSo;

  HoSoCuuHoKhongCCHNModel({
    this.maNguoiDung,
    required this.soCanCuoc,
    required this.ngayCapCanCuoc,
    required this.ngayHetHanCanCuoc,
    required this.coQuanCapCanCuoc,
    this.doiNhom,
    this.soNamHoatDongCuuHo = 0,
    this.soLanThamGiaCuuHo = 0,
    this.diemDanhGia = 0.0,
    this.tongLuotDanhGia = 0,
    this.ghiChu,
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
      'doiNhom': doiNhom,
      'soNamHoatDongCuuHo': soNamHoatDongCuuHo,
      'soLanThamGiaCuuHo': soLanThamGiaCuuHo,
      'diemDanhGia': diemDanhGia,
      'tongLuotDanhGia': tongLuotDanhGia,
      'ghiChu': ghiChu,
      'maTrangThaiHoSo': maTrangThaiHoSo,
    };
  }

  // Đọc từ Firestore về Model
  factory HoSoCuuHoKhongCCHNModel.fromMap(Map<String, dynamic> map, String id) {
    return HoSoCuuHoKhongCCHNModel(
      maNguoiDung: map['maNguoiDung'] ?? id,
      soCanCuoc: map['soCanCuoc'] ?? '',
      ngayCapCanCuoc: map['ngayCapCanCuoc'] != null
          ? (map['ngayCapCanCuoc'] as dynamic).toDate()
          : DateTime.now(),
      ngayHetHanCanCuoc: map['ngayHetHanCanCuoc'] != null
          ? (map['ngayHetHanCanCuoc'] as dynamic).toDate()
          : DateTime.now(),
      coQuanCapCanCuoc: map['coQuanCapCanCuoc'] ?? '',
      doiNhom: map['doiNhom'],
      soNamHoatDongCuuHo: (map['soNamHoatDongCuuHo'] ?? 0).toInt(),
      soLanThamGiaCuuHo: (map['soLanThamGiaCuuHo'] ?? 0).toInt(),
      diemDanhGia: (map['diemDanhGia'] ?? 0.0).toDouble(),
      tongLuotDanhGia: (map['tongLuotDanhGia'] ?? 0).toInt(),
      ghiChu: map['ghiChu'],
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? '',
    );
  }
}
