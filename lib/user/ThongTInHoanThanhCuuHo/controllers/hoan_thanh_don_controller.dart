// lib/user/ThongTInHoanThanhCuuHo/controllers/hoan_thanh_don_controller.dart
import 'dart:async';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:flutter/material.dart';

class HoanThanhDonController {
  final String maYeuCau;
  final String currentUserId;
  final FirebaseService _service = FirebaseService();

  final ValueNotifier<List<Map<String, dynamic>>> danhSachPhanCongNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<DanhGiaModel>> danhGiaNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);

  StreamSubscription? _phanCongSub;
  StreamSubscription? _danhGiaSub;

  HoanThanhDonController({required this.maYeuCau, required this.currentUserId});

  void init() {
    isLoadingNotifier.value = true;

    // 1. Lắng nghe danh sách cứu hộ viên từ YeuCauCuuHo
    _phanCongSub = _service.langNgheDanhSachCuuHo(maYeuCau).listen((danhSach) {
      danhSachPhanCongNotifier.value = danhSach;
      _kiemTraDieuKienHoanThanh(danhSach);
      isLoadingNotifier.value = false;
    });

    // 2. Lắng nghe đánh giá
    _danhGiaSub = _service.langNgheDanhGia(maYeuCau).listen((danhGia) {
      danhGiaNotifier.value = danhGia;
    });
  }

  void _kiemTraDieuKienHoanThanh(List<Map<String, dynamic>> danhSach) {
    if (danhSach.isEmpty) {
      isButtonEnabledNotifier.value = false;
      return;
    }

    // Đồng bộ với màn hình Tổng quan: có ít nhất 1 cứu hộ viên hoàn thành là mở nút xác nhận
    bool daHoanThanh = danhSach.any((phien) {
      final status = (phien['maTrangThaiTiepNhan'] ?? '').toString();
      return status == 'cuuho_trangthai_phancong_hoanthanh' ||
          status == 'hoanthanh';
    });

    isButtonEnabledNotifier.value = daHoanThanh;
  }

  Future<bool> submitDanhGia(
    String maNguoiCuuHo,
    int diem,
    String nhanXet,
  ) async {
    final danhGiaMoi = DanhGiaModel(
      maDanhGia: maNguoiCuuHo,
      maYeuCau: maYeuCau,
      maNguoiDanhGia: currentUserId,
      maNguoiCuuHo: maNguoiCuuHo,
      diemDanhGia: diem,
      nhanXet: nhanXet,
      ngayTao: DateTime.now(),
    );
    return await _service.guiDanhGiaCuuHoVien(danhGiaMoi);
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
    isLoadingNotifier.dispose();
  }
}
