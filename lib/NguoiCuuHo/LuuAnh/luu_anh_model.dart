class LuuAnhModel {
  final String maAnh;
  final String? anhURL; // Lưu chuỗi Base64 của ảnh tại đây
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

  Map<String, dynamic> toMap() {
    return {
      'maAnh': maAnh,
      'anhURL': anhURL,
      'maNguoiDung': maNguoiDung,
      'maPhanLoaiAnh': maPhanLoaiAnh,
      'maMoTa': maMoTa,
    };
  }

  factory LuuAnhModel.fromMap(Map<String, dynamic> map) {
    return LuuAnhModel(
      maAnh: map['maAnh'] ?? '',
      anhURL: map['anhURL'],
      maNguoiDung: map['maNguoiDung'] ?? '',
      maPhanLoaiAnh: map['maPhanLoaiAnh'] ?? '',
      maMoTa: map['maMoTa'],
    );
  }
}
