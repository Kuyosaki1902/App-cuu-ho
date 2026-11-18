// lib/user/Design/anh_dai_dien_widget.dart
//
// Avatar dùng chung, REALTIME: lắng nghe Firestore nên ảnh tự đổi ngay khi
// người dùng cập nhật, không cần quay lại/làm mới màn hình. Có cache để vẽ
// ngay ảnh gần nhất trong lúc chờ kết nối, và rơi về chữ cái viết tắt khi chưa có ảnh.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cuhokhancap/firebase/anh_dai_dien_service.dart';
import 'package:flutter/material.dart';

class AnhDaiDienWidget extends StatefulWidget {
  const AnhDaiDienWidget({
    super.key,
    required this.maNguoiDung,
    required this.hoTen,
    this.radius = 26,
    this.fontSize = 18,
    this.mauNen = const Color(0xFF00695C),
  });

  final String maNguoiDung;
  final String hoTen;
  final double radius;
  final double fontSize;
  final Color mauNen;

  // maNguoiDung -> chuỗi ảnh gần nhất ('' = đã tra nhưng không có ảnh).
  static final Map<String, String> _cache = {};

  /// Giữ lại để tương thích code cũ. Không còn bắt buộc vì widget đã realtime.
  static void xoaCache([String? maNguoiDung]) {
    if (maNguoiDung == null) {
      _cache.clear();
    } else {
      _cache.remove(maNguoiDung);
    }
  }

  @override
  State<AnhDaiDienWidget> createState() => _AnhDaiDienWidgetState();
}

class _AnhDaiDienWidgetState extends State<AnhDaiDienWidget> {
  final AnhDaiDienService _service = AnhDaiDienService();

  StreamSubscription<String?>? _sub;
  String _anh = '';
  ImageProvider? _provider;
  String? _providerNguon;

  @override
  void initState() {
    super.initState();
    _batDau();
  }

  @override
  void didUpdateWidget(covariant AnhDaiDienWidget old) {
    super.didUpdateWidget(old);
    if (old.maNguoiDung != widget.maNguoiDung) _batDau();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _batDau() {
    _sub?.cancel();
    final id = widget.maNguoiDung;
    _anh = AnhDaiDienWidget._cache[id] ?? '';
    if (id.isEmpty) return;

    _sub = _service.theoDoiAnhDaiDien(id).listen(
      (s) {
        final moi = s ?? '';
        AnhDaiDienWidget._cache[id] = moi;
        if (mounted && moi != _anh) setState(() => _anh = moi);
      },
      onError: (Object e, StackTrace st) {
        debugPrint('AnhDaiDienWidget: lỗi theo dõi ảnh của "$id": $e');
      },
    );
  }

  ImageProvider? _giaiMa(String s) {
    if (s.isEmpty) return null;
    if (_providerNguon == s) return _provider;
    ImageProvider? p;
    try {
      if (s.startsWith('http')) {
        p = NetworkImage(s);
      } else {
        final raw = s.contains(',') ? s.substring(s.indexOf(',') + 1) : s;
        final Uint8List bytes =
            base64Decode(raw.replaceAll(RegExp(r'\s+'), ''));
        p = MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint('AnhDaiDienWidget: không giải mã được ảnh: $e');
      p = null;
    }
    _providerNguon = s;
    _provider = p;
    return p;
  }

  String _chuViet(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _giaiMa(_anh);
    if (provider != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.mauNen,
        backgroundImage: provider,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.mauNen,
      child: Text(
        _chuViet(widget.hoTen),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize,
        ),
      ),
    );
  }
}