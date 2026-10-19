// lib/models/ho_so_cuu_ho_khong_cchn_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

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

  // 🌟 Các trường mới bổ sung theo CSDL sơ đồ
  final DateTime? thoiGianOnline;
  final int soLuongCaDuocPhat;
  final int soLuongCaDaNhan;
  final int soLuongDaKhongNhan;

  // 🌟 Dạng dynamic lưu số lượng ca hoàn thành (VD: {'tuan': 8, 'thang': 30, 'tatCa': 65})
  final Map<String, dynamic> soLuongCaHoanThanh;

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
    this.thoiGianOnline,
    this.soLuongCaDuocPhat = 0,
    this.soLuongCaDaNhan = 0,
    this.soLuongDaKhongNhan = 0,
    Map<String, dynamic>? soLuongCaHoanThanh,
  }) : soLuongCaHoanThanh =
           soLuongCaHoanThanh ?? {'tuan': 0, 'thang': 0, 'tatCa': 0};

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
      'thoiGianOnline': thoiGianOnline,
      'soLuongCaDuocPhat': soLuongCaDuocPhat,
      'soLuongCaDaNhan': soLuongCaDaNhan,
      'soLuongDaKhongNhan': soLuongDaKhongNhan,
      'soLuongCaHoanThanh': soLuongCaHoanThanh,
    };
  }

  // Đọc từ Firestore về Model
  factory HoSoCuuHoKhongCCHNModel.fromMap(
    Map<String, dynamic> map, [
    String? id,
  ]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return HoSoCuuHoKhongCCHNModel(
      maNguoiDung: map['maNguoiDung'] ?? id,
      soCanCuoc: map['soCanCuoc'] ?? '',
      ngayCapCanCuoc: parseDateTime(map['ngayCapCanCuoc']) ?? DateTime.now(),
      ngayHetHanCanCuoc:
          parseDateTime(map['ngayHetHanCanCuoc']) ?? DateTime.now(),
      coQuanCapCanCuoc: map['coQuanCapCanCuoc'] ?? '',
      doiNhom: map['doiNhom'],
      soNamHoatDongCuuHo: (map['soNamHoatDongCuuHo'] ?? 0).toInt(),
      soLanThamGiaCuuHo: (map['soLanThamGiaCuuHo'] ?? 0).toInt(),
      diemDanhGia: (map['diemDanhGia'] ?? 0.0).toDouble(),
      tongLuotDanhGia: (map['tongLuotDanhGia'] ?? 0).toInt(),
      ghiChu: map['ghiChu'],
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? '',
      thoiGianOnline: parseDateTime(map['thoiGianOnline']),
      soLuongCaDuocPhat: (map['soLuongCaDuocPhat'] ?? 0).toInt(),
      soLuongCaDaNhan: (map['soLuongCaDaNhan'] ?? 0).toInt(),
      soLuongDaKhongNhan: (map['soLuongDaKhongNhan'] ?? 0).toInt(),
      soLuongCaHoanThanh: map['soLuongCaHoanThanh'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['soLuongCaHoanThanh'])
          : {
              'tuan': 0,
              'thang': 0,
              'tatCa': (map['soLuongCaHoanThanh'] ?? 0).toInt(),
            },
    );
  }
}
