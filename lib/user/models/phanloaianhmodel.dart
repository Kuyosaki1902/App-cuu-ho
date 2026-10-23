import 'package:cuhokhancap/user/models/basemodel.dart';

class PhanLoaiAnhModel implements BaseModel {
  final String maPhanLoaiAnh;
  final String? tenLoai;

  PhanLoaiAnhModel({required this.maPhanLoaiAnh, this.tenLoai});

  @override
  String? get id => maPhanLoaiAnh;

  @override
  Map<String, dynamic> toMap() {
    return {'maPhanLoaiAnh': maPhanLoaiAnh, 'tenLoai': tenLoai};
  }

  factory PhanLoaiAnhModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return PhanLoaiAnhModel(
      maPhanLoaiAnh: map['maPhanLoaiAnh'] ?? id ?? '',
      tenLoai: map['tenLoai'],
    );
  }
}
