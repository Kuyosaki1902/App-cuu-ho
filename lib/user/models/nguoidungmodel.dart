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
  });
  @override
  String? get id => maNguoiDung;
  // Chuyển đối tượng Model thành Map để đẩy lên Firestore
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
    };
  }

  // Tùy chọn: Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory NguoiDungModel.fromMap(Map<String, dynamic> map) {
    return NguoiDungModel(
      maNguoiDung: map['maNguoiDung'],
      hoTen: map['hoTen'] ?? '',
      email: map['email'] ?? '',
      diaChi: map['diaChi'] ?? '',
      queQuan: map['queQuan'] ?? '',
      soDienThoai: map['soDienThoai'] ?? "",
      maGioiTinh: map['maGioiTinh'] ?? '',
      maVaiTro: map['maVaiTro'] ?? '',
      ngaySinh: map['ngaySinh'] != null
          ? (map['ngaySinh'] as dynamic).toDate()
          : DateTime.now(),
      ngayTao: map['ngayTao'] != null
          ? (map['ngayTao'] as dynamic).toDate()
          : DateTime.now(),
      matKhau: map['matKhau'] ?? '',
    );
  }
}
