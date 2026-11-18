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
        .listen((doc) async {
          final seq = ++_seq;
          if (!doc.exists || doc.data() == null) {
            if (!_disposed) requestDataNotifier.value = {'isEmpty': true};
            return;
          }
          try {
            final yeuCau = YeuCauCuuHoModel.fromMap(doc.data()!, doc.id);
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
                final cache = _rescuerCache[e.key] ??= {
                  'user': await _firebaseService.getUserById(e.key),
                  'avatar': await _firebaseService.getUserAvatarUrl(e.key),
                };
                if (cache['user'] == null) return null;
                return {...cache, 'trangThai': e.value};
              }),
            )).whereType<Map<String, dynamic>>().toList();

            if (_disposed || seq != _seq)
              return; // có snapshot mới hơn -> bỏ kết quả cũ
            requestDataNotifier.value = {
              'isEmpty': false,
              'yeuCau': yeuCau,
              'nanNhan': _nanNhanCache,
              'moTa': _moTaCache,
              'listCuuHo': listCuuHo,
            };
          } catch (e) {
            debugPrint('❌ Lỗi map data TheoDoiTinhTrang: $e');
          }
        });
  }

  void dispose() {
    _disposed = true;
    _requestSub?.cancel();
    requestDataNotifier.dispose();
  }
}
