// lib/user/BangXepHangCuuHo/controllers/bang_xep_hang_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';

// =============================================================================
// MODEL HIỂN THỊ
// =============================================================================
class RescuerLeaderboardItemModel {
  final int rank;
  final NguoiDungModel user;
  final int casesCount;
  final String specialty;
  final String organization;
  final double rating;
  final int reviewsCount;
  final String? avatarRaw;

  /// Mã kỹ năng của cứu hộ viên (ChiTietKyNang/{uid}/DanhSachKyNang) - dùng để lọc
  final List<String> skillIds;

  RescuerLeaderboardItemModel({
    required this.rank,
    required this.user,
    required this.casesCount,
    required this.specialty,
    required this.organization,
    required this.rating,
    required this.reviewsCount,
    this.avatarRaw,
    this.skillIds = const [],
  });

  RescuerLeaderboardItemModel copyWithRank(int newRank) =>
      RescuerLeaderboardItemModel(
        rank: newRank,
        user: user,
        casesCount: casesCount,
        specialty: specialty,
        organization: organization,
        rating: rating,
        reviewsCount: reviewsCount,
        avatarRaw: avatarRaw,
        skillIds: skillIds,
      );
}

class KyNangOption {
  final String ma;
  final String ten;
  final String nhom; // key nhóm: kynangcoban / kynangtuhoc / ''
  final String tenNhom;

  const KyNangOption({
    required this.ma,
    required this.ten,
    required this.nhom,
    required this.tenNhom,
  });
}

/// Các lựa chọn của nút lọc: lấy từ toàn bộ hồ sơ / danh mục kỹ năng,
/// KHÔNG phụ thuộc tab đang xem (tab ít người vẫn thấy đủ lựa chọn).
class LeaderboardFilterOptions {
  final List<String> specialties;
  final List<KyNangOption> skills;

  const LeaderboardFilterOptions({
    required this.specialties,
    required this.skills,
  });
}

// Hồ sơ rút gọn, đọc thẳng từ Map nên không phụ thuộc phiên bản model hồ sơ
class _HoSoTomTat {
  final String uid;
  final String loai; // cchn | khongcchn
  final String specialty;
  final String organization;
  final double rating;
  final int reviewsCount;
  final int tongCaHoanThanh;

  _HoSoTomTat({
    required this.uid,
    required this.loai,
    required this.specialty,
    required this.organization,
    required this.rating,
    required this.reviewsCount,
    required this.tongCaHoanThanh,
  });
}

class _DongXepHang {
  final String uid;
  final int soCa;
  final String loaiHoSo;
  _DongXepHang(this.uid, this.soCa, this.loaiHoSo);
}

// =============================================================================
// CONTROLLER
// =============================================================================
class BangXepHangController {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, _HoSoTomTat>? _profileCache;

  // Hồ sơ ở các trạng thái này chưa/không đủ điều kiện xuất hiện trên bảng xếp hạng
  static const Set<String> _trangThaiKhongXepHang = {
    'cuuho_trangthai_hoso_tiepnhan',
    'cuuho_trangthai_hoso_dangthamdinh',
    'cuuho_trangthai_hoso_canbosung',
    'cuuho_trangthai_hoso_tuchoi',
    'cuuho_trangthai_hoso_tamkhoa',
    'CHO_DUYET',
  };

