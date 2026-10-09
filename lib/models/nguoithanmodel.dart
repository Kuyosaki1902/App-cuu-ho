import 'package:cuhokhancap/models/basemodel.dart';

class NguoiThan implements BaseModel {
  final String maNguoiDung;
  final String maNguoiThan;
  final String? moiQuanHe;

  NguoiThan({
    required this.maNguoiDung,
    required this.maNguoiThan,
    this.moiQuanHe,
  });

  // Chuyển từ Map / JSON sang Model
  factory NguoiThan.fromMap(Map<String, dynamic> map) {
    return NguoiThan(
      maNguoiDung: map['maNguoiDung'] as String? ?? '',
      maNguoiThan: map['maNguoiThan'] as String? ?? '',
      moiQuanHe: map['moiQuanHe'] as String?,
    );
  }
  @override
  String? get id => maNguoiDung;
  // Chuyển từ Model sang Map / JSON để lưu Database
  @override
  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'maNguoiThan': maNguoiThan,
      'moiQuanHe': moiQuanHe,
    };
  }

  // Phương thức copyWith để dễ dàng cập nhật dữ liệu
  NguoiThan copyWith({
    String? maNguoiDung,
    String? maNguoiThan,
    String? moiQuanHe,
  }) {
    return NguoiThan(
      maNguoiDung: maNguoiDung ?? this.maNguoiDung,
      maNguoiThan: maNguoiThan ?? this.maNguoiThan,
      moiQuanHe: moiQuanHe ?? this.moiQuanHe,
    );
  }
}
