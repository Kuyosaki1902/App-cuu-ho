// lib/user/HuongDanCuuHo/controllers/huong_dan_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/videohuongdanmodel.dart';
import 'package:flutter/material.dart';

class HuongDanController {
  static const String tatCa = 'Tất cả';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Dữ liệu hiển thị ----
  final ValueNotifier<List<VideoHuongDanModel>> filteredVideosNotifier =
      ValueNotifier([]);

  /// Chip danh mục (lấy từ trường danhMuc của Firestore), luôn có 'Tất cả' đầu tiên
  final ValueNotifier<List<String>> categoriesNotifier = ValueNotifier([tatCa]);
  final ValueNotifier<String> selectedCategoryNotifier = ValueNotifier(tatCa);

  /// Bộ lọc phụ theo mức độ (trường nhanKhanCap), mở bằng nút "tune" ở ô tìm kiếm
  final ValueNotifier<List<String>> nhanOptionsNotifier = ValueNotifier([]);
  final ValueNotifier<String?> selectedNhanNotifier = ValueNotifier(null);

  // ---- Trạng thái ----
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);

  /// null = không lỗi. Có giá trị = hiện màn hình lỗi + nút "Thử lại"
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  List<VideoHuongDanModel> _allVideos = [];
  List<String> _queryTokens = [];
  bool _disposed = false;

  /// Tổng số video đang có trên Firestore (hiện ở chip "Tất cả (N)")
  int get totalCount => _allVideos.length;

  /// Khóa so sánh: bỏ dấu, chữ thường, gộp khoảng trắng
  /// ("Hô hấp & CPR" và "hô hấp &  cpr" được coi là một danh mục).
  String _key(String s) =>
      boDauTiengViet(s).trim().replaceAll(RegExp(r'\s+'), ' ');

  // ===========================================================================
  // TẢI DỮ LIỆU TỪ FIRESTORE: collection 'VideoHuongDan'
  // ===========================================================================
  /// [silent] = true khi kéo để làm mới: không bật vòng xoay toàn màn hình.
  Future<void> loadVideos({bool silent = false}) async {
    if (!silent) isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final snap = await _fetch();
      if (_disposed) return;

      final all = snap.docs
          .map((d) => VideoHuongDanModel.fromMap(d.data(), d.id))
          .toList();
      final hopLe = all.where((v) => v.hopLe).toList();

      debugPrint(
        '📚 VideoHuongDan: ${snap.docs.length} doc, ${hopLe.length} hợp lệ '
        '(fromCache=${snap.metadata.isFromCache})',
      );
      for (final v in all.where((v) => !v.hopLe)) {
        debugPrint(
          '   ⚠️ Bỏ qua ${v.maVideo}: kichHoat=${v.kichHoat}, youtubeId="${v.youtubeId}"',
        );
      }

      if (snap.metadata.isFromCache && snap.docs.isEmpty) {
        // Không có mạng và chưa có dữ liệu đệm -> báo lỗi chứ không báo "chưa có video"
        _setError('Không có kết nối mạng. Hãy kiểm tra mạng rồi thử lại.');
      } else {
        _allVideos = _sorted(hopLe);
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ VideoHuongDan [${e.code}]: ${e.message}');
      _setError(
        e.code == 'permission-denied'
            ? 'Không có quyền đọc dữ liệu video (kiểm tra Firestore Rules).'
            : 'Không tải được video hướng dẫn (${e.code}).',
      );
    } catch (e) {
      debugPrint('❌ VideoHuongDan: $e');
      _setError('Không tải được video hướng dẫn. Vui lòng thử lại.');
    }

    if (_disposed) return;
    _rebuildFilters();
    _applyFilter();
    isLoadingNotifier.value = false;
  }

  Future<void> refresh() => loadVideos(silent: true);

  void _setError(String message) {
    // Đang có dữ liệu cũ thì giữ nguyên danh sách, chỉ báo lỗi khi chưa có gì để hiện
    if (_allVideos.isEmpty) errorNotifier.value = message;
  }

  // Không dùng orderBy của Firestore vì nó LOẠI các doc thiếu trường thuTuUuTien.
  // Mạng yếu: chờ máy chủ tối đa 8s rồi đọc bộ nhớ đệm của Firestore.
  Future<QuerySnapshot<Map<String, dynamic>>> _fetch() async {
    final col = _firestore.collection('VideoHuongDan');
    try {
      return await col.get().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return await col.get(const GetOptions(source: Source.cache));
    }
  }

  List<VideoHuongDanModel> _sorted(List<VideoHuongDanModel> list) {
    final copy = [...list];
    copy.sort((a, b) {
      final byOrder = a.thuTuUuTien.compareTo(b.thuTuUuTien);
      return byOrder != 0 ? byOrder : a.tieuDe.compareTo(b.tieuDe);
    });
    return copy;
  }

  // Dựng danh sách chip + tùy chọn lọc từ chính dữ liệu Firestore
  void _rebuildFilters() {
    final cats = <String>[tatCa];
    final catKeys = <String>{};
    final nhans = <String>[];
    final nhanKeys = <String>{};

    for (final v in _allVideos) {
      final c = v.danhMuc.trim();
      if (c.isNotEmpty && catKeys.add(_key(c))) cats.add(c);

      final n = v.nhanKhanCap.trim();
      if (n.isNotEmpty && nhanKeys.add(_key(n))) nhans.add(n);
    }

    categoriesNotifier.value = cats;
    nhanOptionsNotifier.value = nhans;

    final selCat = selectedCategoryNotifier.value;
    if (selCat != tatCa && !catKeys.contains(_key(selCat))) {
      selectedCategoryNotifier.value = tatCa;
    }
    final selNhan = selectedNhanNotifier.value;
    if (selNhan != null && !nhanKeys.contains(_key(selNhan))) {
      selectedNhanNotifier.value = null;
    }
  }

  // ===========================================================================
  // BỘ LỌC
  // ===========================================================================
  void selectCategory(String category) {
    selectedCategoryNotifier.value = category;
    _applyFilter();
  }

  /// null = bỏ lọc theo mức độ
  void selectNhan(String? nhan) {
    selectedNhanNotifier.value = nhan;
    _applyFilter();
  }

  void updateSearchQuery(String query) {
    // Bỏ dấu + tách từ: "cam mau" tìm được "Cầm máu"; mọi từ phải cùng khớp
    _queryTokens = boDauTiengViet(
      query,
    ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    _applyFilter();
  }

  void _applyFilter() {
    if (_disposed) return;
    final selCat = selectedCategoryNotifier.value;
    final selNhan = selectedNhanNotifier.value;
    final catKey = selCat == tatCa ? null : _key(selCat);
    final nhanKey = selNhan == null ? null : _key(selNhan);

    filteredVideosNotifier.value = _allVideos.where((v) {
      if (catKey != null && _key(v.danhMuc) != catKey) return false;
      if (nhanKey != null && _key(v.nhanKhanCap) != nhanKey) return false;
      return _queryTokens.every(v.searchText.contains);
    }).toList();
  }

  void dispose() {
    _disposed = true;
    filteredVideosNotifier.dispose();
    categoriesNotifier.dispose();
    selectedCategoryNotifier.dispose();
    nhanOptionsNotifier.dispose();
    selectedNhanNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
  }
}
