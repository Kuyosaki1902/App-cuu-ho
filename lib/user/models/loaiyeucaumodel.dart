import 'package:cuhokhancap/user/models/basemodel.dart';

class LoaiYeuCauModel implements BaseModel {
  final String maLoaiYeuCau;
  final String tenLoaiYeuCau;

  LoaiYeuCauModel({required this.maLoaiYeuCau, required this.tenLoaiYeuCau});
  @override
  String? get id => maLoaiYeuCau;
  @override
  Map<String, dynamic> toMap() {
    return {'maLoaiYeuCau': maLoaiYeuCau, 'tenLoaiYeuCau': tenLoaiYeuCau};
  }

  factory LoaiYeuCauModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LoaiYeuCauModel(
      maLoaiYeuCau: map['maLoaiYeuCau'] ?? id ?? '',
      tenLoaiYeuCau: map['tenLoaiYeuCau'] ?? '',
    );
  }
}
