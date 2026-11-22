// lib/user/LichSuCuuHo/controllers/lich_su_cuu_ho_controller.dart
import 'package:flutter/material.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';

class RescuerHistoryItem {
  final NguoiDungModel user;
  final String? avatarUrl;
  final String trangThai;

  RescuerHistoryItem({
    required this.user,
    this.avatarUrl,
    required this.trangThai,
  });
}

class RescueHistoryCardData {
  final YeuCauCuuHoModel yeuCau;
  final ChiTietMoTaHienTruongModel? moTa;
  final List<RescuerHistoryItem> rescuers;
  final Map<String, DanhGiaModel> danhGiaMap; // Key: maNguoiCuuHo

  RescueHistoryCardData({
    required this.yeuCau,
    this.moTa,
    required this.rescuers,
    required this.danhGiaMap,
  });

  bool get isCompleted =>
      yeuCau.maTinhTrangYeuCau == 'user_tinhtrang_hoanthanh';

  bool get isAllEvaluated =>
      rescuers.isNotEmpty &&
      rescuers.every(
        (r) =>
            r.user.maNguoiDung != null &&
            danhGiaMap.containsKey(r.user.maNguoiDung),
      );
}

class LichSuCuuHoController {
  final String currentUserId;
  final FirebaseService _firebaseService = FirebaseService();

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<List<RescueHistoryCardData>> historyListNotifier =
      ValueNotifier([]);

  LichSuCuuHoController({required this.currentUserId});

  Future<void> loadHistory() async {
    isLoadingNotifier.value = true;
    try {
      final yeuCauList = await _firebaseService.getLichSuYeuCauByUser(
        currentUserId,
      );
      List<RescueHistoryCardData> cardList = [];

      const acceptedStatuses = {
        'cuuho_trangthai_phancong_tiepnhan',
        'cuuho_trangthai_phancong_daden',
        'cuuho_trangthai_phancong_dangcuuho',
        'cuuho_trangthai_phancong_hoanthanh',
      };

      for (var yc in yeuCauList) {
        final validRescuerIds = yc.danhSachPhanCongVien.entries
            .where((e) => acceptedStatuses.contains(e.value))
            .map((e) => e.key)
            .toList();

        final results = await Future.wait([
          _firebaseService.getMoTaHienTruongById(yc.maYeuCau),
          validRescuerIds.isEmpty
              ? Future.value(<NguoiDungModel>[])
              : _firebaseService.getUsersByIds(validRescuerIds),
          _firebaseService.getDanhGiaCuuHoVienTheoYeuCau(
            yc.maYeuCau,
            rescuerIds: validRescuerIds,
          ),
        ]);

        final moTa = results[0] as ChiTietMoTaHienTruongModel?;
        final users = results[1] as List<NguoiDungModel>;
        final danhGiaMap = results[2] as Map<String, DanhGiaModel>;

        List<RescuerHistoryItem> rescuerItems = [];
        for (var u in users) {
          if (u.maNguoiDung == null) continue;
          final avatar = await _firebaseService.getUserAvatarUrl(
            u.maNguoiDung!,
          );
          rescuerItems.add(
            RescuerHistoryItem(
              user: u,
              avatarUrl: avatar,
              trangThai: yc.danhSachPhanCongVien[u.maNguoiDung!] ?? '',
            ),
          );
        }

        cardList.add(
          RescueHistoryCardData(
            yeuCau: yc,
            moTa: moTa,
            rescuers: rescuerItems,
            danhGiaMap: danhGiaMap,
          ),
        );
      }

      historyListNotifier.value = cardList;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<bool> submitEvaluation({
    required String maYeuCau,
    required String maNguoiCuuHo,
    required int diemDanhGia,
    required String nhanXet,
  }) async {
    final newDanhGia = DanhGiaModel(
      maDanhGia: maNguoiCuuHo,
      maYeuCau: maYeuCau,
      maNguoiDanhGia: currentUserId,
      maNguoiCuuHo: maNguoiCuuHo,
      diemDanhGia: diemDanhGia,
      nhanXet: nhanXet.trim(),
      ngayTao: DateTime.now(),
    );

    final ok = await _firebaseService.guiDanhGiaCuuHoVien(newDanhGia);
    if (ok) {
      final currentList = List<RescueHistoryCardData>.from(
        historyListNotifier.value,
      );
      final idx = currentList.indexWhere((c) => c.yeuCau.maYeuCau == maYeuCau);
      if (idx != -1) {
        final oldCard = currentList[idx];
        final updatedMap = Map<String, DanhGiaModel>.from(oldCard.danhGiaMap);
        updatedMap[maNguoiCuuHo] = newDanhGia;

        currentList[idx] = RescueHistoryCardData(
          yeuCau: oldCard.yeuCau,
          moTa: oldCard.moTa,
          rescuers: oldCard.rescuers,
          danhGiaMap: updatedMap,
        );
        historyListNotifier.value = currentList;
      }
    }
    return ok;
  }

  void dispose() {
    isLoadingNotifier.dispose();
    historyListNotifier.dispose();
  }
}
