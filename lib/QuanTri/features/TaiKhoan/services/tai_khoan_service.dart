import 'dart:async';
import '../../../core/luong_truc_tiep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/tai_khoan_model.dart';
import '../../../models/trang_du_lieu.dart';
import '../../../models/ban_ghi.dart';
import '../../YeuCauHoTro/models/chi_tiet_yeu_cau_model.dart';
import '../../YeuCauHoTro/models/yeu_cau_ho_tro_model.dart';

abstract class NguonTaiKhoan {
  Future<List<TaiKhoan>> allAccounts();
  Future<Map<String, String>> roles();
  Future<TaiKhoan> get(String uid);
  Future<void> action(TaiKhoan account, String action, String reason);
  Future<TrangBanGhi> records(
    String uid,
    String kind, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  });
  Future<BanGhi?> sos(String id);
}

abstract class TaiKhoanPhanTrang {
  Future<TrangDuLieu<TaiKhoan>> page({Object? after});
}

abstract class TaiKhoanTrucTiep {
  Stream<TrangDuLieu<TaiKhoan>> watchPage(int limit);
  Stream<TaiKhoan> watchAccount(String uid);
  Stream<Map<String, String>> watchRoles();
  Stream<TrangBanGhi> watchRecords(String uid, String kind, int limit);
  Stream<List<BanGhi>> watchCurrentCases(String uid);
}

