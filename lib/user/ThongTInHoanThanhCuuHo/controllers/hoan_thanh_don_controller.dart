import 'dart:async';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart'; // Đổi import gọi thẳng FirebaseService

class HoanThanhDonController {
  final String maYeuCau;
  final String currentUserId;
  final FirebaseService _service =
      FirebaseService(); // Khởi tạo FirebaseService tổng

  // Danh sách chi tiết phân công
  final ValueNotifier<List<Map<String, dynamic>>> danhSachPhanCongNotifier =
      ValueNotifier([]);
  // Danh sách đánh giá
  final ValueNotifier<List<DanhGiaModel>> danhGiaNotifier = ValueNotifier([]);
  // Trạng thái nút xác nhận
  final ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier(false);

  StreamSubscription? _phanCongSub;
  StreamSubscription? _danhGiaSub;

  HoanThanhDonController({required this.maYeuCau, required this.currentUserId});

  void init() {
    // 1. Lắng nghe chi tiết phân công
    _phanCongSub = _service.langNgheDanhSachCuuHo(maYeuCau).listen((danhSach) {
      danhSachPhanCongNotifier.value = danhSach;
      _kiemTraDieuKienHoanThanh(danhSach);
    });

    // 2. Lắng nghe danh giá
    _danhGiaSub = _service.langNgheDanhGia(maYeuCau).listen((danhGia) {
      danhGiaNotifier.value = danhGia;
    });
  }

  // 🌟 ĐIỀU KIỆN KÍCH HOẠT NÚT HOÀN THÀNH KÉP
  void _kiemTraDieuKienHoanThanh(List<Map<String, dynamic>> danhSach) {
    if (danhSach.isEmpty) {
      isButtonEnabledNotifier.value = false;
      return;
    }

    // Yêu cầu MỌI cứu hộ viên (đã tiếp nhận) đều phải có trạng thái hoanthanh
    bool tatCaDaHoanThanh = danhSach.every(
      (phien) =>
          phien['maTrangThaiTiepNhan'] == 'cuuho_trangthai_phancong_hoanthanh',
    );

    isButtonEnabledNotifier.value = tatCaDaHoanThanh;
  }

  Future<bool> submitDanhGia(
    String maNguoiCuuHo,
    int diem,
    String nhanXet,
  ) async {
    final danhGiaMoi = DanhGiaModel(
      maDanhGia: '',
      maYeuCau: maYeuCau,
      maNguoiDanhGia: currentUserId,
      maNguoiCuuHo: maNguoiCuuHo,
      diemDanhGia: diem,
      nhanXet: nhanXet,
      ngayTao: DateTime.now(),
    );
    return await _service.guiDanhGia(danhGiaMoi);
  }

  Future<bool> hoanThanhChuyenDi() async {
    return await _service.xacNhanHoanThanhYeuCau(maYeuCau);
  }

  void dispose() {
    _phanCongSub?.cancel();
    _danhGiaSub?.cancel();
    danhSachPhanCongNotifier.dispose();
    danhGiaNotifier.dispose();
    isButtonEnabledNotifier.dispose();
  }
}