  // ---------------------------------------------------------------------------
  // Tiện ích parse an toàn (soLuongCaHoanThanh có thể là int HOẶC Map {tuan,thang,tatCa})
  // ---------------------------------------------------------------------------
  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Map) return _toInt(v['tatCa']);
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static String _uidOf(Map<String, dynamic> d, String docId) {
    final f = (d['maNguoiDung'] ?? '').toString().trim();
    return f.isNotEmpty ? f : docId;
  }

  // ---------------------------------------------------------------------------
  // Làm mới dữ liệu đệm
  // ---------------------------------------------------------------------------
  void refresh() {
    _profileCache = null;
  }

  // ---------------------------------------------------------------------------
  // HỒ SƠ: đọc 1 lần cả 2 collection, dùng cho mọi tab
  // ---------------------------------------------------------------------------
  Future<Map<String, _HoSoTomTat>> _loadProfiles() async {
    if (_profileCache != null) return _profileCache!;

    final snaps = await Future.wait([
      _firebaseService.getHoSoCoCCHNSnapshot(),
      _firebaseService.getHoSoKhongCCHNSnapshot(),
    ]);

    final map = <String, _HoSoTomTat>{};

    for (final doc in snaps[0].docs) {
      final d = doc.data();
      final status = (d['maTrangThaiHoSo'] ?? '').toString();
      if (_trangThaiKhongXepHang.contains(status)) continue;

      final uid = _uidOf(d, doc.id);
      final tenCN = (d['tenChuyenNganh'] ?? '').toString().trim();
      final chucDanh = (d['chucDanh'] ?? '').toString().trim();
      final donVi = (d['donViCongTac'] ?? '').toString().trim();

      map[uid] = _HoSoTomTat(
        uid: uid,
        loai: 'cchn',
        specialty: tenCN.isNotEmpty
            ? tenCN
            : (chucDanh.isNotEmpty ? chucDanh : 'Cứu hộ Y tế'),
        organization: donVi.isNotEmpty ? donVi : 'Đội Cứu hộ Y tế',
        rating: _toDouble(d['diemDanhGia']),
        reviewsCount: _toInt(d['tongLuotDanhGia']),
        tongCaHoanThanh: _toInt(d['soLuongCaHoanThanh']),
      );
    }

    for (final doc in snaps[1].docs) {
      final d = doc.data();
      final status = (d['maTrangThaiHoSo'] ?? '').toString();
      if (_trangThaiKhongXepHang.contains(status)) continue;

      final uid = _uidOf(d, doc.id);
      if (map.containsKey(uid)) continue; // đã có hồ sơ CCHN thì ưu tiên CCHN

      final doiNhom = (d['doiNhom'] ?? '').toString().trim();
      map[uid] = _HoSoTomTat(
        uid: uid,
        loai: 'khongcchn',
        specialty: 'Cứu hộ & Hỗ trợ cộng đồng',
        organization: doiNhom.isNotEmpty ? doiNhom : 'Tình nguyện viên Cứu hộ',
        rating: _toDouble(d['diemDanhGia']),
        reviewsCount: _toInt(d['tongLuotDanhGia']),
        tongCaHoanThanh: _toInt(d['soLuongCaHoanThanh']),
      );
    }

    _profileCache = map;
    return map;
  }

  // ---------------------------------------------------------------------------
  // LỰA CHỌN CHO NÚT LỌC
  // ---------------------------------------------------------------------------
  Future<LeaderboardFilterOptions> loadFilterOptions() async {
    final profiles = await _loadProfiles();
    final specialties =
        profiles.values
            .map((p) => p.specialty)
            .where((s) => s.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    List<KyNangOption> skills = [];
    try {
      final catalog = await _firebaseService.getDanhMucKyNang();
      skills = catalog
          .map(
            (k) => KyNangOption(
              ma: k['ma'] ?? '',
              ten: k['ten'] ?? '',
              nhom: k['nhom'] ?? '',
              tenNhom: k['tenNhom'] ?? 'Khác',
            ),
          )
          .where((k) => k.ma.isNotEmpty)
          .toList();
    } catch (_) {}

    return LeaderboardFilterOptions(specialties: specialties, skills: skills);
  }

  /// Lọc: trong cùng nhóm là HOẶC (chọn 1 trong các mục), giữa 2 nhóm là VÀ.
  static List<RescuerLeaderboardItemModel> applyFilters(
    List<RescuerLeaderboardItemModel> list, {
    required Set<String> specialties,
    required Set<String> skills,
  }) {
    return list.where((item) {
      if (specialties.isNotEmpty && !specialties.contains(item.specialty)) {
        return false;
      }
      if (skills.isNotEmpty && !item.skillIds.any(skills.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // BẢNG XẾP HẠNG
  // ---------------------------------------------------------------------------
  /// selectedTab: 0 = tuần, 1 = tháng, 2 = tất cả
  Future<List<RescuerLeaderboardItemModel>> fetchLeaderboard(
    int selectedTab, {
    DateTime? targetDate,
  }) async {
    final profiles = await _loadProfiles();
    final rows = <_DongXepHang>[];

    if (selectedTab == 2) {
      // TẤT CẢ: số ca = tổng ca hoàn thành trong hồ sơ
      for (final p in profiles.values) {
        rows.add(_DongXepHang(p.uid, p.tongCaHoanThanh, p.loai));
      }
    } else {
      final date = targetDate ?? DateTime.now();
      final kyId = _firebaseService.taoMaKyXepHang(
        date,
        isThang: selectedTab == 1,
      );
      final thanhVien = await _firebaseService.layThanhVienXepHangKy(kyId);
      final seen = <String>{};
      for (final tv in thanhVien) {
        final uid = (tv['maNguoiDung'] ?? '').toString().trim();
        if (uid.isEmpty || !seen.add(uid)) continue;
        rows.add(
          _DongXepHang(
            uid,
            (tv['soCaHoanThanh'] as int?) ?? 0,
            (tv['loaiHoSo'] ?? '').toString(),
          ),
        );
      }
    }

    return _buildItems(rows, profiles);
  }

  Future<List<RescuerLeaderboardItemModel>> _buildItems(
    List<_DongXepHang> rows,
    Map<String, _HoSoTomTat> profiles,
  ) async {
    if (rows.isEmpty) return [];

    final userMap = await _loadUserMap(rows.map((r) => r.uid).toSet());

    final built = await Future.wait(
      rows.map((r) async {
        final user = userMap[r.uid];
        if (user == null) return null;

        // chạy song song avatar + kỹ năng
        final avatarF = _firebaseService.getUserAvatarUrl(r.uid);
        final skillsF = _firebaseService.getSkillIdsByUserId(r.uid);
        final avatar = await avatarF;
        final skills = await skillsF;

        final hs = profiles[r.uid];
        return RescuerLeaderboardItemModel(
          rank: 0,
          user: user,
          casesCount: r.soCa,
          specialty: hs?.specialty ?? 'Cứu hộ & Hỗ trợ cộng đồng',
          organization: hs?.organization ?? 'Đội ngũ cứu hộ',
          rating: hs?.rating ?? 0.0,
          reviewsCount: hs?.reviewsCount ?? 0,
          avatarRaw: avatar,
          skillIds: skills,
        );
      }),
    );

    final items = built.whereType<RescuerLeaderboardItemModel>().toList()
      ..sort((a, b) => b.casesCount.compareTo(a.casesCount));

    return List.generate(items.length, (i) => items[i].copyWithRank(i + 1));
  }

  // ---------------------------------------------------------------------------
  // Nạp thông tin người dùng (doc id hoặc trường maNguoiDung đều khớp được)
  // ---------------------------------------------------------------------------
  Future<Map<String, NguoiDungModel>> _loadUserMap(Set<String> userIds) async {
    final Map<String, NguoiDungModel> userMap = {};
    final List<String> idList = userIds.toList();

    void addDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = Map<String, dynamic>.from(doc.data());
      final String fieldUid = (data['maNguoiDung'] ?? '').toString().trim();
      final String resolvedId = fieldUid.isNotEmpty ? fieldUid : doc.id;
      data['maNguoiDung'] = resolvedId;
      final model = NguoiDungModel.fromMap(data);
      userMap[doc.id] = model;
      userMap[resolvedId] = model;
    }

    for (var i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(
        i,
        i + 30 > idList.length ? idList.length : i + 30,
      );

      final byDocId = await _firestore
          .collection('NguoiDung')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      byDocId.docs.forEach(addDoc);

      final missing = chunk.where((id) => !userMap.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        final byField = await _firestore
            .collection('NguoiDung')
            .where('maNguoiDung', whereIn: missing)
            .get();
        byField.docs.forEach(addDoc);
      }
    }
    return userMap;
  }
}
