import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

class NguoiThanModel implements BaseModel {
  final String maNguoiDung;
  final String maNguoiThan;
  final String? moiQuanHe;
  final String trangThai;
  final DateTime ngayTao; // Thêm ngày tạo

  NguoiThanModel({
    required this.maNguoiDung,
    required this.maNguoiThan,
    this.moiQuanHe,
    required this.trangThai,
    required this.ngayTao,
  });

  // Chuyển từ Map / JSON sang Model
  factory NguoiThanModel.fromMap(Map<String, dynamic> map) {
    return NguoiThanModel(
      maNguoiDung: map['maNguoiDung'] as String? ?? '',
      maNguoiThan: map['maNguoiThan'] as String? ?? '',
      moiQuanHe: map['moiQuanHe'] as String?,
      trangThai: map['trangThai'] as String? ?? '',
      ngayTao: map['ngayTao'] is Timestamp
          ? (map['ngayTao'] as Timestamp).toDate()
          : (DateTime.tryParse(map['ngayTao']?.toString() ?? '') ??
                DateTime.now()),
    );
  }

  String get customPath => 'NguoiThan/$maNguoiDung/DanhSachNguoiThan';

  @override
  String? get id => maNguoiThan;

  // Chuyển từ Model sang Map / JSON để lưu Database
  @override
  Map<String, dynamic> toMap() {
    return {
      'moiQuanHe': moiQuanHe,
      'trangThai': trangThai,
      'ngayTao':
          ngayTao, // Đẩy lên Firestore (Firestore tự ép kiểu sang Timestamp)
    };
  }
}
