import '../../../core/luong_truc_tiep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../TaiKhoan/models/tai_khoan_model.dart';
import '../../../models/trang_du_lieu.dart';
import '../../../models/giay_to_ho_so.dart';
import '../../../models/ban_ghi.dart';
import '../models/xac_minh_model.dart';
import '../../../core/kiem_tra_quyen_ghi.dart';

abstract class NguonXacMinh {
  Future<List<HoSoXacMinh>> list();
  Future<ChiTietXacMinh> detail(String collection, String uid);
  Future<void> review(HoSoXacMinh profile, String action);
}

class MocXacMinh {
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> after;
  final Set<String> ended;
  MocXacMinh(this.after, this.ended);
}

abstract class XacMinhPhanTrang {
  Future<TrangDuLieu<HoSoXacMinh>> page({Object? after});
}

abstract class XacMinhTrucTiep {
  Stream<TrangDuLieu<HoSoXacMinh>> watchPage(int limit);
  Stream<ChiTietXacMinh> watchDetail(String collection, String uid);
}

class XacMinhService
    implements NguonXacMinh, XacMinhPhanTrang, XacMinhTrucTiep {
  final FirebaseFirestore db;
  XacMinhService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;
  Stream<HoSoXacMinh> watchProfile(
    String collection,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      gopLuong<Object?>([
        db.collection('NguoiDung').doc(doc.id).snapshots(),
        db
            .collection('LuuAnh')
            .where('maNguoiDung', isEqualTo: doc.id)
            .snapshots(),
      ]).map((values) {
        final user = values[0] as DocumentSnapshot<Map<String, dynamic>>;
        final files = values[1] as QuerySnapshot<Map<String, dynamic>>;
        return HoSoXacMinh(
          doc.id,
          collection,
          doc.data() ?? {},
          user.data() ?? {},
          files.docs
              .where((file) => belongsToProfile(file.data(), collection))
              .map(BanGhi.fromDoc)
              .toList(),
          accountExists: user.exists,
        );
      });

  // The verification list intentionally excludes LuuAnh payloads. Full
  // document media is subscribed to only from watchDetail().
  Stream<HoSoXacMinh> watchProfileSummary(
    String collection,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => db
      .collection('NguoiDung')
      .doc(doc.id)
      .snapshots()
      .map(
        (user) => HoSoXacMinh(
          doc.id,
          collection,
          doc.data() ?? {},
          user.data() ?? {},
          const [],
          accountExists: user.exists,
        ),
      );

  @override
  Stream<TrangDuLieu<HoSoXacMinh>> watchPage(int limit) =>
      gopLuong(
        profileCollections
            .map(
              (collection) => chuyenLuong(
                db
                    .collection(collection)
                    .orderBy(FieldPath.documentId)
                    .limit(limit + 1)
                    .snapshots(),
                (page) =>
                    gopLuong(
                      page.docs
                          .take(limit)
                          .map((doc) => watchProfileSummary(collection, doc))
                          .toList(),
                    ).map(
                      (items) =>
                          TrangDuLieu(items, null, page.docs.length > limit),
                    ),
              ),
            )
            .toList(),
      ).map(
        (pages) => TrangDuLieu(
          pages.expand((page) => page.items).toList(),
          null,
          pages.any((page) => page.hasMore),
        ),
      );

  Stream<List<String>> watchSkills(String uid) => chuyenLuong(
    gopLuong<Object?>([
      db
          .collection('ChiTietKyNang')
          .where('maNguoiDung', isEqualTo: uid)
          .snapshots(),
      db
          .collection('ChiTietKyNang')
          .doc(uid)
          .collection('DanhSachKyNang')
          .snapshots(),
      db
          .collection('ChiTietKyNangCuuHo')
          .where('maNguoiDung', isEqualTo: uid)
          .snapshots(),
    ]),
    (pages) {
      final names = <String, String>{};
      for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final page = pages[pageIndex] as QuerySnapshot<Map<String, dynamic>>;
        for (final doc in page.docs) {
          final data = doc.data();
          final rawId = data['maKyNangCuuHo'] ?? data['maKyNang'];
          final id = rawId is String && rawId.trim().isNotEmpty
              ? rawId.trim()
              : (pageIndex > 0 ? doc.id : '');
          if (id.isEmpty || id.contains('/')) continue;
          final custom = '${data['tenKyNangTudo'] ?? ''}'.trim();
          names[id] = custom.isNotEmpty ? custom : id;
        }
      }
      final ids = names.keys.toList()..sort();
      return gopLuong(
        ids
            .map(
              (id) => db
                  .collection('KyNangCuuHo')
                  .doc(id)
                  .snapshots()
                  .map(
                    (doc) => '${doc.data()?['tenKyNang'] ?? names[id] ?? id}',
                  ),
            )
            .toList(),
      );
    },
  );

  @override
  Stream<ChiTietXacMinh> watchDetail(String collection, String uid) {
    if (!profileCollections.contains(collection)) {
      return Stream.error(StateError('Loại hồ sơ không hợp lệ.'));
    }
    return chuyenLuong(db.collection(collection).doc(uid).snapshots(), (doc) {
      if (!doc.exists) {
        return Stream.error(StateError('Hồ sơ không còn tồn tại.'));
      }
      return gopLuong<Object?>([
        watchProfile(collection, doc),
        watchSkills(uid),
      ]).map(
        (values) => ChiTietXacMinh(
          values[0] as HoSoXacMinh,
          [],
          values[1] as List<String>,
        ),
      );
    });
  }

  Future<HoSoXacMinh> hydrate(
    String collection,
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool withDocuments = true,
  }) async {
    final user = await db
        .collection('NguoiDung')
        .doc(doc.id)
        .get(const GetOptions(source: Source.server));
    final files = withDocuments
        ? await db
              .collection('LuuAnh')
              .where('maNguoiDung', isEqualTo: doc.id)
              .get(const GetOptions(source: Source.server))
        : null;
    return HoSoXacMinh(
      doc.id,
      collection,
      doc.data() ?? {},
      user.data() ?? {},
      (files?.docs ?? [])
          .where((x) => belongsToProfile(x.data(), collection))
          .map(BanGhi.fromDoc)
          .toList(),
      accountExists: user.exists,
    );
  }

  @override
  Future<List<HoSoXacMinh>> list() async => (await page()).items;
  @override
  Future<TrangDuLieu<HoSoXacMinh>> page({Object? after}) async {
    final previous = after as MocXacMinh?;
    final cursors = {...?previous?.after};
    final ended = {...?previous?.ended};
    final result = <HoSoXacMinh>[];
    for (final collection in profileCollections) {
      if (ended.contains(collection)) continue;
      Query<Map<String, dynamic>> q = db
          .collection(collection)
          .orderBy(FieldPath.documentId)
          .limit(10);
      if (cursors[collection] != null) {
        q = q.startAfterDocument(cursors[collection]!);
      }
      final batch = await q.get(const GetOptions(source: Source.server));
      result.addAll(
        await taiTheoNhom(
          batch.docs,
          (doc) => hydrate(collection, doc, withDocuments: false),
        ),
      );
      if (batch.docs.isNotEmpty) cursors[collection] = batch.docs.last;
      if (batch.docs.length < 10) ended.add(collection);
    }
    return TrangDuLieu(
      result,
      MocXacMinh(cursors, ended),
      ended.length < profileCollections.length,
    );
  }

  @override
  Future<ChiTietXacMinh> detail(String collection, String uid) async {
    if (!profileCollections.contains(collection)) {
      throw StateError('Loại hồ sơ không hợp lệ.');
    }
    final doc = await db
        .collection(collection)
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) throw StateError('Hồ sơ không còn tồn tại.');
    final profile = await hydrate(collection, doc);
    final linkPages = await Future.wait([
      db
          .collection('ChiTietKyNang')
          .where('maNguoiDung', isEqualTo: uid)
          .get(const GetOptions(source: Source.server)),
      db
          .collection('ChiTietKyNang')
          .doc(uid)
          .collection('DanhSachKyNang')
          .get(const GetOptions(source: Source.server)),
      db
          .collection('ChiTietKyNangCuuHo')
          .where('maNguoiDung', isEqualTo: uid)
          .get(const GetOptions(source: Source.server)),
    ]);
    final customNames = <String, String>{};
    for (var pageIndex = 0; pageIndex < linkPages.length; pageIndex++) {
      final page = linkPages[pageIndex];
      for (final link in page.docs) {
        final data = link.data();
        final rawId = data['maKyNangCuuHo'] ?? data['maKyNang'];
        final id = rawId is String && rawId.trim().isNotEmpty
            ? rawId.trim()
            : (pageIndex > 0 ? link.id : '');
        if (id.isEmpty || id.contains('/')) continue;
        final custom = '${data['tenKyNangTudo'] ?? ''}'.trim();
        if (custom.isNotEmpty) {
          customNames[id] = custom;
        } else {
          customNames.putIfAbsent(id, () => id);
        }
      }
    }
    final skills = await taiTheoNhom(customNames.keys, (id) async {
      final skill = await db
          .collection('KyNangCuuHo')
          .doc(id)
          .get(const GetOptions(source: Source.server));
      return '${skill.data()?['tenKyNang'] ?? customNames[id] ?? id}';
    });
    return ChiTietXacMinh(profile, [], skills);
  }

  @override
  Future<void> review(HoSoXacMinh profile, String action) async {
    final next = verificationNextStatus(action);
    if (!profileCollections.contains(profile.collection)) {
      throw StateError('Loại hồ sơ không hợp lệ.');
    }
    final actor = currentAdminUid();
    final ref = db.collection(profile.collection).doc(profile.uid);
    final userRef = db.collection('NguoiDung').doc(profile.uid);
    await db.runTransaction((transaction) async {
      await checkAdminTransaction(db, transaction, actor, profile.uid);
      final snapshot = await transaction.get(ref);
      final user = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw StateError('Không tìm thấy hồ sơ ${ref.path}.');
      }
      if (!user.exists) {
        throw StateError(
          'Không tìm thấy tài khoản ${userRef.path}. Chưa thể xử lý hồ sơ.',
        );
      }
      final current = snapshot.data()!['maTrangThaiHoSo'];
      if (current != profile.data['maTrangThaiHoSo']) {
        throw StateError('Trạng thái đã thay đổi. Vui lòng tải lại hồ sơ.');
      }
      if (![
        'cho_duyet',
        'can_bo_sung',
      ].contains(normalizeProfileStatus(current))) {
        throw StateError('Hồ sơ đã kết thúc xét duyệt.');
      }
      transaction.update(ref, {'maTrangThaiHoSo': next});
    });
  }
}
