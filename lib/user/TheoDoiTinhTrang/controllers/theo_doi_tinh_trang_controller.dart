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

  /// null = đang tải | {'isEmpty': true} = đơn không tồn tại |
  /// {'isError': true} = lỗi mạng/quyền | còn lại = dữ liệu đơn
  final ValueNotifier<Map<String, dynamic>?> requestDataNotifier =
      ValueNotifier(null);

  StreamSubscription<DocumentSnapshot>? _requestSub;
  int _seq = 0;
  bool _disposed = false;
  NguoiDungModel? _nanNhanCache;
  ChiTietMoTaHienTruongModel? _moTaCache;
  final Map<String, Map<String, dynamic>> _rescuerCache = {};

  static const _accepted = {
    'cuuho_trangthai_phancong_tiepnhan',
    'cuuho_trangthai_phancong_daden',
    'cuuho_trangthai_phancong_dangcuuho',
    'cuuho_trangthai_phancong_hoanthanh',
  };

  void init() {
    _requestSub = FirebaseFirestore.instance
        .collection('YeuCauCuuHo')
        .doc(maYeuCau)
        .snapshots()
        .listen(
          (doc) async {
            final seq = ++_seq;
            if (!doc.exists || doc.data() == null) {
              if (!_disposed) requestDataNotifier.value = {'isEmpty': true};
              return;
            }
            try {
              final yeuCau = YeuCauCuuHoModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              _nanNhanCache ??= await _firebaseService.getUserById(
                yeuCau.maNguoiYeuCau,
              );
              _moTaCache ??= await _firebaseService.getMoTaHienTruongById(
                maYeuCau,
              );

              final entries = yeuCau.danhSachPhanCongVien.entries.where(
                (e) => _accepted.contains(e.value),
              );

              final listCuuHo = (await Future.wait(
                entries.map((e) async {
                  Map<String, dynamic>? cache = _rescuerCache[e.key];
                  if (cache == null) {
                    final user = await _firebaseService.getUserById(e.key);
                    // Lỗi tạm thời -> KHÔNG cache null (nếu không người này sẽ biến mất mãi)
                    if (user == null) return null;
                    final avatar = await _firebaseService.getUserAvatarUrl(
                      e.key,
                    );
                    cache = {'user': user, 'avatar': avatar};
                    _rescuerCache[e.key] = cache;
                  }
                  return {...cache, 'trangThai': e.value};
                }),
              )).whereType<Map<String, dynamic>>().toList();

              if (_disposed || seq != _seq) {
                return; // có snapshot mới hơn -> bỏ kết quả cũ
              }
              requestDataNotifier.value = {
                'isEmpty': false,
                'yeuCau': yeuCau,
                'nanNhan': _nanNhanCache,
                'moTa': _moTaCache,
                'listCuuHo': listCuuHo,
              };
            } catch (e) {
              debugPrint('❌ Lỗi map data TheoDoiTinhTrang: $e');
              // Chưa có dữ liệu nào để hiện -> báo lỗi thay vì quay vòng mãi
              if (!_disposed && requestDataNotifier.value == null) {
                requestDataNotifier.value = {'isError': true};
              }
            }
          },
          onError: (e) {
            debugPrint('❌ Lỗi stream YeuCauCuuHo: $e');
            if (!_disposed) requestDataNotifier.value = {'isError': true};
          },
        );
  }

  /// Nút "Thử lại" trên màn hình lỗi
  void restart() {
    _requestSub?.cancel();
    _seq++;
    if (!_disposed) requestDataNotifier.value = null; // quay lại trạng thái đang tải
    init();
  }

  void dispose() {
    _disposed = true;
    _requestSub?.cancel();
    requestDataNotifier.dispose();
  }
}
