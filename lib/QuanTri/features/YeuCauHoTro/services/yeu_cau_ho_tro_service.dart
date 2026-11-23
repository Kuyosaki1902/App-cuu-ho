import '../../../core/luong_truc_tiep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/trang_du_lieu.dart';
import '../models/chi_tiet_yeu_cau_model.dart';
import '../models/yeu_cau_ho_tro_model.dart';

abstract class NguonYeuCauHoTro {
  Future<TrangDuLieu<YeuCauHoTro>> page({Object? after});
}

abstract class YeuCauTrucTiep {
  Stream<TrangDuLieu<YeuCauHoTro>> watchPage(int limit);
}

abstract class YeuCauTheoTab {
  Stream<TrangDuLieu<YeuCauHoTro>> watchFirstTabPage(String tab);
  Future<TrangDuLieu<YeuCauHoTro>> fetchNextTabPage(String tab, Object? after);
  Stream<List<YeuCauHoTro>> watchUrgentActive();
  // Observe only the IDs of loaded history pages, not the whole collection.
  Stream<List<YeuCauHoTro>> watchLoadedRows(List<String> ids);
  Future<YeuCauHoTro> hydrateRow(YeuCauHoTro item);
}

// A single live, ordered window avoids offset/cursor drift when requests are
// inserted, closed or moved between pages. Every loaded position is live.
abstract class YeuCauCuaSoTrucTiep {
  Stream<TrangDuLieu<YeuCauHoTro>> watchTabWindow(String tab, int loadedLimit);
  Stream<List<YeuCauHoTro>> watchUrgentActive();
  Future<YeuCauHoTro> hydrateRow(YeuCauHoTro item);
}

