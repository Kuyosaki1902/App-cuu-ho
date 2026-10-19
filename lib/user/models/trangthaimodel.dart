// lib/models/trangthaimodel.dart

import 'package:cuhokhancap/user/models/basemodel.dart';

class TrangThaiModel implements BaseModel {
  final String? maTrangThai;
  final String trangThai;

  TrangThaiModel({required this.maTrangThai, required this.trangThai});

  @override
  String? get id => maTrangThai;

  // Chuyển từ Map / JSON sang Model
  factory TrangThaiModel.fromMap(Map<String, dynamic> map) {
    return TrangThaiModel(
      maTrangThai: map['maTrangThai'] as String?,
      trangThai: map['trangThai'] as String? ?? '',
    );
  }

  // Chuyển từ Model sang Map / JSON để lưu Database
  @override
  Map<String, dynamic> toMap() {
    return {'maTrangThai': maTrangThai, 'trangThai': trangThai};
  }
}