class TaiKhoanService
    implements NguonTaiKhoan, TaiKhoanPhanTrang, TaiKhoanTrucTiep {
  final FirebaseFirestore db;
  TaiKhoanService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;

  // Exclude the fixed NguoiDung/admin chat mirror at Firestore query time.
  // This avoids downloading it or its three auxiliary profiles on the list.
  Query<Map<String, dynamic>> _manageableAccounts() => db
      .collection('NguoiDung')
      .where(FieldPath.documentId, isNotEqualTo: 'admin')
      .orderBy(FieldPath.documentId);

  bool _manageableDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      TaiKhoan(doc.id, doc.data() ?? const {}, null, null).isManageableAccount;

  @override
  Stream<TaiKhoan> watchAccount(String uid) {
    if (uid.trim().toLowerCase() == 'admin') {
      return Stream<TaiKhoan>.error(
        StateError('Hồ sơ Admin dành riêng cho chat, không quản lý tài khoản.'),
      );
    }
    return gopLuong([
      db.collection('NguoiDung').doc(uid).snapshots(),
      db.collection('HoSoCuuHoCoCCHN').doc(uid).snapshots(),
      db.collection('HoSoCuuHoKhongCCHN').doc(uid).snapshots(),
      db.collection('HanCheNguoiDung').doc(uid).snapshots(),
    ]).map((docs) {
      if (!docs[0].exists) throw StateError('Tài khoản không còn tồn tại.');
      final account = TaiKhoan(
        uid,
        docs[0].data()!,
        docs[1].data(),
        docs[2].data(),
        restrictions: docs[3].data() ?? {},
      );
      if (!account.isManageableAccount) {
        throw StateError('Hồ sơ Admin dành riêng cho chat.');
      }
      return account;
    });
  }

  @override
  Stream<TrangDuLieu<TaiKhoan>> watchPage(int limit) => chuyenLuong(
    _manageableAccounts().limit(limit + 1).snapshots(),
    // Avoid three persistent listeners for every account list row.
    // The full watchAccount() remains realtime in the detail screen.
    (page) => Stream.fromFuture(
      taiTheoNhom(
        page.docs.take(limit).where(_manageableDoc),
        hydrate,
      ).then((items) => TrangDuLieu(items, null, page.docs.length > limit)),
    ),
  );

  @override
  Stream<Map<String, String>> watchRoles() => db
      .collection('VaiTro')
      .snapshots()
      .map(
        (page) => {
          for (final doc in page.docs)
            doc.id: textOf(doc.data(), 'vaiTro', doc.id),
        },
      );

  @override
  Stream<TrangBanGhi> watchRecords(String uid, String kind, int limit) =>
      truyVanBanGhi(uid, kind)
          .limit(limit + 1)
          .snapshots()
          .map(
            (page) => TrangBanGhi(
              page.docs
                  .take(limit)
                  .where(
                    (doc) => kind != 'sent' || maNanNhan(doc.data()) == uid,
                  )
                  .map(BanGhi.fromDoc)
                  .toList(),
              null,
              page.docs.length > limit,
            ),
          );

  Stream<String> _ngayVietNam() {
    late final StreamController<String> days;
    Timer? timer;
    void tick() {
      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
      days.add(now.toIso8601String().substring(0, 10));
      final midnight = DateTime.utc(now.year, now.month, now.day + 1);
      timer = Timer(midnight.difference(now), tick);
    }

    days = StreamController<String>(
      onListen: tick,
      onCancel: () {
        timer?.cancel();
      },
    );
    return days.stream;
  }

  @override
  Stream<List<BanGhi>> watchCurrentCases(String uid) => chuyenLuong(
    chuyenLuong(
      _ngayVietNam(),
      (day) => db
          .collection('ChiTietPhanCongCuuHo')
          .doc(uid)
          .collection('DanhSachNgay')
          .doc(day)
          .collection('DanhSachPhanCong')
          .snapshots(),
    ),
    (page) {
      final ids = page.docs
          .where(
            (doc) =>
                assignmentStatus(doc.data()['maTrangThaiTiepNhan']) ==
                'duoc_chon',
          )
          .map((doc) => doc.id)
          .toSet();
      if (ids.any((id) => id.isEmpty || id.contains('/'))) {
        return Stream<List<BanGhi>>.error(
          StateError('Phân công có mã yêu cầu không hợp lệ.'),
        );
      }
      return gopLuong(
        ids
            .map((id) => db.collection('YeuCauCuuHo').doc(id).snapshots())
            .toList(),
      ).map((docs) {
        if (docs.any((doc) => !doc.exists)) {
          throw StateError('Có phân công trỏ tới yêu cầu không còn tồn tại.');
        }
        return docs
            .where(
              (doc) => !['hoan_thanh', 'da_huy'].contains(
                normalizeRequestStatus(doc.data()?['maTinhTrangYeuCau']),
              ),
            )
            .map(BanGhi.fromDoc)
            .toList();
      });
    },
  );

  Future<TaiKhoan> hydrate(DocumentSnapshot<Map<String, dynamic>> doc) async {
    if (!_manageableDoc(doc)) {
      throw StateError('Hồ sơ Admin dành riêng cho chat.');
    }
    final profiles = await Future.wait([
      db
          .collection('HoSoCuuHoCoCCHN')
          .doc(doc.id)
          .get(const GetOptions(source: Source.server)),
      db
          .collection('HoSoCuuHoKhongCCHN')
          .doc(doc.id)
          .get(const GetOptions(source: Source.server)),
      db
          .collection('HanCheNguoiDung')
          .doc(doc.id)
          .get(const GetOptions(source: Source.server)),
    ]);
    return TaiKhoan(
      doc.id,
      doc.data()!,
      profiles[0].data(),
      profiles[1].data(),
      restrictions: profiles[2].data() ?? {},
    );
  }

  @override
  Future<List<TaiKhoan>> allAccounts() async => (await page()).items;

  @override
  Future<TrangDuLieu<TaiKhoan>> page({Object? after}) async {
    Query<Map<String, dynamic>> q = _manageableAccounts().limit(20);
    if (after != null) {
      q = q.startAfterDocument(after as DocumentSnapshot<Map<String, dynamic>>);
    }
    final batch = await q.get(const GetOptions(source: Source.server));
    final result = await taiTheoNhom(batch.docs.where(_manageableDoc), hydrate);
    return TrangDuLieu(
      result,
      batch.docs.isEmpty ? after : batch.docs.last,
      batch.docs.length == 20,
    );
  }

  @override
  Future<TaiKhoan> get(String uid) async {
    if (uid.trim().toLowerCase() == 'admin') {
      throw StateError('Hồ sơ Admin dành riêng cho chat.');
    }
    final doc = await db
        .collection('NguoiDung')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) throw StateError('Không tìm thấy tài khoản.');
    return hydrate(doc);
  }

  @override
  Future<Map<String, String>> roles() async {
    final docs = await db
        .collection('VaiTro')
        .get(const GetOptions(source: Source.server));
    return {for (final d in docs.docs) d.id: textOf(d.data(), 'vaiTro', d.id)};
  }

  @override
  Future<void> action(TaiKhoan account, String action, String reason) async {
    if (!account.isManageableAccount) {
      throw StateError('Không được hạn chế hồ sơ Admin dùng cho chat.');
    }
    final why = reason.trim();
    if (!['khoa', 'mo_khoa', 'tam_ngung', 'khoi_phuc'].contains(action) ||
        why.length < 5 ||
        why.length > 500) {
      throw StateError('Thao tác hoặc lý do không hợp lệ.');
    }
    try {
      await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('adminCapNhatHanCheNguoiDung').call({
        'uid': account.uid,
        'action': action,
        'lyDo': why,
        'expectedVersion': account.version,
      });
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? 'Không thể cập nhật trạng thái tài khoản.');
    }
  }

  Query<Map<String, dynamic>> truyVanBanGhi(String uid, String kind) {
    Query<Map<String, dynamic>> query;
    switch (kind) {
      case 'sent':
        query = db
            .collection('YeuCauCuuHo')
            .where(
              Filter.or(
                Filter('maNguoiYeuCau', isEqualTo: uid),
                Filter('maNguoiDung', isEqualTo: uid),
              ),
            );
      case 'helped':
        query = db
            .collectionGroup('DanhSachPhanCong')
            .where('maNguoiCuuHo', isEqualTo: uid);
      case 'documents':
        query = db.collection('LuuAnh').where('maNguoiDung', isEqualTo: uid);
      case 'ratings':
        query = db.collection('DanhGia').doc(uid).collection('DanhSachYeuCau');
      case 'reports':
        query = db
            .collection('PhanAnh')
            .where('maNguoiBiPhanAnh', isEqualTo: uid);
      case 'discipline':
        query = db
            .collection('HoSoKyLuat')
            .where('maNguoiDung', isEqualTo: uid);
      case 'audit':
        query = db
            .collection('NguoiDung')
            .doc(uid)
            .collection('NhatKyQuanTri')
            .orderBy('thoiGian', descending: true)
            .orderBy(FieldPath.documentId, descending: true);
      default:
        throw ArgumentError('Loại dữ liệu không được hỗ trợ: $kind');
    }
    if (kind != 'audit') query = query.orderBy(FieldPath.documentId);
    return query;
  }

  @override
  Future<TrangBanGhi> records(
    String uid,
    String kind, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    var query = truyVanBanGhi(uid, kind);
    if (after != null) query = query.startAfterDocument(after);
    final docs = await query
        .limit(20)
        .get(const GetOptions(source: Source.server));
    return TrangBanGhi(
      docs.docs
          .where((d) => kind != 'sent' || maNanNhan(d.data()) == uid)
          .map(BanGhi.fromDoc)
          .toList(),
      docs.docs.isEmpty ? after : docs.docs.last,
      docs.docs.length == 20,
    );
  }

  @override
  Future<BanGhi?> sos(String id) async {
    if (id.isEmpty || id.contains('/')) {
      throw StateError('Mã SOS không hợp lệ.');
    }
    final doc = await db
        .collection('YeuCauCuuHo')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? BanGhi.fromDoc(doc) : null;
  }
}
