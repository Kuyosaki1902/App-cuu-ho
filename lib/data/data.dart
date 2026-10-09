// lib/mock_data.dart

import 'package:cuhokhancap/models/gioitinhmodel.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/models/vaitromodel.dart';

final List<NguoiDungModel> NguoiDungList = [
  NguoiDungModel(
    maNguoiDung: 'nguoidung1',
    hoTen: 'Liễu Như Yên',
    email: 'phannhuyen@gmail.com',
    diaChi: 'Tổng Dinh Thự Họ Liễu',
    queQuan: 'Dinh Thự Họ Liễu',
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
