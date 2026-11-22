import 'dart:async';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:flutter/material.dart';

class HoanThanhDonController {
  final String maYeuCau;
  final String currentUserId;
  final FirebaseService _service = FirebaseService();

  final ValueNotifier<List<Map<String, dynamic>>> danhSachPhanCongNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<List<DanhGiaModel>> danhGiaNotifier =
      ValueNotifier<List<DanhGiaModel>>([]);
  final ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);

  StreamSubscription? _phanCongSub;
  StreamSubscription? _danhGiaSub;

  HoanThanhDonController({required this.maYeuCau, required this.currentUserId});

  void init() {
    isLoadingNotifier.value = true;

    _phanCongSub = _service.langNgheDanhSachCuuHo(maYeuCau).listen((danhSach) {
      danhSachPhanCongNotifier.value = danhSach;
      _kiemTraDieuKienHoanThanh(danhSach);
      isLoadingNotifier.value = false;
    });

    _danhGiaSub = _service.langNgheDanhGia(maYeuCau).listen((danhGia) {
      danhGiaNotifier.value = danhGia;
    });
  }

  bool _laPhienDaHoanThanh(Map<String, dynamic> phien) {
    final status = (phien['maTrangThaiTiepNhan'] ?? '').toString().trim();
    return status == 'cuuho_trangthai_phancong_hoanthanh' ||
        status == 'hoanthanh';
  }

  void _kiemTraDieuKienHoanThanh(List<Map<String, dynamic>> danhSach) {
    if (danhSach.isEmpty) {
      isButtonEnabledNotifier.value = false;
      return;
    }

    // Chỉ cho phép hoàn thành đơn khi TẤT CẢ cứu hộ viên trong danh sách đều đã hoàn thành
    final bool tatCaDaHoanThanh = danhSach.every(_laPhienDaHoanThanh);
    isButtonEnabledNotifier.value = tatCaDaHoanThanh;
  }

  Future<bool> hoanThanhVaGuiTatCaDanhGia({
    required Map<String, int> selectedRatings,
    required Map<String, String> draftComments,
  }) async {
    final danhSachThanhVien = danhSachPhanCongNotifier.value;

    // Chặn tuyệt đối nếu còn ít nhất 1 người chưa hoàn thành
    if (danhSachThanhVien.isEmpty ||
        !danhSachThanhVien.every(_laPhienDaHoanThanh)) {
      return false;
    }

    final List<DanhGiaModel> listDanhGia = [];

    for (final tv in danhSachThanhVien) {
      final String maNguoiCuuHo = (tv['maNguoiCuuHo'] ?? '').toString();
      if (maNguoiCuuHo.isEmpty) continue;

      final int sao = selectedRatings[maNguoiCuuHo] ?? 5;
      final String nhanXet = (draftComments[maNguoiCuuHo] ?? '').trim();

      listDanhGia.add(
        DanhGiaModel(
          maDanhGia: maYeuCau,
          maYeuCau: maYeuCau,
          maNguoiDanhGia: currentUserId,
          maNguoiCuuHo: maNguoiCuuHo,
          diemDanhGia: sao,
          nhanXet: nhanXet,
          ngayTao: DateTime.now(),
        ),
      );
    }

    return await _service.xacNhanHoanThanhVaGuiDanhGia(
      maYeuCau: maYeuCau,
      danhSachDanhGia: listDanhGia,
    );
  }

  Future<bool> hoanThanhChuyenDi() async {
    final danhSachThanhVien = danhSachPhanCongNotifier.value;
    if (danhSachThanhVien.isEmpty ||
        !danhSachThanhVien.every(_laPhienDaHoanThanh)) {
      return false;
    }
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
