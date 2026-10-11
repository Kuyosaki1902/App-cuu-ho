// lib/mock_data.dart

import 'package:cuhokhancap/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/models/gioitinhmodel.dart';
import 'package:cuhokhancap/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/models/loaiyeucaumodel.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/models/nguoithanmodel.dart';
import 'package:cuhokhancap/models/tinhtrangyeucaumodel.dart';
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
    maGioiTinh: 'gioitinh1',
    maVaiTro: 'vaitro1',
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
    maGioiTinh: 'gioitinh1',
    maVaiTro: 'vaitro2', // Cứu hộ có chứng chỉ hành nghề (CCHN)
    matKhau: '123456',
    ngaySinh: DateTime(1998, 5, 12),
    ngayTao: DateTime.now(),
  ),
  // Người dùng thứ 3: Cứu hộ không có chứng chỉ (vaitro3)
  NguoiDungModel(
    maNguoiDung: 'nguoidung3',
    hoTen: 'Trần Văn B',
    email: 'tranvanb@gmail.com',
    diaChi: '456 Đường Lê Văn Việt, TP. Thủ Đức',
    queQuan: 'Đồng Nai',
    soDienThoai: '0123456777',
    maGioiTinh: 'gioitinh1',
    maVaiTro: 'vaitro3', // Cứu hộ KHÔNG có chứng chỉ hành nghề
    matKhau: '123456',
    ngaySinh: DateTime(1995, 8, 20),
    ngayTao: DateTime.now(),
  ),
];
final List<GioiTinhModel> GioiTinhList = [
  GioiTinhModel(maGioiTinh: "gioitinh1", gioiTinh: "Nam"),
  GioiTinhModel(maGioiTinh: "gioitinh2", gioiTinh: "Nữ"),
];
final List<VaiTroModel> VaiTroList = [
  VaiTroModel(maVaiTro: "vaitro1", vaiTro: "Người Dùng"),
  VaiTroModel(maVaiTro: "vaitro2", vaiTro: "Cứu Hộ Có Chứng Chỉ"),
  VaiTroModel(maVaiTro: "vaitro3", vaiTro: "Cứu Hộ Chưa Có Chứng Chỉ"),
];
final List<HoSoCuuHoCoCCHNModel> HoSoCuuHoCoCCHNList = [
  HoSoCuuHoCoCCHNModel(
    maNguoiDung: 'nguoidung2', // Liên kết đúng ID của nguoidung2
    soCanCuoc: '079198001234',
    ngayCapCanCuoc: DateTime(2021, 3, 15),
    ngayHetHanCanCuoc: DateTime(2038, 5, 12),
    coQuanCapCanCuoc: 'Cục Cảnh sát QLHC về TTXH',
    maCCHN: 'CCHN-YTE-2023-089',
    ngayCapCCHN: DateTime(2023, 6, 10),
    coQuanCapCCHN: 'Sở Y tế TP. Hồ Chí Minh',
    maTheChuyenNganh: 'TCN-CH-001',
    chucDanh: 'Bác sĩ Cấp cứu ngoài bệnh viện',
    donViCongTac: 'Trung tâm Cấp cứu 115 TP.HCM',
    diemDanhGia: 4.9,
    tongLuotDanhGia: 38,
    maTrangThaiHoSo: 'DA_DUYET',
  ),
];
final List<HoSoCuuHoKhongCCHNModel> HoSoCuuHoKhongCCHNList = [
  HoSoCuuHoKhongCCHNModel(
    maNguoiDung: 'nguoidung3', // Liên kết đúng ID của nguoidung3
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
  // Người dùng 1 xem Người dùng 2 (Nguyễn Văn A) là Cha
  NguoiThanModel(
    maNguoiDung: 'nguoidung1',
    maNguoiThan: 'nguoidung2',
    moiQuanHe: 'Bố (Ba)',
    trangThai: 'Đồng ý',
  ),
  // Người dùng 1 xem Người dùng 3 (Trần Văn B) là Mẹ
  NguoiThanModel(
    maNguoiDung: 'nguoidung1',
    maNguoiThan: 'nguoidung3',
    moiQuanHe: 'Mẹ',
    trangThai: 'Đồng ý',
  ),

  // Người dùng 2 (Cha) xem Người dùng 1 là Con (hoặc Con gái)
  NguoiThanModel(
    maNguoiDung: 'nguoidung2',
    maNguoiThan: 'nguoidung1',
    moiQuanHe: 'Con gái',
    trangThai: 'Đồng ý',
  ),
  // Người dùng 3 (Mẹ) xem Người dùng 1 là Con (hoặc Con gái)
  NguoiThanModel(
    maNguoiDung: 'nguoidung3',
    maNguoiThan: 'nguoidung1',
    moiQuanHe: 'Con gái',
    trangThai: 'Đồng ý',
  ),
];
final List<YeuCauCuuHoModel> listYeuCauCuuHo = [
  YeuCauCuuHoModel(
    maYeuCau: 'yeucau1',
    thoiGianTao: DateTime.now(),
    viDo: 10.85232,
    kinhDo: 106.75841,
    mucDoKhanCap: 3, // 1: Thấp, 2: Trung bình, 3: Khẩn cấp
    soNguoiCanCuuHo: 2,
    maNguoiYeuCau: 'nguoidung1', // Liễu Như Yên tạo đơn
    maAdminDieuPhoi: 'admin1',
    thoiGianPhanCong: DateTime.now(),
    thoiGianHoanThanh: null,
    maLoaiYeuCau: 'loaiyeucau1',
    maTinhTrangYeuCau: 'tinhtrang1',
  ),
];
final List<ChiTietPhanCongCuuHoModel> listChiTietPhanCong = [
  // Phân công 1: Gửi cho nguoidung2 (Nguyễn Văn A)
  ChiTietPhanCongCuuHoModel(
    maPhanCong: 'phancong1',
    maYeuCau: 'yeucau1',
    loaiPhanCong: 'Chính',
    maNguoiCuuHo: 'nguoidung2',
    thoiGianGui: DateTime.now(),
    thoiGianPhanHoi: null,
    maLoaiPhanCong: 'loaiphancong1',
    maTrangThaiTiepNhan: 'trangthai1',
  ),

  // Phân công 2: Gửi cho nguoidung3 (Trần Văn B)
  ChiTietPhanCongCuuHoModel(
    maPhanCong: 'phancong2',
    maYeuCau: 'yeucau1',
    loaiPhanCong: 'Hỗ trợ',
    maNguoiCuuHo: 'nguoidung3',
    thoiGianGui: DateTime.now(),
    thoiGianPhanHoi: null,
    maLoaiPhanCong: 'loaiphancong2',
    maTrangThaiTiepNhan: 'trangthai1',
  ),
];
final List<LoaiYeuCauModel> listLoaiYeuCau = [
  LoaiYeuCauModel(maLoaiYeuCau: 'loaiyeucau1', tenLoaiYeuCau: 'SOS'),
  LoaiYeuCauModel(maLoaiYeuCau: 'loaiyeucau2', tenLoaiYeuCau: 'Tìm Tự Động'),
  LoaiYeuCauModel(maLoaiYeuCau: 'loaiyeucau3', tenLoaiYeuCau: 'Chọn Bác Sĩ'),
];
final List<TinhTrangYeuCauModel> listTinhTrangYeuCau = [
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'tinhtrang1',
    tinhTrang: 'Chờ Tiếp Nhận',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'tinhtrang2',
    tinhTrang: 'Quá Hạn Điều Phối',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'tinhtrang3',
    tinhTrang: 'Đã Phân Công',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'tinhtrang4',
    tinhTrang: 'Đang Cứu Hộ',
  ),
  TinhTrangYeuCauModel(
    maTinhTrangYeuCau: 'tinhtrang5',
    tinhTrang: 'Hoàn Thành',
  ),
  TinhTrangYeuCauModel(maTinhTrangYeuCau: 'tinhtrang6', tinhTrang: 'Đã Hủy'),
];
final List<List> ListAll = [
  NguoiDungList,
  GioiTinhList,
  VaiTroList,
  HoSoCuuHoCoCCHNList,
  HoSoCuuHoKhongCCHNList,
  NguoiThanList,
  listYeuCauCuuHo,
  listChiTietPhanCong,
  listLoaiYeuCau,
  listTinhTrangYeuCau,
];
