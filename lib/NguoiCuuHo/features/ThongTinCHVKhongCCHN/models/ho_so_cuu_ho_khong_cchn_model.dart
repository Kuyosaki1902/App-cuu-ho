/// Mã trạng thái hồ sơ, theo quy ước `cuuho_trangthai_hoso_*` của app.
/// Nguồn chính là enum `TrangThaiHoSo` ở TrangThaiXacThuc/models/trang_thai_ho_so.dart,
/// các hằng này phải trùng khớp với mã của enum đó.
const String kTrangThaiTiepNhan = 'cuuho_trangthai_hoso_tiepnhan';
const String kTrangThaiDangThamDinh = 'cuuho_trangthai_hoso_dangthamdinh';
const String kTrangThaiCanBoSung = 'cuuho_trangthai_hoso_canbosung';
const String kTrangThaiTuChoi = 'cuuho_trangthai_hoso_tuchoi';
const String kTrangThaiTamKhoa = 'cuuho_trangthai_hoso_tamkhoa';
const String kTrangThaiDaDuyet = 'cuuho_trangthai_hoso_daduyet';

/// Giờ nộp có thể là chuỗi ISO hoặc Timestamp của Firestore.
String _asIso(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  try {
    return (v as dynamic).toDate().toIso8601String() as String;
  } catch (_) {
    return '';
  }
}

class HoSoCuuHoKhongCCHNModel {
  // --- Do người dùng khai ---
  final String maNguoiDung;
  final String soCanCuoc;
  final String ngayCapCanCuoc;
  final String ngayHetHanCanCuoc;
  final String coQuanCapCanCuoc;
  final String? doiNhom;
  final int soNamHoatDongCuuHo;
  final int soLanThamGiaCuuHo;
  final String? tomTatCuuHo;
  final String? ghiChu;
  final String thoiGianOnline;
  /// Giờ nộp hồ sơ. Khi gửi, controller ghi đè bằng FieldValue.serverTimestamp()
  /// để đếm ngược thẩm định không phụ thuộc đồng hồ máy người dùng.
  final String thoiGianNop;

  // --- Đường dẫn ảnh trên Firebase Storage (không lưu Base64 trong Firestore) ---
  final String anhCccdTruocPath;
  final String anhCccdSauPath;
  final String anhSelfiePath;

  // --- Đồng ý xử lý dữ liệu cá nhân ---
  final bool daDongYXuLyDuLieu;
  final String thoiGianDongY;

  // --- Bài kiểm tra trong app (server nên chấm lại) ---
  final int diemBaiKiemTra;
  final int tongCauBaiKiemTra;

  // --- Chỉ SERVER / NGƯỜI DUYỆT được ghi (siết bằng Firestore Rules) ---
  final double diemDanhGia;
  final int tongLuotDanhGia;
  final int soLuongCaDuocPhat;
  final int soluongCaDaNhan;
  final int soLuongDaKhongNhan;
  final int soLuongCaHoanThanh;
  final int capDoUyTin; // 0 = chưa duyệt, 1..3 = cấp uy tín
  final List<String> kyNangDaXacMinh;
  final String maTrangThaiHoSo;
  final String? nguoiDuyet;
  final String? thoiGianDuyet;
  final String? lyDoTuChoi;
  final String? hanTaiXacMinh; // tái xác minh định kỳ (vd 12 tháng)

  HoSoCuuHoKhongCCHNModel({
    required this.maNguoiDung,
    required this.soCanCuoc,
    required this.ngayCapCanCuoc,
    required this.ngayHetHanCanCuoc,
    required this.coQuanCapCanCuoc,
    this.doiNhom,
    this.soNamHoatDongCuuHo = 0,
    this.soLanThamGiaCuuHo = 0,
    this.tomTatCuuHo,
    this.ghiChu,
    required this.thoiGianOnline,
    this.thoiGianNop = '',
    this.anhCccdTruocPath = '',
    this.anhCccdSauPath = '',
    this.anhSelfiePath = '',
    this.daDongYXuLyDuLieu = false,
    this.thoiGianDongY = '',
    this.diemBaiKiemTra = 0,
    this.tongCauBaiKiemTra = 0,
    this.diemDanhGia = 0.0,
    this.tongLuotDanhGia = 0,
    this.soLuongCaDuocPhat = 0,
    this.soluongCaDaNhan = 0,
    this.soLuongDaKhongNhan = 0,
    this.soLuongCaHoanThanh = 0,
    this.capDoUyTin = 0,
    this.kyNangDaXacMinh = const [],
    required this.maTrangThaiHoSo,
    this.nguoiDuyet,
    this.thoiGianDuyet,
    this.lyDoTuChoi,
    this.hanTaiXacMinh,
  });

