// lib/mock_data.dart

import 'package:cuhokhancap/user/models/chitietkynangmodel.dart';
import 'package:cuhokhancap/user/models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/gioitinhmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/user/models/loaiyeucaumodel.dart';
import 'package:cuhokhancap/user/models/moiquanhe.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/models/nguoithanmodel.dart';
import 'package:cuhokhancap/user/models/phanloaianhmodel.dart';
import 'package:cuhokhancap/user/models/tinhtrangyeucaumodel.dart';
import 'package:cuhokhancap/user/models/trangthaimodel.dart';
import 'package:cuhokhancap/user/models/vaitromodel.dart';
import 'package:cuhokhancap/user/models/yeucaucuuhomodel.dart';

final List<NguoiDungModel> NguoiDungList = [
  NguoiDungModel(
    maNguoiDung: 'nguoidung4',
    hoTen: 'Nguyễn Phan Liêm',
    email: 'phanliem@gmail.com',
    diaChi: 'Đô Lương, P.11, TP. Vũng Tàu',
    queQuan: 'Bà Rịa - Vũng Tàu',
    soDienThoai: '0907777888',
    maGioiTinh: 'gioitinh_nam',
    maVaiTro: 'vaitro_cuuhococc',
    matKhau: '123456',
    ngaySinh: DateTime(1985, 3, 12),
    ngayTao: DateTime.now(),
    viDo: 10.3750,
    kinhDo: 107.1050,
    geohash: 'w263f9x',
    isOnline: false,
    nhanCaCuuHo: false,
  ),
  NguoiDungModel(
    maNguoiDung: 'nguoidung5',
    hoTen: 'Nguyễn Không Liêm',
    email: 'phanliem@gmail.com',
    diaChi: 'Đô Lương, P.11, TP. Vũng Tàu',
    queQuan: 'Bà Rịa - Vũng Tàu',
    soDienThoai: '0907777888',
    maGioiTinh: 'gioitinh_nam',
    maVaiTro: 'vaitro_cuuhococc',
    matKhau: '123456',
    ngaySinh: DateTime(1985, 3, 12),
    ngayTao: DateTime.now(),
    viDo: 10.3750,
    kinhDo: 107.1050,
    geohash: 'w263f9x',
    isOnline: false,
    nhanCaCuuHo: false,
  ),
  NguoiDungModel(
    maNguoiDung: 'nguoidung6',
    hoTen: 'Nguyễn Chỉ Liêm',
    email: 'phanliem@gmail.com',
    diaChi: 'Đô Lương, P.11, TP. Vũng Tàu',
    queQuan: 'Bà Rịa - Vũng Tàu',
    soDienThoai: '0907777888',
    maGioiTinh: 'gioitinh_nam',
    maVaiTro: 'vaitro_cuuhococc',
    matKhau: '123456',
    ngaySinh: DateTime(1985, 3, 12),
    ngayTao: DateTime.now(),
    viDo: 10.3750,
    kinhDo: 107.1050,
    geohash: 'w263f9x',
    isOnline: false,
    nhanCaCuuHo: false,
  ),
];

final List<GioiTinhModel> GioiTinhList = [
  GioiTinhModel(maGioiTinh: "gioitinh_nam", gioiTinh: "Nam"),
  GioiTinhModel(maGioiTinh: "gioitinh_nu", gioiTinh: "Nữ"),
];

final List<VaiTroModel> VaiTroList = [
  VaiTroModel(maVaiTro: "vaitro_nguoidung", vaiTro: "Người Dùng"),
  VaiTroModel(maVaiTro: "vaitro_cuuhococc", vaiTro: "Cứu Hộ Có Chứng Chỉ"),
  VaiTroModel(
    maVaiTro: "vaitro_cuuhochuacocc",
    vaiTro: "Cứu Hộ Chưa Có Chứng Chỉ",
  ),
];

final List<HoSoCuuHoCoCCHNModel> HoSoCuuHoCoCCHNList = [
  HoSoCuuHoCoCCHNModel(
    maNguoiDung: 'nguoidung6',
    soCanCuoc: '079188009999',
    ngayCapCanCuoc: DateTime(2020, 5, 10),
    ngayHetHanCanCuoc: DateTime(2038, 9, 20),
    coQuanCapCanCuoc: 'Cục Cảnh sát QLHC về TTXH',
    maCCHN: 'CCHN-YTE-2022-555',
    ngayCapCCHN: DateTime(2022, 1, 15),
    coQuanCapCCHN: 'Sở Y tế Bà Rịa - Vũng Tàu',
    maTheChuyenNganh: 'TCN-CH-005',
    tenChuyenNganh: 'Chấn thương Chỉnh hình',
    chucDanh: 'Bác sĩ Cấp cứu Ngoại khoa',
    donViCongTac: 'Bệnh viện Đa khoa Vũng Tàu',
    diemDanhGia: 5.0,
    tongLuotDanhGia: 42,
    maTrangThaiHoSo: 'cuuho_trangthai_tiepnhan',
  ),
  HoSoCuuHoCoCCHNModel(
    maNguoiDung: 'nguoidung7',
    soCanCuoc: '079185007777',
    ngayCapCanCuoc: DateTime(2019, 8, 20),
    ngayHetHanCanCuoc: DateTime(2035, 3, 12),
    coQuanCapCanCuoc: 'Cục Cảnh sát QLHC về TTXH',
    maCCHN: 'CCHN-YTE-2021-777',
    ngayCapCCHN: DateTime(2021, 4, 10),
    coQuanCapCCHN: 'Sở Y tế Bà Rịa - Vũng Tàu',
    maTheChuyenNganh: 'TCN-CH-007',
    tenChuyenNganh: 'Hồi sức Cấp cứu',
    chucDanh: 'Trưởng khoa Cấp cứu',
    donViCongTac: 'Trung tâm Y tế TP. Vũng Tàu',
    diemDanhGia: 4.9,
    tongLuotDanhGia: 56,
    maTrangThaiHoSo: 'cuuho_trangthai_tiepnhan',
  ),
];

