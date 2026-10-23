import 'package:cuhokhancap/user/models/basemodel.dart';

class LuuAnhModel implements BaseModel {
  final String maAnh;
  final String? anhURL;
  final String maNguoiDung;
  final String maPhanLoaiAnh;
  final String? maMoTa;

  LuuAnhModel({
    required this.maAnh,
    this.anhURL,
    required this.maNguoiDung,
    required this.maPhanLoaiAnh,
    this.maMoTa,
  });

  @override
  String? get id => maAnh;

  @override
  Map<String, dynamic> toMap() {
    return {
      'maAnh': maAnh,
      'anhURL': anhURL,
      'maNguoiDung': maNguoiDung,
      'maPhanLoaiAnh': maPhanLoaiAnh,
      'maMoTa': maMoTa,
    };
  }

  factory LuuAnhModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LuuAnhModel(
      maAnh: map['maAnh'] ?? id ?? '',
      anhURL: map['anhURL'],
      maNguoiDung: map['maNguoiDung'] ?? '',
      maPhanLoaiAnh: map['maPhanLoaiAnh'] ?? '',
      maMoTa: map['maMoTa'],
    );
  }
}