  /// Khi tạo hồ sơ, các trường "server" phải ở giá trị khởi tạo này.
  /// Firestore Rules nên chỉ cho client `create` với đúng các giá trị mặc định đó.
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
      'tomTatCuuHo': tomTatCuuHo,
      'ghiChu': ghiChu,
      'thoiGianOnline': thoiGianOnline,
      'thoiGianNop': thoiGianNop,
      'anhCccdTruocPath': anhCccdTruocPath,
      'anhCccdSauPath': anhCccdSauPath,
      'anhSelfiePath': anhSelfiePath,
      'daDongYXuLyDuLieu': daDongYXuLyDuLieu,
      'thoiGianDongY': thoiGianDongY,
      'diemBaiKiemTra': diemBaiKiemTra,
      'tongCauBaiKiemTra': tongCauBaiKiemTra,
      'diemDanhGia': diemDanhGia,
      'tongLuotDanhGia': tongLuotDanhGia,
      'soLuongCaDuocPhat': soLuongCaDuocPhat,
      'soluongCaDaNhan': soluongCaDaNhan,
      'soLuongDaKhongNhan': soLuongDaKhongNhan,
      'soLuongCaHoanThanh': soLuongCaHoanThanh,
      'capDoUyTin': capDoUyTin,
      'kyNangDaXacMinh': kyNangDaXacMinh,
      'maTrangThaiHoSo': maTrangThaiHoSo,
      'nguoiDuyet': nguoiDuyet,
      'thoiGianDuyet': thoiGianDuyet,
      'lyDoTuChoi': lyDoTuChoi,
      'hanTaiXacMinh': hanTaiXacMinh,
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
      tomTatCuuHo: map['tomTatCuuHo'],
      ghiChu: map['ghiChu'],
      thoiGianOnline: map['thoiGianOnline'] ?? '',
      thoiGianNop: _asIso(map['thoiGianNop']),
      anhCccdTruocPath: map['anhCccdTruocPath'] ?? '',
      anhCccdSauPath: map['anhCccdSauPath'] ?? '',
      anhSelfiePath: map['anhSelfiePath'] ?? '',
      daDongYXuLyDuLieu: map['daDongYXuLyDuLieu'] ?? false,
      thoiGianDongY: map['thoiGianDongY'] ?? '',
      diemBaiKiemTra: map['diemBaiKiemTra'] ?? 0,
      tongCauBaiKiemTra: map['tongCauBaiKiemTra'] ?? 0,
      diemDanhGia: (map['diemDanhGia'] ?? 0.0).toDouble(),
      tongLuotDanhGia: map['tongLuotDanhGia'] ?? 0,
      soLuongCaDuocPhat: map['soLuongCaDuocPhat'] ?? 0,
      soluongCaDaNhan: map['soluongCaDaNhan'] ?? 0,
      soLuongDaKhongNhan: map['soLuongDaKhongNhan'] ?? 0,
      soLuongCaHoanThanh: map['soLuongCaHoanThanh'] ?? 0,
      capDoUyTin: map['capDoUyTin'] ?? 0,
      kyNangDaXacMinh: List<String>.from(map['kyNangDaXacMinh'] ?? const []),
      maTrangThaiHoSo: map['maTrangThaiHoSo'] ?? kTrangThaiTiepNhan,
      nguoiDuyet: map['nguoiDuyet'],
      thoiGianDuyet: map['thoiGianDuyet'],
      lyDoTuChoi: map['lyDoTuChoi'],
      hanTaiXacMinh: map['hanTaiXacMinh'],
    );
  }
}
