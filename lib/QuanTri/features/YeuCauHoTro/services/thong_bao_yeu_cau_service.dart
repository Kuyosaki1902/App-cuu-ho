import 'package:cloud_firestore/cloud_firestore.dart';

class ThongBaoAdmin {
  final String id;
  final Map<String, dynamic> data;
  final DateTime? instant;

  const ThongBaoAdmin(this.id, this.data, this.instant);

  bool get isRead => data['daDoc'] == true;
}

class TrangThongBao {
  final List<ThongBaoAdmin> items;
  final Object? cursor;
  final bool hasMore;
  const TrangThongBao(this.items, this.cursor, this.hasMore);
}

class DemThongBao {
  final int total;
  final int unread;
  const DemThongBao(this.total, this.unread);
}

abstract class NguonThongBaoYeuCau {
  Stream<TrangThongBao> watchLatest(String field);
  Future<TrangThongBao> fetchNext(String field, Object cursor);
  Future<TrangThongBao> fetchRecent(String field);
  Stream<List<ThongBaoAdmin>> watchLegacy();
  Future<List<ThongBaoAdmin>> fetchLegacy();
  Future<DemThongBao> count();
  Future<void> markRead(String id);
  Future<int> markAllRead();
}

class ThongBaoYeuCauService implements NguonThongBaoYeuCau {
  final FirebaseFirestore db;
  final String uid;

  ThongBaoYeuCauService(this.uid, {FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;

  Query<Map<String, dynamic>> get _query =>
      db.collection('ThongBao').where('maNguoiDung', isEqualTo: uid);

  Query<Map<String, dynamic>> _byField(String field) => _query
      .orderBy(field, descending: true)
      .orderBy(FieldPath.documentId, descending: true);

  static DateTime? _parseTime(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value.trim())?.toUtc();
    if (value is int) {
      final ms = value.abs() < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    return null;
  }

  static DateTime? instant(Map<String, dynamic> data) =>
      _parseTime(data['ngayTao']) ?? _parseTime(data['ngayGui']);

  ThongBaoAdmin _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      ThongBaoAdmin(doc.id, doc.data(), instant(doc.data()));

  TrangThongBao _page(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final docs = snapshot.docs.take(20).toList();
    return TrangThongBao(
      docs.map(_fromDoc).toList(),
      docs.isEmpty ? null : docs.last,
      snapshot.docs.length > 20,
    );
  }

  Stream<TrangThongBao> watchLatest(String field) =>
      _byField(field).limit(21).snapshots().map(_page);

  Future<TrangThongBao> fetchNext(String field, Object cursor) async {
    final after = cursor as DocumentSnapshot<Map<String, dynamic>>;
    final page = await _byField(field)
        .startAfterDocument(after)
        .limit(21)
        .get(const GetOptions(source: Source.server));
    return _page(page);
  }

  Future<TrangThongBao> fetchRecent(String field) async => _page(
    await _byField(
      field,
    ).limit(21).get(const GetOptions(source: Source.server)),
  );

  Stream<List<ThongBaoAdmin>> watchLegacy() =>
      _query.snapshots().map((page) => page.docs.map(_fromDoc).toList());

  Future<List<ThongBaoAdmin>> fetchLegacy() async => (await _query.get(
    const GetOptions(source: Source.server),
  )).docs.map(_fromDoc).toList();

  Future<DemThongBao> count() async {
    final counts = await Future.wait([
      _query.count().get(),
      _query.where('daDoc', isEqualTo: true).count().get(),
    ]);
    final total = counts[0].count ?? 0;
    final read = counts[1].count ?? 0;
    return DemThongBao(total, (total - read).clamp(0, total).toInt());
  }

  Future<void> markRead(String id) =>
      db.collection('ThongBao').doc(id).update({'daDoc': true});

  Future<int> markAllRead() async {
    final unread = await _query.get(const GetOptions(source: Source.server));
    final docs = unread.docs
        .where((doc) => doc.data()['daDoc'] != true)
        .toList();
    for (var start = 0; start < docs.length; start += 450) {
      final end = start + 450 < docs.length ? start + 450 : docs.length;
      final batch = db.batch();
      for (final doc in docs.sublist(start, end)) {
        batch.update(doc.reference, {'daDoc': true});
      }
      await batch.commit();
    }
    return docs.length;
  }
}
