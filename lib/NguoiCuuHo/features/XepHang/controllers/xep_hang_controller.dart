import 'dart:convert';

import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/controllers/anh_dai_dien_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/controllers/xep_hang_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/XepHang/models/xep_hang_model.dart';
import 'package:flutter/material.dart';

class XepHangController extends ChangeNotifier {
  /// [lamMoiTruocKhiTaiTatCa]: việc do nơi ghép màn hình cung cấp (ví dụ làm mới
  /// điểm tổng) chạy trước khi tải bảng "Từ trước đến nay". Xếp hạng không cần biết
  /// việc đó thuộc tính năng nào.
  XepHangController(
    this.userId, {
    XepHangService? service,
    this.lamMoiTruocKhiTaiTatCa,
  }) : _service = service ?? XepHangService();

  final String userId;
  final XepHangService _service;
  final Future<void> Function()? lamMoiTruocKhiTaiTatCa;

  bool _disposed = false;
  int _lanTai = 0;

  KyXepHang ky = KyXepHang.tuan;
  List<XepHangItem> bangXepHang = const [];
  XepHangItem? mucCuaToi;
  bool dangTaiBang = false;
  String? loiBang;

  String get nhanKy => XepHangService.nhanKy(ky);
  bool get toiTrongBang =>
      mucCuaToi != null && bangXepHang.any((e) => e.maNguoiDung == userId);

  final AnhDaiDienService _avatarService = AnhDaiDienService();
  final Map<String, Future<ImageProvider?>> _avatarCache = {};

  Future<ImageProvider?> layAvatarProvider(String uid) {
    if (uid.isEmpty) return Future.value(null);
    return _avatarCache.putIfAbsent(uid, () async {
      try {
        final raw = await _avatarService.layAnhDaiDien(uid);
        if (raw == null || raw.isEmpty) return null;
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          return NetworkImage(raw);
        }
        final clean = raw.contains(',') ? raw.split(',').last : raw;
        return MemoryImage(base64Decode(clean.trim()));
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> doiKy(KyXepHang moi) async {
    if (moi == ky) return;
    ky = moi;
    bangXepHang = const [];
    mucCuaToi = null;
    await taiBangXepHang();
  }

  Future<void> taiBangXepHang() async {
    final kyHienTai = ky;
    final lan = ++_lanTai;
    dangTaiBang = true;
    loiBang = null;
    notifyListeners();

    try {
      if (kyHienTai == KyXepHang.tatCa && lamMoiTruocKhiTaiTatCa != null) {
        try {
          await lamMoiTruocKhiTaiTatCa!();
        } catch (e) {
          debugPrint('XepHang: làm mới điểm thất bại: $e');
        }
      }

      final fBang = _service.layBangXepHang(kyHienTai);
      final fMuc = _service.layMucCuaToi(kyHienTai, userId);
      final bang = await fBang;
      final muc = await fMuc;

      if (lan != _lanTai) return;
      bangXepHang = bang;
      mucCuaToi = muc;
    } catch (e) {
      debugPrint('XepHang: lỗi tải bảng: $e');
      if (lan == _lanTai) {
        loiBang = 'Không tải được bảng xếp hạng. Thử lại sau.';
      }
    }

    if (lan == _lanTai) dangTaiBang = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
