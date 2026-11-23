import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/ban_ghi.dart';

class PhanAnhService {
  final FirebaseFirestore db;
  PhanAnhService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;

  // Firestore stores reviews under DanhGia/{rescuerId}/DanhSachYeuCau.
  // Use the direct path for a selected rescuer to avoid a collection-group index.
  Query<Map<String, dynamic>> _reviewsQuery({String? recipient}) {
    final Query<Map<String, dynamic>> query =
        recipient != null && recipient.isNotEmpty
        ? db.collection('DanhGia').doc(recipient).collection('DanhSachYeuCau')
        : db.collectionGroup('DanhSachYeuCau');
    return query.orderBy(FieldPath.documentId);
  }

  Query<Map<String, dynamic>> _oneStarQuery({String? recipient}) {
    final Query<Map<String, dynamic>> query =
        recipient != null && recipient.isNotEmpty
        ? db.collection('DanhGia').doc(recipient).collection('DanhSachYeuCau')
        : db.collectionGroup('DanhSachYeuCau');
    return query
        .where('diemDanhGia', whereIn: [1, '1'])
        .orderBy('ngayTao', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  /// Live newest 20 one-star reviews; history uses the same sorting and cursor.
  Stream<TrangBanGhi> watchFirstOneStar({String? recipient}) =>
      _oneStarQuery(recipient: recipient).limit(21).snapshots().map((snapshot) {
        final visible = snapshot.docs.take(20).toList(growable: false);
        return TrangBanGhi(
          visible.map(BanGhi.fromDoc).toList(growable: false),
          visible.isEmpty ? null : visible.last,
          snapshot.docs.length > 20,
        );
      });

  Future<TrangBanGhi> page(
    bool oneStar,
    DocumentSnapshot<Map<String, dynamic>>? cursor, {
    String? recipient,
  }) async {
    var query = oneStar
        ? _oneStarQuery(recipient: recipient)
        : _reviewsQuery(recipient: recipient);
    if (cursor != null) query = query.startAfterDocument(cursor);
    try {
      final batch = await query
          .limit(21)
          .get(const GetOptions(source: Source.server));
      final visible = batch.docs.take(20).toList(growable: false);
      return TrangBanGhi(
        visible.map(BanGhi.fromDoc).toList(growable: false),
        visible.isEmpty ? cursor : visible.last,
        batch.docs.length > 20,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition' ||
          !(error.message?.toLowerCase().contains('index') ?? false)) {
        rethrow;
      }
      // Missing collection-group index: read existing parent documents instead.
      // This preserves the current schema and the 20-item page contract.
      return _reviewsWithoutIndex(oneStar, cursor, recipient);
    }
  }

  Future<TrangBanGhi> _reviewsWithoutIndex(
    bool oneStar,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    String? recipient,
  ) async {
    final parents = recipient != null && recipient.isNotEmpty
        ? [db.collection('DanhGia').doc(recipient)]
        : (await db
                  .collection('DanhGia')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .map((doc) => doc.reference)
              .toList();
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final parent in parents) {
      final batch = await parent
          .collection('DanhSachYeuCau')
          .get(const GetOptions(source: Source.server));
      docs.addAll(batch.docs);
    }
    if (oneStar) {
      docs.removeWhere((doc) => ![1, '1'].contains(doc.data()['diemDanhGia']));
    }
    docs.sort((a, b) {
      if (oneStar) {
        final aDate = _reviewTime(a.data()['ngayTao']);
        final bDate = _reviewTime(b.data()['ngayTao']);
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) return byDate;
        return b.reference.path.compareTo(a.reference.path);
      }
      return a.reference.path.compareTo(b.reference.path);
    });
    final cursorIndex = cursor == null
        ? -1
        : docs.indexWhere((doc) => doc.reference.path == cursor.reference.path);
    final start = cursorIndex + 1;
    final visible = docs.skip(start).take(20).toList(growable: false);
    return TrangBanGhi(
      visible.map(BanGhi.fromDoc).toList(growable: false),
      visible.isEmpty ? cursor : visible.last,
      start + visible.length < docs.length,
    );
  }

  int _reviewTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate().millisecondsSinceEpoch;
    if (raw is DateTime) return raw.millisecondsSinceEpoch;
    if (raw is String) {
      return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  Future<TrangBanGhi> rescuers(
    DocumentSnapshot<Map<String, dynamic>>? cursor,
  ) async {
    Query<Map<String, dynamic>> query = db
        .collection('NguoiDung')
        .where(
          'maVaiTro',
          whereIn: ['vaitro_cuuhococc', 'vaitro_cuuhochuacocc'],
        )
        .orderBy(FieldPath.documentId)
        .limit(20);
    if (cursor != null) query = query.startAfterDocument(cursor);
    final page = await query.get();
    return TrangBanGhi(
      page.docs.map(BanGhi.fromDoc).toList(),
      page.docs.isEmpty ? cursor : page.docs.last,
      page.size == 20,
    );
  }

  DocumentReference<Map<String, dynamic>> _reviewRef(String path) {
    final parts = path.split('/');
    if (parts.length != 4 ||
        parts[0] != 'DanhGia' ||
        parts[1].isEmpty ||
        parts[2] != 'DanhSachYeuCau' ||
        parts[3].isEmpty) {
      throw StateError('Đường dẫn đánh giá không hợp lệ.');
    }
    return db.doc(path);
  }

  Stream<BanGhi?> watch(String path) => _reviewRef(path).snapshots().map(
    (snapshot) => snapshot.exists ? BanGhi.fromDoc(snapshot) : null,
  );

  Future<void> update(String path, String actor, {String? result}) async {
    final ref = _reviewRef(path);
    final note = result?.trim();
    if (actor.isEmpty) throw StateError('Phiên đăng nhập đã kết thúc.');
    if (note != null && (note.length < 5 || note.length > 500)) {
      throw StateError('Nhập kết quả xử lý từ 5 đến 500 ký tự.');
    }

    await db.runTransaction((tx) async {
      final admin = await tx.get(db.collection('Admin').doc(actor));
      final review = await tx.get(ref);
      final data = review.data();
      if (admin.data()?['trangThai'] != 'hoat_dong') {
        throw StateError('Tài khoản không có quyền xử lý.');
      }
      if (data == null || ![1, '1'].contains(data['diemDanhGia'])) {
        throw StateError('Đánh giá không còn trong nhóm 1 sao.');
      }
      final status = data['trangThaiXuLy'] ?? 'chua_xu_ly';
      if (note == null && status != 'chua_xu_ly') {
        throw StateError('Đánh giá đã được tiếp nhận.');
      }
      if (note != null &&
          (status != 'dang_xu_ly' || data['maAdminXuLy'] != actor)) {
        throw StateError('Chỉ người đang phụ trách mới được hoàn tất.');
      }
      tx.update(ref, {
        'trangThaiXuLy': note == null ? 'dang_xu_ly' : 'da_xu_ly',
        'maAdminXuLy': actor,
        'ngayCapNhatXuLy': FieldValue.serverTimestamp(),
        ...?(note == null ? null : {'ketQuaXuLy': note}),
      });
    });
  }
}