final List<HoSoCuuHoKhongCCHNModel> HoSoCuuHoKhongCCHNList = [
  HoSoCuuHoKhongCCHNModel(
    maNguoiDung: 'nguoidung3',
    soCanCuoc: '075195005678',
    ngayCapCanCuoc: DateTime(2022, 1, 10),
    ngayHetHanCanCuoc: DateTime(2035, 8, 20),
    coQuanCapCanCuoc: 'Cục Cảnh sát QLHC về TTXH',
    doiNhom: 'Đội Cứu hộ Tình nguyện TP. Thủ Đức',
    soNamHoatDongCuuHo: 3,
    soLanThamGiaCuuHo: 24,
    diemDanhGia: 4.7,
    tongLuotDanhGia: 15,
    ghiChu: 'Thành thạo kỹ năng sơ cấp cứu ban đầu và sửa chữa xe máy cơ bản',
    maTrangThaiHoSo: 'DA_DUYET',
  ),
];

final List<NguoiThanModel> NguoiThanList = [
  NguoiThanModel(
    maNguoiDung: 'nguoidung1',
    maNguoiThan: 'nguoidung2',
    moiQuanHe: 'Bố (Ba)',
    trangThai: 'trangthai_dongy', // 🛠 Đã cập nhật
    ngayTao: DateTime.now(),
  ),
  NguoiThanModel(
    maNguoiDung: 'nguoidung1',
    maNguoiThan: 'nguoidung3',
    moiQuanHe: 'Mẹ',
    trangThai: 'trangthai_dongy', // 🛠 Đã cập nhật
    ngayTao: DateTime.now(),
  ),

  NguoiThanModel(
    maNguoiDung: 'nguoidung2',
    maNguoiThan: 'nguoidung1',
    moiQuanHe: 'Con gái',
    trangThai: 'trangthai_dongy', // 🛠 Đã cập nhật
    ngayTao: DateTime.now(),
  ),
  NguoiThanModel(
    maNguoiDung: 'nguoidung3',
    maNguoiThan: 'nguoidung1',
    moiQuanHe: 'Con gái',
    trangThai: 'trangthai_dongy', // 🛠 Đã cập nhật
    ngayTao: DateTime.now(),
  ),
];

final List<YeuCauCuuHoModel> listYeuCauCuuHo = [
  YeuCauCuuHoModel(
    maYeuCau: 'yeucau1',
    thoiGianTao: DateTime.now(),
    viDo: 10.85232,
    kinhDo: 106.75841,
    mucDoKhanCap: 3,
    soNguoiCanCuuHo: 2,
    maNguoiYeuCau: 'nguoidung1',
    maAdminDieuPhoi: 'admin1',
    thoiGianPhanCong: DateTime.now(),
    thoiGianHoanThanh: null,
    maLoaiYeuCau: 'loaiyeucau_sos', // 🛠 Đã cập nhật
    maTinhTrangYeuCau: 'user_tinhtrang_chotiepnhan', // 🛠 Đã cập nhật
  ),
  YeuCauCuuHoModel(
    maYeuCau: 'yeucau2',
    thoiGianTao: DateTime.now(),
    viDo: 10.3394,
    kinhDo: 107.0835,
    mucDoKhanCap: 1,
    soNguoiCanCuuHo: 1,
    maNguoiYeuCau: 'nguoidung4',
    maAdminDieuPhoi: null,
    thoiGianPhanCong: null,
    thoiGianHoanThanh: null,
    maLoaiYeuCau: 'loaiyeucau_sos',
    maTinhTrangYeuCau: 'user_tinhtrang_chotiepnhan',
  ),
];

final List<ChiTietPhanCongCuuHoModel> listChiTietPhanCong = [
  ChiTietPhanCongCuuHoModel(
    maPhanCong: 'phancong1',
    maYeuCau: 'yeucau1',
    loaiPhanCong: 'Chính',
    maNguoiCuuHo: 'nguoidung2',
    thoiGianGui: DateTime.now(),
    thoiGianPhanHoi: null,
    maLoaiPhanCong: 'loaiphancong1',
    maTrangThaiTiepNhan: 'trangthai_choxemxet', // 🛠 Đã cập nhật
  ),
  ChiTietPhanCongCuuHoModel(
    maPhanCong: 'phancong2',
    maYeuCau: 'yeucau1',
    loaiPhanCong: 'Hỗ trợ',
    maNguoiCuuHo: 'nguoidung3',
    thoiGianGui: DateTime.now(),
    thoiGianPhanHoi: null,
    maLoaiPhanCong: 'loaiphancong2',
    maTrangThaiTiepNhan: 'trangthai_choxemxet', // 🛠 Đã cập nhật
  ),
];

