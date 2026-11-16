// lib/user/TheoDoiTinhTrang/controllers/theo_doi_tinh_trang_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';

class TheoDoiTinhTrangController {
  final String maYeuCau;

  TheoDoiTinhTrangController({required this.maYeuCau});

  final FirebaseService _firebaseService = FirebaseService();

  // Đã thêm khoảng trắng chống nuốt code
  final ValueNotifier<Map<String, dynamic>?> requestDataNotifier =
      ValueNotifier(null);

  StreamSubscription<DocumentSnapshot>? _requestSub;

  void init() {
    _requestSub = FirebaseFirestore.instance
        .collection('YeuCauCuuHo')
        .doc(maYeuCau)
        .snapshots()
        .listen((doc) async {
          if (doc.exists && doc.data() != null) {
            try {
              // 1. Lấy thông tin Yêu Cầu
              YeuCauCuuHoModel yeuCau = YeuCauCuuHoModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              // 2. Lấy thông tin Nạn Nhân
              NguoiDungModel? nanNhan = await _firebaseService.getUserById(
                yeuCau.maNguoiYeuCau,
              );

              // 3. Lấy Mô Tả Hiện Trường (Triệu chứng, Ghi chú)
              ChiTietMoTaHienTruongModel? moTa = await _firebaseService
                  .getMoTaHienTruongById(maYeuCau);

              // 4. Lấy danh sách Cứu Hộ Viên (Đã loại những người từ chối/hủy)
              List<Map<String, dynamic>> listCuuHo = [];

              for (var entry in yeuCau.danhSachPhanCongVien.entries) {
                String maCuuHo = entry.key;
                String trangThai = entry.value;

                if (trangThai != 'cuuho_trangthai_phancong_tuchoi' &&
                    trangThai != 'cuuho_trangthai_phancong_dahuy' &&
                    trangThai != 'tuchoi' &&
                    trangThai != 'dahuy') {
                  NguoiDungModel? userCuuHo = await _firebaseService
                      .getUserById(maCuuHo);

                  if (userCuuHo != null) {
                    String? avatar = await _firebaseService.getUserAvatarUrl(
                      maCuuHo,
                    );

                    listCuuHo.add({
                      'user': userCuuHo,
                      'trangThai': trangThai,
                      'avatar': avatar,
                    });
                  }
                }
              }

              // Cập nhật State
              requestDataNotifier.value = {
                'isEmpty': false,
                'yeuCau': yeuCau,
                'nanNhan': nanNhan,
                'moTa': moTa,
                'listCuuHo': listCuuHo,
              };
            } catch (e) {
              debugPrint('❌ Lỗi map data TheoDoiTinhTrang: $e');
            }
          } else {
            requestDataNotifier.value = {'isEmpty': true}; // Đơn không tồn tại
          }
        });
  }

  void dispose() {
    _requestSub?.cancel();
    requestDataNotifier.dispose();
  }
}
