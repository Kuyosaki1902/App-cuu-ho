import '../../../core/luong_truc_tiep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/ban_ghi.dart';
import '../models/chi_tiet_yeu_cau_model.dart';
import '../../../core/kiem_tra_quyen_ghi.dart';

abstract class NguonChiTietYeuCau {
  Stream<BanGhi?> watchRequest(String id);
  Stream<List<BanGhi>> watchSelected(String id);
  Stream<BanGhi?> watchPerson(String uid);
  Future<Map<String, dynamic>> helperProfile(String uid);
  Future<String> requestType(String id);
  Future<TrangBanGhi> records(
    String id,
    String kind, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  });
  Future<void> saveCheck(
    BanGhi request,
    BanGhi assignment,
    String outcome,
    String note,
  );
}

abstract class ChiTietYeuCauTrucTiep {
  Stream<Map<String, dynamic>> watchHelperProfile(String uid);
  Stream<String> watchRequestType(String id);
  Stream<TrangBanGhi> watchRecords(String id, String kind, int limit);
}

class ChiTietYeuCauService
    implements NguonChiTietYeuCau, ChiTietYeuCauTrucTiep {
  final FirebaseFirestore db;
  ChiTietYeuCauService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;
  @override
  Stream<BanGhi?> watchRequest(String id) => db
      .collection('YeuCauCuuHo')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? BanGhi.fromDoc(d) : null);
  @override
  Stream<List<BanGhi>> watchSelected(String id) => db
      .collectionGroup('DanhSachPhanCong')
      .where('maYeuCau', isEqualTo: id)
      .where('maTrangThaiTiepNhan', whereIn: selectedAssignmentCodes)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(BanGhi.fromDoc).toList());
  @override
  Stream<BanGhi?> watchPerson(String uid) => db
      .collection('NguoiDung')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? BanGhi.fromDoc(d) : null);

  @override
  Future<Map<String, dynamic>> helperProfile(String uid) async {
    final docs = await Future.wait([
      db
          .collection('HoSoCuuHoCoCCHN')
          .doc(uid)
          .get(const GetOptions(source: Source.server)),
      db
          .collection('HoSoCuuHoKhongCCHN')
          .doc(uid)
          .get(const GetOptions(source: Source.server)),
    ]);
    if (docs[0].exists) return {...docs[0].data()!, 'loaiHoSo': 'Có CCHN'};
    if (docs[1].exists) return {...docs[1].data()!, 'loaiHoSo': 'Không CCHN'};
    return {};
  }

  @override
  Future<String> requestType(String id) async {
    if (id.isEmpty || id.contains('/')) return '';
    final doc = await db
        .collection('LoaiYeuCau')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.data()?['tenLoaiYeuCau'] is String
        ? doc.data()!['tenLoaiYeuCau'] as String
        : '';
  }

  Query<Map<String, dynamic>> truyVanBanGhi(String id, String kind) {
    Query<Map<String, dynamic>> q;
    switch (kind) {
      case 'descriptions':
        q = db
            .collection('ChiTietMoTaHienTruong')
            .where('maYeuCau', isEqualTo: id);
      case 'requestImages':
        q = db.collection('LuuAnh').where('maYeuCau', isEqualTo: id);
      case 'images':
        q = db.collection('LuuAnh').where('maMoTa', isEqualTo: id);
      case 'invitations':
        q = db
            .collectionGroup('DanhSachPhanCong')
            .where('maYeuCau', isEqualTo: id);
      case 'reviews':
        q = db
            .collectionGroup('DanhSachYeuCau')
            .where('maYeuCau', isEqualTo: id);
      case 'logs':
        q = db.collection('YeuCauCuuHo').doc(id).collection('NhatKyKiemTra');
      default:
        throw ArgumentError('Loại dữ liệu không hợp lệ.');
    }
    if (kind == 'logs') q = q.orderBy('thoiGian', descending: true);
    q = q.orderBy(FieldPath.documentId, descending: kind == 'logs');
    return q;
  }

  @override
  Stream<TrangBanGhi> watchRecords(String id, String kind, int limit) {
    if (kind == 'descriptions') {
      return gopLuong<dynamic>([
        db.collection('ChiTietMoTaHienTruong').doc(id).snapshots(),
        db
            .collection('ChiTietMoTaHienTruong')
            .where('maYeuCau', isEqualTo: id)
            .limit(limit + 1)
            .snapshots(),
      ]).map((values) {
        final direct = values[0] as DocumentSnapshot<Map<String, dynamic>>;
        final queried = values[1] as QuerySnapshot<Map<String, dynamic>>;
        final records = <String, BanGhi>{};
        if (direct.exists) {
          final row = BanGhi.fromDoc(direct);
          records[row.id] = row;
        }
        for (final doc in queried.docs) {
          final row = BanGhi.fromDoc(doc);
          records[row.id] = row;
        }
        final rows = records.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        return TrangBanGhi(
          rows.take(limit).toList(),
          null,
          rows.length > limit || queried.docs.length > limit,
        );
      });
    }

    if (kind == 'requestImages') {
      return gopLuong<dynamic>([
        db
            .collection('LuuAnh')
            .where('maYeuCau', isEqualTo: id)
            .limit(limit + 1)
            .snapshots(),
        db
            .collection('LuuAnh')
            .where('maMoTa', isEqualTo: id)
            .limit(limit + 1)
            .snapshots(),
        db.collection('ChiTietMoTaHienTruong').doc(id).snapshots(),
      ]).map((values) {
        final byRequest = values[0] as QuerySnapshot<Map<String, dynamic>>;
        final byDescription = values[1] as QuerySnapshot<Map<String, dynamic>>;
        final description = values[2] as DocumentSnapshot<Map<String, dynamic>>;
        final records = <String, BanGhi>{};
        final sources = <String>{};
        for (final doc in [...byRequest.docs, ...byDescription.docs]) {
          final row = BanGhi.fromDoc(doc);
          final source = _mediaSource(row.data);
          if (source.isNotEmpty && !sources.add(source)) continue;
          records[row.id] = row;
        }

        final descriptionData = description.data() ?? <String, dynamic>{};
        final legacyMedia = descriptionData['videoUrl'];
        final legacyMime =
            (descriptionData['contentType'] ??
                    descriptionData['mimeType'] ??
                    '')
                .toString()
                .toLowerCase();
        final mimeIsNonImage =
            legacyMime.startsWith('video/') ||
            legacyMime.startsWith('audio/') ||
            legacyMime.startsWith('application/') ||
            legacyMime.startsWith('text/');
        if (legacyMedia is String &&
            legacyMedia.trim().isNotEmpty &&
            !mimeIsNonImage &&
            !_isNonImageMedia(legacyMedia) &&
            !sources.contains(legacyMedia.trim())) {
          final fallback = legacyMedia.trim();
          records['legacy-media-$id'] = BanGhi('legacy-media-$id', {
            'maAnh': 'legacy-media-$id',
            'maYeuCau': id,
            'maPhanLoaiAnh': 'phanloaianh_hientruong',
            'anhURL': fallback,
          });
        }

        final rows = records.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        final hasMore =
            byRequest.docs.length > limit ||
            byDescription.docs.length > limit ||
            rows.length > limit;
        return TrangBanGhi(rows.take(limit).toList(), null, hasMore);
      });
    }

    if (kind == 'reviews') return _watchRequestReviews(id, limit);

    return truyVanBanGhi(id, kind)
        .limit(limit + 1)
        .snapshots()
        .map(
          (page) => TrangBanGhi(
            page.docs.take(limit).map(BanGhi.fromDoc).toList(),
            null,
            page.docs.length > limit,
          ),
        );
  }

  Stream<TrangBanGhi> _watchRequestReviews(String id, int limit) async* {
    try {
      await for (final page in truyVanBanGhi(
        id,
        'reviews',
      ).limit(limit + 1).snapshots()) {
        yield TrangBanGhi(
          page.docs.take(limit).map(BanGhi.fromDoc).toList(),
          null,
          page.docs.length > limit,
        );
      }
    } on FirebaseException catch (error) {
      if (!_missingReviewIndex(error)) rethrow;
      yield await _reviewsWithoutIndex(id, limit);
    }
  }

  bool _missingReviewIndex(FirebaseException error) =>
      error.code == 'failed-precondition' &&
      (error.message?.toLowerCase().contains('index') ?? false);

  Future<TrangBanGhi> _reviewsWithoutIndex(
    String id,
    int limit, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    final parents = await db
        .collection('DanhGia')
        .get(const GetOptions(source: Source.server));
    final reviews = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final parent in parents.docs) {
      final page = await parent.reference
          .collection('DanhSachYeuCau')
          .where('maYeuCau', isEqualTo: id)
          .get(const GetOptions(source: Source.server));
      reviews.addAll(page.docs);
    }
    reviews.sort((a, b) => a.reference.path.compareTo(b.reference.path));
    final cursorIndex = after == null
        ? -1
        : reviews.indexWhere(
            (doc) => doc.reference.path == after.reference.path,
          );
    final start = cursorIndex + 1;
    final visible = reviews.skip(start).take(limit).toList();
    return TrangBanGhi(
      visible.map(BanGhi.fromDoc).toList(),
      visible.isEmpty ? after : visible.last,
      start + visible.length < reviews.length,
    );
  }

  bool _isNonImageMedia(String source) {
    final normalized = source.trim().toLowerCase();
    if (normalized.startsWith('data:video/') ||
        normalized.startsWith('data:audio/') ||
        normalized.startsWith('data:application/')) {
      return true;
    }
    final value = normalized.split('?').first;
    return RegExp(
      r'\.(mp4|mov|m4v|webm|mkv|avi|3gp|m3u8|m4a|mp3|wav|aac|ogg|opus|amr|flac|pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|zip|rar|7z)$',
    ).hasMatch(value);
  }

  String _mediaSource(Map<String, dynamic> data) {
    for (final key in [
      'anhURL',
      'fileURL',
      'fileUrl',
      'tepTinUrl',
      'taiLieuUrl',
      'duongDanTep',
      'attachmentUrl',
      'urlFile',
      'duongDan',
      'base64Image',
      'anhBase64',
      'base64',
    ]) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  @override
  Stream<Map<String, dynamic>> watchHelperProfile(String uid) =>
      gopLuong([
        db.collection('HoSoCuuHoCoCCHN').doc(uid).snapshots(),
        db.collection('HoSoCuuHoKhongCCHN').doc(uid).snapshots(),
      ]).map((docs) {
        if (docs[0].exists) return {...docs[0].data()!, 'loaiHoSo': 'Có CCHN'};
        if (docs[1].exists) {
          return {...docs[1].data()!, 'loaiHoSo': 'Không CCHN'};
        }
        return <String, dynamic>{};
      });

  @override
  Stream<String> watchRequestType(String id) {
    if (id.isEmpty || id.contains('/')) return Stream.value('');
    return db.collection('LoaiYeuCau').doc(id).snapshots().map((doc) {
      final value = doc.data()?['tenLoaiYeuCau'];
      return value is String ? value : '';
    });
  }

  @override
  Future<TrangBanGhi> records(
    String id,
    String kind, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    var q = truyVanBanGhi(id, kind).limit(10);
    if (after != null) q = q.startAfterDocument(after);
    try {
      final page = await q.get(const GetOptions(source: Source.server));
      return TrangBanGhi(
        page.docs.map(BanGhi.fromDoc).toList(),
        page.docs.isEmpty ? after : page.docs.last,
        page.docs.length == 10,
      );
    } on FirebaseException catch (error) {
      if (kind != 'reviews' || !_missingReviewIndex(error)) rethrow;
      return _reviewsWithoutIndex(id, 10, after: after);
    }
  }

  @override
  Future<void> saveCheck(
    BanGhi request,
    BanGhi assignment,
    String outcome,
    String note,
  ) async {
    validateCheckResult(outcome, note);
    final actor = currentAdminUid();
    final ref = db.collection('YeuCauCuuHo').doc(request.id);
    final path = assignment.path;
    if (path == null)
      throw StateError('Chưa có bản ghi phân công để kiểm tra.');
    final assignmentRef = db.doc(path);
    final day = assignmentRef.parent.parent!.id;
    await db.runTransaction((tx) async {
      final admin = await tx.get(db.collection('Admin').doc(actor));
      final fresh = await tx.get(ref);
      final selected = await tx.get(assignmentRef);
      if (admin.data()?['trangThai'] != 'hoat_dong') {
        throw StateError('Không có quyền Admin.');
      }
      if (!fresh.exists) throw StateError('Yêu cầu không còn tồn tại.');
      final d = fresh.data()!;
      if (!reviewableRequest(d['maTinhTrangYeuCau'])) {
        throw StateError('Ca không ở trạng thái có thể kiểm tra.');
      }
      final owner = d['maAdminDieuPhoi'];
      if (owner is String && owner.isNotEmpty && owner != actor) {
        throw StateError('Ca đang do Admin khác phụ trách.');
      }
      if (d['maTinhTrangYeuCau'] != request.data['maTinhTrangYeuCau'] ||
          (d['phienBanKiemTra'] ?? 0) !=
              (request.data['phienBanKiemTra'] ?? 0)) {
        throw StateError('Ca đã thay đổi. Hãy tải lại trước khi lưu.');
      }
      final a = selected.data();
      if (a == null ||
          a['maPhanCong'] != assignment.id ||
          a['maYeuCau'] != request.id ||
          !selectedAssignmentCodes.contains(a['maTrangThaiTiepNhan']) ||
          a['maNguoiCuuHo'] != assignment.data['maNguoiCuuHo']) {
        throw StateError(
          'Phân công đã thay đổi. Hãy kiểm tra lại người phụ trách.',
        );
      }
      final version = ((d['phienBanKiemTra'] ?? 0) as num).toInt() + 1;
      final log = ref
          .collection('NhatKyKiemTra')
          .doc('kiemtra_v${version.toString().padLeft(6, '0')}');
      final change = {
        'ketQuaKiemTra': outcome,
        'ghiChuKiemTra': note.trim(),
        'maAdminKiemTra': actor,
        'ngayKiemTra': FieldValue.serverTimestamp(),
        'maPhanCongKiemTra': assignment.id,
        'maNhatKyKiemTra': log.id,
        'phienBanKiemTra': version,
        'canKiemTra': false,
        'canBoSungNhanLuc':
            outcome == 'can_thay_nguoi' || d['canBoSungNhanLuc'] == true,
      };
      tx.update(ref, change);
      tx.set(log, {
        'maAdmin': actor,
        'maPhanCong': assignment.id,
        'ngayPhanCong': day,
        'maNguoiCuuHo': a['maNguoiCuuHo'],
        'ketQua': outcome,
        'ghiChu': note.trim(),
        'thoiGian': FieldValue.serverTimestamp(),
        'phienBan': version,
      });
    });
  }
}
