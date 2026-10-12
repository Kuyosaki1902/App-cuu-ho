import 'package:cuhokhancap/models/basemodel.dart';

class NguoiThanModel implements BaseModel {
  final String maNguoiDung;
  final String maNguoiThan;
  final String? moiQuanHe;
  final String trangThai;

  NguoiThanModel({
    required this.maNguoiDung,
    required this.maNguoiThan,
    this.moiQuanHe,
    required this.trangThai,
  });

  // Chuyển từ Map / JSON sang Model
  factory NguoiThanModel.fromMap(Map<String, dynamic> map) {
    return NguoiThanModel(
      maNguoiDung: map['maNguoiDung'] as String? ?? '',
      maNguoiThan: map['maNguoiThan'] as String? ?? '',
      moiQuanHe: map['moiQuanHe'] as String?,
      trangThai: map['trangThai'],
    );
  }
  @override
  String? get id => maNguoiThan;
  // Chuyển từ Model sang Map / JSON để lưu Database
  @override
  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'maNguoiThan': maNguoiThan,
      'moiQuanHe': moiQuanHe,
      'trangThai': trangThai,
    };
  }
}
