// lib/mock_data.dart

import 'package:cuhokhancap/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/models/gioitinhmodel.dart';
import 'package:cuhokhancap/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/models/loaiyeucaumodel.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/models/nguoithanmodel.dart';
import 'package:cuhokhancap/models/tinhtrangyeucaumodel.dart';
import 'package:cuhokhancap/models/trangthaimodel.dart';
import 'package:cuhokhancap/models/vaitromodel.dart';
import 'package:cuhokhancap/models/yeucaucuuhomodel.dart';

final List<NguoiDungModel> NguoiDungList = [
  NguoiDungModel(
    maNguoiDung: 'nguoidung1',
    hoTen: 'Liễu Như Yên',
    email: 'phannhuyen@gmail.com',
    diaChi: 'Tổng Dinh Thự Họ Liễu',
    queQuan: 'Dinh Thự Họ Liễu',
    soDienThoai: '0123456789',
    maGioiTinh: 'gioitinh_nu', // 🛠 Đã cập nhật
    maVaiTro: 'vaitro_nguoidung', // 🛠 Đã cập nhật
    matKhau: '123456',
    ngaySinh: DateTime(2000, 10, 7),
    ngayTao: DateTime.now(),
  ),
  NguoiDungModel(
    maNguoiDung: 'nguoidung2',
    hoTen: 'Nguyễn Văn A',
    email: 'nguyenvana@gmail.com',
    diaChi: '123 Đường ABC, Quận 1',
    queQuan: 'TP. Hồ Chí Minh',
    soDienThoai: '0123456788',
    maGioiTinh: 'gioitinh_nam', // 🛠 Đã cập nhật
    maVaiTro: 'vaitro_cuuhococc', // 🛠 Đã cập nhật (Cứu hộ có CCHN)
    matKhau: '123456',
    ngaySinh: DateTime(1998, 5, 12),
    ngayTao: DateTime.now(),
  ),
  NguoiDungModel(
    maNguoiDung: 'nguoidung3',
    hoTen: 'Trần Văn B',
    email: 'tranvanb@gmail.com',
    diaChi: '456 Đường Lê Văn Việt, TP. Thủ Đức',
    queQuan: 'Đồng Nai',
    soDienThoai: '0123456777',
    maGioiTinh: 'gioitinh_nam', // 🛠 Đã cập nhật
    maVaiTro: 'vaitro_cuuhochuacocc', // 🛠 Đã cập nhật (Cứu hộ KHÔNG CCHN)
    matKhau: '123456',
    ngaySinh: DateTime(1995, 8, 20),
    ngayTao: DateTime.now(),
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
    maNguoiDung: 'nguoidung2',
    soCanCuoc: '079198001234',
    ngayCapCanCuoc: DateTime(2021, 3, 15),
    ngayHetHanCanCuoc: DateTime(2038, 5, 12),
    coQuanCapCanCuoc: 'Cục Cảnh sát QLHC về TTXH',
    maCCHN: 'CCHN-YTE-2023-089',
    ngayCapCCHN: DateTime(2023, 6, 10),
    coQuanCapCCHN: 'Sở Y tế TP. Hồ Chí Minh',
    maTheChuyenNganh: 'TCN-CH-001',
    tenChuyenNganh: 'Tim Mạch',
    chucDanh: 'Bác sĩ Cấp cứu ngoài bệnh viện',
    donViCongTac: 'Trung tâm Cấp cứu 115 TP.HCM',
    diemDanhGia: 4.9,
    tongLuotDanhGia: 38,
    maTrangThaiHoSo: 'DA_DUYET',
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

final List<List> ListAll = [
  GioiTinhList,
  VaiTroList,
  NguoiThanList,
  listLoaiYeuCau,
  listTinhTrangYeuCau,
  listTrangThai,
];
