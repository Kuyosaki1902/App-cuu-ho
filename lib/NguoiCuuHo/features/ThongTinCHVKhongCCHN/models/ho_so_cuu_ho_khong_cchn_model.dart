class HoSoCuuHoKhongCCHNModel {
  final String maNguoiDung;
  final String soCanCuoc;
  final String ngayCapCanCuoc;
  final String ngayHetHanCanCuoc;
  final String coQuanCapCanCuoc;
  final String? doiNhom;
  final int soNamHoatDongCuuHo;
  final int soLanThamGiaCuuHo;
  final double diemDanhGia;
  final int tongLuotDanhGia;
  final String? ghiChu;
  final String thoiGianOnline;
  final int soLuongCaDuocPhat;
  final int soluongCaDaNhan;
  final int soLuongDaKhongNhan;
  final int soLuongCaHoanThanh;
  final String maTrangThaiHoSo;

  HoSoCuuHoKhongCCHNModel({
    required this.maNguoiDung,
    required this.soCanCuoc,
    required this.ngayCapCanCuoc,
    required this.ngayHetHanCanCuoc,
    required this.coQuanCapCanCuoc,
    this.doiNhom,
    this.soNamHoatDongCuuHo = 0,
    this.soLanThamGiaCuuHo = 0,
    this.diemDanhGia = 0.0,
    this.tongLuotDanhGia = 0,
    this.ghiChu,
    required this.thoiGianOnline,
    this.soLuongCaDuocPhat = 0,
    this.soluongCaDaNhan = 0,
    this.soLuongDaKhongNhan = 0,
    this.soLuongCaHoanThanh = 0,
    required this.maTrangThaiHoSo,
  });

  Map<String, dynamic> toMap() {
    return {
      'maNguoiDung': maNguoiDung,
      'soCanCuoc': soCanCuoc,
      'ngayCapCanCuoc': ngayCapCanCuoc,
      'ngayHetHanCanCuoc': ngayHetHanCanCuoc,
      'coQuanCapCanCuoc': coQuanCapCanCuoc,
      'doiNhom': doiNhom,
      'soNamHoatDongCuuHo': soNamHoatDongCuuHo,
      'soLanThamGiaCuuHo': soLanThamGiaCuuHo,
      'diemDanhGia': diemDanhGia,
      'tongLuotDanhGia': tongLuotDanhGia,
      'ghiChu': ghiChu,
      'thoiGianOnline': thoiGianOnline,
      'soLuongCaDuocPhat': soLuongCaDuocPhat,
      'soluongCaDaNhan': soluongCaDaNhan,
      'soLuongDaKhongNhan': soLuongDaKhongNhan,
      'soLuongCaHoanThanh': soLuongCaHoanThanh,
      'maTrangThaiHoSo': maTrangThaiHoSo,
    };
  }

  factory HoSoCuuHoKhongCCHNModel.fromMap(Map<String, dynamic> map) {
    return HoSoCuuHoKhongCCHNModel(
      maNguoiDung: map['maNguoiDung'] ?? '',
      soCanCuoc: map['soCanCuoc'] ?? '',
      ngayCapCanCuoc: map['ngayCapCanCuoc'] ?? '',
      ngayHetHanCanCuoc: map['ngayHetHanCanCuoc'] ?? '',
      coQuanCapCanCuoc: map['coQuanCapCanCuoc'] ?? '',
      doiNhom: map['doiNhom'],
      soNamHoatDongCuuHo: map['soNamHoatDongCuuHo'] ?? 0,
      soLanThamGiaCuuHo: map['soLanThamGiaCuuHo'] ?? 0,
      diemDanhGia: (map['diemDanhGia'] ?? 0.0).toDouble(),
      tongLuotDanhGia: map['tongLuotDanhGia'] ?? 0,
      ghiChu: map['ghiChu'],
      thoiGianOnline: map['thoiGianOnline'] ?? '',
      soLuongCaDuocPhat: map['soLuongCaDuocPhat'] ?? 0,
      soluongCaDaNhan: map['soluongCaDaNhan'] ?? 0,
      soLuongDaKhongNhan: map['soLuongDaKhongNhan'] ?? 0,
      soLuongCaHoanThanh: map['soLuongCaHoanThanh'] ?? 0,
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? 'cuuho_trangthai_tiepnhan',
    );
  }
}