class YeuCauHoTroService
    implements
        NguonYeuCauHoTro,
        YeuCauTrucTiep,
        YeuCauTheoTab,
        YeuCauCuaSoTrucTiep {
  final FirebaseFirestore db;
  YeuCauHoTroService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;

  static const _activeStatuses = <String>[
    'cho_tiep_nhan',
    'qua_han_dieu_phoi',
    'da_phan_cong',
    'dang_cuu_ho',
    'cho_dong',
    'user_tinhtrang_chotiepnhan',
    'user_tinhtrang_quahandieuphoi',
    'user_tinhtrang_daphancong',
    'user_tinhtrang_dangcuuho',
  ];
  static const _closedStatuses = <String>[
    'hoan_thanh',
    'da_huy',
    'user_tinhtrang_hoanthanh',
    'user_tinhtrang_dahuy',
  ];

  final Map<String, Future<String>> _nameCache = {};
  final Map<String, Future<String>> _typeCache = {};

  Query<Map<String, dynamic>> _tabQuery(String tab) => db
      .collection('YeuCauCuuHo')
      .where(
        'maTinhTrangYeuCau',
        whereIn: tab == 'closed' ? _closedStatuses : _activeStatuses,
      )
      .orderBy(FieldPath.documentId);

  YeuCauHoTro _rawRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = data['thoiGianTao'];
    return YeuCauHoTro(
      doc.id,
      data,
      createdAt: raw is Timestamp
          ? raw.toDate()
          : raw is String
          ? DateTime.tryParse(raw)
          : null,
    );
  }

  @override
  Stream<TrangDuLieu<YeuCauHoTro>> watchTabWindow(
    String tab,
    int loadedLimit,
  ) => _tabQuery(tab).limit(loadedLimit + 1).snapshots().map((snapshot) {
    final docs = snapshot.docs.take(loadedLimit).toList();
    return TrangDuLieu(
      docs.map(_rawRow).toList(),
      docs.isEmpty ? null : docs.last,
      snapshot.docs.length > loadedLimit,
    );
  });

  @override
  Stream<TrangDuLieu<YeuCauHoTro>> watchFirstTabPage(String tab) =>
      _tabQuery(tab).limit(21).snapshots().map((snapshot) {
        final docs = snapshot.docs;
        return TrangDuLieu(
          docs.take(20).map(_rawRow).toList(),
          docs.isEmpty ? null : docs.take(20).last,
          docs.length > 20,
        );
      });

  @override
  Future<TrangDuLieu<YeuCauHoTro>> fetchNextTabPage(
    String tab,
    Object? after,
  ) async {
    if (after is! DocumentSnapshot<Map<String, dynamic>>) {
      return const TrangDuLieu(<YeuCauHoTro>[], null, false);
    }
    final batch = await _tabQuery(tab)
        .startAfterDocument(after)
        .limit(21)
        .get(const GetOptions(source: Source.server));
    final docs = batch.docs.take(20).toList();
    return TrangDuLieu(
      docs.map(_rawRow).toList(),
      docs.isEmpty ? after : docs.last,
      batch.docs.length > 20,
    );
  }

  @override
  Stream<List<YeuCauHoTro>> watchUrgentActive() {
    final requests = db.collection('YeuCauCuuHo');
    Stream<List<YeuCauHoTro>> query(Query<Map<String, dynamic>> ref) =>
        ref.snapshots().map((snapshot) => snapshot.docs.map(_rawRow).toList());

    return gopLuong<List<YeuCauHoTro>>([
      query(requests.where('mucDoKhanCap', isEqualTo: 1)),
      query(requests.where('mucDoKhanCap', isEqualTo: '1')),
      query(
        requests.where(
          'maTinhTrangYeuCau',
          whereIn: const ['qua_han_dieu_phoi', 'user_tinhtrang_quahandieuphoi'],
        ),
      ),
      query(requests.where('canBoSungNhanLuc', isEqualTo: true)),
      query(requests.where('canKiemTra', isEqualTo: true)),
    ]).map((groups) {
      final result = <String, YeuCauHoTro>{};
      for (final group in groups) {
        for (final item in group) {
          if (item.tab == 'active' &&
              (item.urgencyLevel == 1 || item.needsIntervention)) {
            result[item.id] = item;
          }
        }
      }
      return result.values.toList();
    });
  }

  @override
  Stream<List<YeuCauHoTro>> watchLoadedRows(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const <YeuCauHoTro>[]);
    // Each loaded page contains at most 20 documents, within Firestore's
    // whereIn operand limit. Query only by ID to catch status transitions.
    return db
        .collection('YeuCauCuuHo')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((page) => page.docs.map(_rawRow).toList());
  }

  Future<String> _cachedName(String uid) {
    if (uid.isEmpty || uid.contains('/')) return Future.value('');
    return _nameCache.putIfAbsent(uid, () async {
      try {
        final doc = await db.collection('NguoiDung').doc(uid).get();
        return (doc.data()?['hoTen'] ?? '').toString().trim();
      } catch (_) {
        _nameCache.remove(uid);
        rethrow;
      }
    });
  }

  Future<String> _cachedType(String type) {
    if (type.isEmpty || type.contains('/')) return Future.value('');
    return _typeCache.putIfAbsent(type, () async {
      try {
        final doc = await db.collection('LoaiYeuCau').doc(type).get();
        return (doc.data()?['tenLoaiYeuCau'] ?? '').toString().trim();
      } catch (_) {
        _typeCache.remove(type);
        rethrow;
      }
    });
  }

  @override
  Future<YeuCauHoTro> hydrateRow(YeuCauHoTro item) async {
    final personId = maNanNhan(item.data);
    final type = item.text('maLoaiYeuCau');
    final parts = await Future.wait([_cachedName(personId), _cachedType(type)]);

    final members = phanCongTrongCa(item.data);
    final accepted = members.keys
        .where((uid) => assignmentStatus(members[uid]) == 'duoc_chon')
        .toSet();
    if (const [
      'da_phan_cong',
      'dang_cuu_ho',
      'cho_dong',
    ].contains(item.status)) {
      final assigned = await db
          .collectionGroup('DanhSachPhanCong')
          .where('maYeuCau', isEqualTo: item.id)
          .where('maTrangThaiTiepNhan', whereIn: selectedAssignmentCodes)
          .limit(10)
          .get();
      for (final row in assigned.docs) {
        final uid = row.data()['maNguoiCuuHo'];
        if (uid is String && uid.isNotEmpty && !uid.contains('/')) {
          accepted.add(uid);
        }
      }
    }
    final assignedNames = await Future.wait(
      accepted.map((uid) async {
        final name = await _cachedName(uid);
        return name.isEmpty ? uid : name;
      }),
    );
    return YeuCauHoTro(
      item.id,
      item.data,
      createdAt: item.createdAt,
      tenNanNhan: parts[0],
      typeName: parts[1],
      assigneeName: assignedNames.join(', '),
    );
  }

  @override
  Stream<TrangDuLieu<YeuCauHoTro>> watchPage(int limit) => db
      .collection('YeuCauCuuHo')
      .orderBy(FieldPath.documentId)
      .limit(limit + 1)
      .snapshots()
      .map(
        (page) => TrangDuLieu(
          page.docs.take(limit).map(_rawRow).toList(),
          page.docs.isEmpty ? null : page.docs.take(limit).last,
          page.docs.length > limit,
        ),
      );

  @override
  Future<TrangDuLieu<YeuCauHoTro>> page({Object? after}) async {
    Query<Map<String, dynamic>> query = db
        .collection('YeuCauCuuHo')
        .orderBy(FieldPath.documentId)
        .limit(20);
    if (after != null) {
      query = query.startAfterDocument(
        after as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final batch = await query.get(const GetOptions(source: Source.server));
    final users = <String, Future<String>>{};
    final types = <String, Future<String>>{};
    Future<String> name(String collection, String id, String field) async {
      if (id.isEmpty || id.contains('/')) return '';
      final doc = await db
          .collection(collection)
          .doc(id)
          .get(const GetOptions(source: Source.server));
      final value = doc.data()?[field];
      return value is String ? value : '';
    }

    Future<YeuCauHoTro> hydrate(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) async {
      final data = doc.data();
      final uid = maNanNhan(data);
      final type = data['maLoaiYeuCau'] is String
          ? data['maLoaiYeuCau'] as String
          : '';
      final names = await Future.wait([
        users.putIfAbsent(uid, () => name('NguoiDung', uid, 'hoTen')),
        types.putIfAbsent(
          type,
          () => name('LoaiYeuCau', type, 'tenLoaiYeuCau'),
        ),
      ]);
      final members = phanCongTrongCa(data);
      final ids = members.keys
          .where((uid) => assignmentStatus(members[uid]) == 'duoc_chon')
          .toSet();
      if ([
        'da_phan_cong',
        'dang_cuu_ho',
        'cho_dong',
      ].contains(normalizeRequestStatus(data['maTinhTrangYeuCau']))) {
        final assigned = await db
            .collectionGroup('DanhSachPhanCong')
            .where('maYeuCau', isEqualTo: doc.id)
            .where('maTrangThaiTiepNhan', whereIn: selectedAssignmentCodes)
            .limit(10)
            .get(const GetOptions(source: Source.server));
        for (final row in assigned.docs) {
          final helper = row.data()['maNguoiCuuHo'];
          if (helper is String && helper.isNotEmpty && !helper.contains('/'))
            ids.add(helper);
        }
      }
      final assignee = (await Future.wait(
        ids.map((uid) async {
          final label = await users.putIfAbsent(
            uid,
            () => name('NguoiDung', uid, 'hoTen'),
          );
          return label.isEmpty ? uid : label;
        }),
      )).join(', ');
      final raw = data['thoiGianTao'];
      return YeuCauHoTro(
        doc.id,
        data,
        tenNanNhan: names[0],
        assigneeName: assignee,
        typeName: names[1],
        createdAt: raw is Timestamp
            ? raw.toDate()
            : raw is String
            ? DateTime.tryParse(raw)
            : null,
      );
    }

    final items = await taiTheoNhom(batch.docs, hydrate);
    return TrangDuLieu(
      items,
      batch.docs.isEmpty ? after : batch.docs.last,
      batch.docs.length == 20,
    );
  }
}