final List<LoaiYeuCauModel> listLoaiYeuCau = [
  LoaiYeuCauModel(maLoaiYeuCau: 'loaiyeucau_sos', tenLoaiYeuCau: 'SOS'),
  LoaiYeuCauModel(
    maLoaiYeuCau: 'loaiyeucau_timtudong',
    tenLoaiYeuCau: 'Tìm Tự Động',
  ),
  LoaiYeuCauModel(
    maLoaiYeuCau: 'loaiyeucau_chonbacsi',
    tenLoaiYeuCau: 'Chọn Bác Sĩ',
  ),
];

final List<TinhTrangYeuCauModel> listTinhTrangYeuCau = [
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_chotiepnhan',
    tinhTrang: 'Chờ Tiếp Nhận',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_quahandieuphoi',
    tinhTrang: 'Quá Hạn Điều Phối',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_daphancong',
    tinhTrang: 'Đã Phân Công',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_dangcuuho',
    tinhTrang: 'Đang Cứu Hộ',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_hoanthanh',
    tinhTrang: 'Hoàn Thành',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'user_tinhtrang_dahuy',
    tinhTrang: 'Đã Hủy',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'admin_tinhtrang_hoatdong',
    tinhTrang: 'Hoạt Động',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'admin_tinhtrang_tamkhoa',
    tinhTrang: 'Tạm Khóa',
  ),
];

final List<TrangThaiModel> listTrangThai = [
  TrangThaiModel(
    maTrangThai: "cuuho_trangthai_tiepnhan",
    trangThai: "Tiếp Nhận",
  ),
  TrangThaiModel(maTrangThai: "cuuho_trangthai_daduyet", trangThai: "Đã Duyệt"),
  TrangThaiModel(maTrangThai: "cuuho_trangthai_tuchoi", trangThai: "Từ Chối"),
];
final List<ChiTietMoTaHienTruongModel> ChiTietMoTaHienTruongList = [
  ChiTietMoTaHienTruongModel(
    maYeuCau: 'yeucau2',
    videoUrl: 'https://example.com/video_hientruong_2.mp4',
    ghiAmUrl: 'https://example.com/audio_hientruong_2.mp3',
    ghiChuText: {
      'trieuChung': ['Sốt cao 39.5°C', 'Co giật nhẹ', 'Khó thở'],
      'moTaChiTiet':
          'Bệnh nhân có biểu hiện co giật kéo dài khoảng 2 phút, người nhà đã sơ cứu mở thoáng đường thở. Cần bác sĩ ngoại khoa/cấp cứu hỗ trợ gấp tại hiện trường.',
    },
    thoiGianTao: DateTime.now(),
  ),
];
final List<MoiQuanHeModel> listMoiQuanHe = [];
final List<ChiTietKyNangModel> listChiTietKiNang = [
  ChiTietKyNangModel(
    maNguoiDung: 'nguoidung3',
    danhSachKiNang: [
      ChiTietKyNangItemModel(
        maKyNangCuuHo: 'kn_bang_bo',
        ngayCapNhat: DateTime.now(),
      ),
      ChiTietKyNangItemModel(
        maKyNangCuuHo: 'kn_bong',
        ngayCapNhat: DateTime.now(),
      ),
      ChiTietKyNangItemModel(
        maKyNangCuuHo: 'kn_cpr',
        ngayCapNhat: DateTime.now(),
      ),
      ChiTietKyNangItemModel(
        maKyNangCuuHo: 'kn_co_dinh',
        ngayCapNhat: DateTime.now(),
      ),
      ChiTietKyNangItemModel(
        maKyNangCuuHo: 'kn_duoi_nuoc',
        ngayCapNhat: DateTime.now(),
      ),
    ],
  ),
];
final List<PhanLoaiAnhModel> listPhanLoaiAnh = [
  PhanLoaiAnhModel(
    maPhanLoaiAnh: 'phanloaianh_anhthuctekhongcchn',
    tenLoai: 'Ảnh Thực Tế Không CCHN',
  ),
  PhanLoaiAnhModel(
    maPhanLoaiAnh: 'phanloaianh_thecongtac',
    tenLoai: 'Thẻ Công Tác',
  ),
  PhanLoaiAnhModel(
    maPhanLoaiAnh: 'phanloaianh_avatar',
    tenLoai: 'Ảnh Avatar Người Dùng',
  ),
  PhanLoaiAnhModel(
    maPhanLoaiAnh: 'phanloaianh_hientruong',
    tenLoai: 'Ảnh Hiện Trường Nạn Nhân',
  ),
];
final List<List> ListAll = [listPhanLoaiAnh];
