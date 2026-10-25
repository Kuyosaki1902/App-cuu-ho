// lib/user/models/chitietkinangmodel.dart

import 'package:cuhokhancap/user/models/basemodel.dart';

class ChiTietKyNangItemModel {
  final String maKyNangCuuHo;
  final DateTime? ngayCapNhat;

  ChiTietKyNangItemModel({required this.maKyNangCuuHo, this.ngayCapNhat});

  factory ChiTietKyNangItemModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return ChiTietKyNangItemModel(
      maKyNangCuuHo:
          (map['maKyNangCuuHo'] != null &&
              map['maKyNangCuuHo'].toString().isNotEmpty)
          ? map['maKyNangCuuHo'].toString()
          : docId,
      ngayCapNhat: map['ngayCapNhat'] != null
          ? (map['ngayCapNhat'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'maKyNangCuuHo': maKyNangCuuHo, 'ngayCapNhat': ngayCapNhat};
  }
}

class ChiTietKyNangModel implements BaseModel {
  final String maNguoiDung;
  final List<ChiTietKyNangItemModel> danhSachKiNang;

  ChiTietKyNangModel({
    required this.maNguoiDung,
    this.danhSachKiNang = const [],
  });
  @override
  String? get id => maNguoiDung;

  factory ChiTietKyNangModel.fromMap(
    Map<String, dynamic> map,
    String docId, {
    List<ChiTietKyNangItemModel> danhSachKiNang = const [],
  }) {
    return ChiTietKyNangModel(
      maNguoiDung:
          (map['maNguoiDung'] != null &&
              map['maNguoiDung'].toString().isNotEmpty)
          ? map['maNguoiDung'].toString()
          : docId,
      danhSachKiNang: danhSachKiNang,
    );
  }
  @override
  Map<String, dynamic> toMap() {
    return {'maNguoiDung': maNguoiDung};
  }
}
