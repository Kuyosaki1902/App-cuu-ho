// lib/NguoiCuuHo/LuuAnh/anh_dai_dien_widget.dart
//
// Widget avatar dùng chung: tự truy vấn ảnh đại diện qua AnhDaiDienService,
// có cache trong bộ nhớ và tự rơi về chữ cái viết tắt khi chưa có ảnh.
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

  // Cache: maNguoiDung -> chuỗi ảnh ('' nghĩa là đã tra nhưng không có ảnh).
  static final Map<String, String> _cache = {};
  static final ValueNotifier<int> _phienBan = ValueNotifier<int>(0);

  /// Gọi sau khi người dùng đổi/xóa ảnh đại diện để các avatar tải lại.
  static void xoaCache([String? maNguoiDung]) {
    if (maNguoiDung == null) {
      _cache.clear();
    } else {
      _cache.remove(maNguoiDung);
    }
    _phienBan.value++;
  }

  @override
  State<AnhDaiDienWidget> createState() => _AnhDaiDienWidgetState();
}

class _AnhDaiDienWidgetState extends State<AnhDaiDienWidget> {
  final AnhDaiDienService _service = AnhDaiDienService();

  Future<String>? _future;
  ImageProvider? _provider;
  String? _providerNguon;

  @override
  void initState() {
    super.initState();
    AnhDaiDienWidget._phienBan.addListener(_taiLai);
    _future = _tai();
  }

  @override
  void didUpdateWidget(covariant AnhDaiDienWidget old) {
    super.didUpdateWidget(old);
    if (old.maNguoiDung != widget.maNguoiDung) _taiLai();
  }

  @override
  void dispose() {
    AnhDaiDienWidget._phienBan.removeListener(_taiLai);
    super.dispose();
  }

  void _taiLai() {
    if (!mounted) return;
    setState(() => _future = _tai());
  }

  Future<String> _tai() async {
    final id = widget.maNguoiDung;
    if (id.isEmpty) return '';
    final daCo = AnhDaiDienWidget._cache[id];
    if (daCo != null) return daCo;
    try {
      final s = await _service.layAnhDaiDien(id) ?? '';
      AnhDaiDienWidget._cache[id] = s;
      return s;
    } catch (_) {
      return ''; // lỗi mạng: không cache để lần sau thử lại
    }
  }

  ImageProvider? _giaiMa(String s) {
    if (s.isEmpty) return null;
    if (_providerNguon == s) return _provider; // tránh decode lại mỗi lần build
    ImageProvider? p;
    try {
      if (s.startsWith('http')) {
        p = NetworkImage(s);
      } else {
        final raw = s.contains(',') ? s.substring(s.indexOf(',') + 1) : s;
        final Uint8List bytes = base64Decode(raw.trim());
        p = MemoryImage(bytes);
      }
    } catch (_) {
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
    final chuViet = CircleAvatar(
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

    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        final provider = _giaiMa(snap.data ?? '');
        if (provider == null) return chuViet;
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.mauNen,
          backgroundImage: provider,
          onBackgroundImageError: (_, __) {},
        );
      },
    );
  }
}
