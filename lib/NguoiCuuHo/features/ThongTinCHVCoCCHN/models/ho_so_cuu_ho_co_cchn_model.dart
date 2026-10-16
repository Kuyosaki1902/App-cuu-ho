class HoSoCuuHoCoCCHNModel {
  final String maNguoiDung;
  final String soCanCuoc;
  final String ngayCapCanCuoc;
  final String ngayHetHanCanCuoc;
  final String coQuanCapCanCuoc;
  final String maCCHN;
  final String ngayCapCCHN;
  final String coQuanCapCCHN;
  final String maTheChuyenNganh;
  final String chucDanh;
  final String tenChuyenNganh;
  final String donViCongTac;
  final double diemDanhGia;
  final String thoiGianOnline;
  final int soLuongCaDuocPhat;
  final int soluongCaDaNhan;
  final int soLuongDaKhongNhan;
  final int soLuongCaHoanThanh;
  final int tongLuotDanhGia;
  final String maTrangThaiHoSo;

  HoSoCuuHoCoCCHNModel({
    required this.maNguoiDung,
    required this.soCanCuoc,
    required this.ngayCapCanCuoc,
    required this.ngayHetHanCanCuoc,
    required this.coQuanCapCanCuoc,
    required this.maCCHN,
    required this.ngayCapCCHN,
    required this.coQuanCapCCHN,
    required this.maTheChuyenNganh,
    required this.chucDanh,
    required this.tenChuyenNganh,
    required this.donViCongTac,
    this.diemDanhGia = 0.0,
    required this.thoiGianOnline,
    this.soLuongCaDuocPhat = 0,
    this.soluongCaDaNhan = 0,
    this.soLuongDaKhongNhan = 0,
    this.soLuongCaHoanThanh = 0,
    this.tongLuotDanhGia = 0,
    this.maTrangThaiHoSo = 'CHO_DUYET',
  });

  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'soCanCuoc': soCanCuoc,
      'ngayCapCanCuoc': ngayCapCanCuoc,
      'ngayHetHanCanCuoc': ngayHetHanCanCuoc,
      'coQuanCapCanCuoc': coQuanCapCanCuoc,
      'maCCHN': maCCHN,
      'ngayCapCCHN': ngayCapCCHN,
      'coQuanCapCCHN': coQuanCapCCHN,
      'maTheChuyenNganh': maTheChuyenNganh,
      'chucDanh': chucDanh,
      'tenChuyenNganh': tenChuyenNganh,
      'donViCongTac': donViCongTac,
      'diemDanhGia': diemDanhGia,
      'thoiGianOnline': thoiGianOnline,
      'soLuongCaDuocPhat': soLuongCaDuocPhat,
      'soluongCaDaNhan': soluongCaDaNhan,
      'soLuongDaKhongNhan': soLuongDaKhongNhan,
      'soLuongCaHoanThanh': soLuongCaHoanThanh,
      'tongLuotDanhGia': tongLuotDanhGia,
      'maTrangThaiHoSo': maTrangThaiHoSo,
    };
  }

  factory HoSoCuuHoCoCCHNModel.fromMap(Map<String, dynamic> map) {
    return HoSoCuuHoCoCCHNModel(
      maNguoiDung: map['maNguoiDung'] ?? '',
      soCanCuoc: map['soCanCuoc'] ?? '',
      ngayCapCanCuoc: map['ngayCapCanCuoc'] ?? '',
      ngayHetHanCanCuoc: map['ngayHetHanCanCuoc'] ?? '',
      coQuanCapCanCuoc: map['coQuanCapCanCuoc'] ?? '',
      maCCHN: map['maCCHN'] ?? '',
      ngayCapCCHN: map['ngayCapCCHN'] ?? '',
      coQuanCapCCHN: map['coQuanCapCCHN'] ?? '',
      maTheChuyenNganh: map['maTheChuyenNganh'] ?? '',
      chucDanh: map['chucDanh'] ?? '',
      tenChuyenNganh: map['tenChuyenNganh'] ?? '',
      donViCongTac: map['donViCongTac'] ?? '',
      diemDanhGia: (map['diemDanhGia'] ?? 0).toDouble(),
      thoiGianOnline: map['thoiGianOnline'] ?? '',
      soLuongCaDuocPhat: map['soLuongCaDuocPhat'] ?? 0,
      soluongCaDaNhan: map['soluongCaDaNhan'] ?? 0,
      soLuongDaKhongNhan: map['soLuongDaKhongNhan'] ?? 0,
      soLuongCaHoanThanh: map['soLuongCaHoanThanh'] ?? 0,
      tongLuotDanhGia: map['tongLuotDanhGia'] ?? 0,
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? 'CHO_DUYET',
    );
  }
}
