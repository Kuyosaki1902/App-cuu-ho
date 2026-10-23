// lib/user/models/nguoidungmodel.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

class NguoiDungModel implements BaseModel {
  final String? maNguoiDung;
  final String hoTen;
  final String email;
  final String diaChi;
  final String queQuan;
  final String matKhau;
  final String soDienThoai;
  final String maGioiTinh;
  final String maVaiTro;
  final DateTime ngaySinh;
  final DateTime ngayTao;

  // 🌟 Thuộc tính tọa độ GPS & Geohash
  final double? viDo;
  final double? kinhDo;
  final String? geohash;

  // 🌟 Bổ sung 2 thuộc tính mới theo sơ đồ ERD
  final bool nhanCaCuuHo;
  final bool isOnline;

  NguoiDungModel({
    this.maNguoiDung,
    required this.hoTen,
    required this.email,
    required this.diaChi,
    required this.queQuan,
    required this.soDienThoai,
    required this.maGioiTinh,
    required this.maVaiTro,
    required this.ngaySinh,
    required this.ngayTao,
    required this.matKhau,
    this.viDo,
    this.kinhDo,
    this.geohash,
    this.nhanCaCuuHo = false,
    this.isOnline = false,
  });

  @override
  String? get id => maNguoiDung;

  // Chuyển đối tượng Model thành Map để đẩy/cập nhật lên Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'hoTen': hoTen,
      'email': email,
      'diaChi': diaChi,
      'queQuan': queQuan,
      'soDienThoai': soDienThoai,
      'maGioiTinh': maGioiTinh,
      'maVaiTro': maVaiTro,
      'ngaySinh':
          ngaySinh, // Firestore sẽ tự động chuyển DateTime thành Timestamp
      'ngayTao': ngayTao,
      'matKhau': matKhau,
      'viDo': viDo,
      'kinhDo': kinhDo,
      'geohash': geohash,
      'nhanCaCuuHo': nhanCaCuuHo,
      'isOnline': isOnline,
    };
  }

  // Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory NguoiDungModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NguoiDungModel(
      maNguoiDung: map['maNguoiDung'] ?? id ?? '',
      hoTen: map['hoTen'] ?? '',
      email: map['email'] ?? '',
      diaChi: map['diaChi'] ?? '',
      queQuan: map['queQuan'] ?? '',
      soDienThoai: map['soDienThoai'] ?? '',
      maGioiTinh: map['maGioiTinh'] ?? '',
      maVaiTro: map['maVaiTro'] ?? '',
      ngaySinh: parseDateTime(map['ngaySinh']),
      ngayTao: parseDateTime(map['ngayTao']),
      matKhau: map['matKhau'] ?? '',
      viDo: (map['viDo'] as num?)?.toDouble(),
      kinhDo: (map['kinhDo'] as num?)?.toDouble(),
      geohash: map['geohash'],
      nhanCaCuuHo: map['nhanCaCuuHo'] ?? false,
      isOnline: map['isOnline'] ?? false,
    );
  }
}
