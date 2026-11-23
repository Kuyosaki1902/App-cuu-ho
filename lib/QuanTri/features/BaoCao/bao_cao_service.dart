import 'package:cloud_firestore/cloud_firestore.dart';

class BaoCaoRow {
  final String id;
  final Map<String, dynamic> data;
  const BaoCaoRow(this.id, this.data);
}

class BaoCaoData {
  final List<BaoCaoRow> requests;
  final List<BaoCaoRow> rescueRecords;
  final List<BaoCaoRow> users;
  final List<BaoCaoRow> achievements;
  final List<BaoCaoRow> professionalProfiles;
  final List<BaoCaoRow> volunteerProfiles;
  final List<BaoCaoRow> requestTypes;
  final List<BaoCaoRow> reviews;
  final String? reviewLoadError;
  final DateTime loadedAt;

  const BaoCaoData({
    required this.requests,
    required this.rescueRecords,
    required this.users,
    required this.achievements,
    required this.professionalProfiles,
    required this.volunteerProfiles,
    required this.requestTypes,
    required this.reviews,
    required this.reviewLoadError,
    required this.loadedAt,
  });
}

class BaoCaoService {
  final FirebaseFirestore db;
  BaoCaoService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  Future<List<BaoCaoRow>> _read(String collection) async {
    const batchSize = 400;
    final rows = <BaoCaoRow>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> query = db
          .collection(collection)
          .orderBy(FieldPath.documentId)
          .limit(batchSize);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final page = await query.get(const GetOptions(source: Source.server));
      rows.addAll(
        page.docs.map(
          (doc) => BaoCaoRow(doc.id, Map<String, dynamic>.from(doc.data())),
        ),
      );
      if (page.docs.length < batchSize) break;
      cursor = page.docs.last;
    }
    return rows;
  }

  Future<List<BaoCaoRow>> _readRescuerUsers(
    List<BaoCaoRow> professionalProfiles,
    List<BaoCaoRow> volunteerProfiles,
  ) async {
    final users = <String, BaoCaoRow>{};
    const batchSize = 400;
    DocumentSnapshot<Map<String, dynamic>>? roleCursor;
    while (true) {
      Query<Map<String, dynamic>> roleQuery = db
          .collection('NguoiDung')
          .where(
            'maVaiTro',
            whereIn: ['vaitro_cuuhococc', 'vaitro_cuuhochuacocc'],
          )
          .orderBy(FieldPath.documentId)
          .limit(batchSize);
      if (roleCursor != null)
        roleQuery = roleQuery.startAfterDocument(roleCursor);
      final rolePage = await roleQuery.get(
        const GetOptions(source: Source.server),
      );
      for (final doc in rolePage.docs) {
        users[doc.id] = BaoCaoRow(
          doc.id,
          Map<String, dynamic>.from(doc.data()),
        );
      }
      if (rolePage.docs.length < batchSize) break;
      roleCursor = rolePage.docs.last;
    }

    final profileIds = <String>{
      ...professionalProfiles.map((row) => row.id),
      ...volunteerProfiles.map((row) => row.id),
    };
    final missingIds = profileIds
        .where((uid) => !users.containsKey(uid))
        .toList();
    final linkedUsers = await Future.wait(
      missingIds.map(
        (uid) => db
            .collection('NguoiDung')
            .doc(uid)
            .get(const GetOptions(source: Source.server)),
      ),
    );
    for (final doc in linkedUsers) {
      final value = doc.data();
      if (doc.exists && value != null) {
        users[doc.id] = BaoCaoRow(doc.id, Map<String, dynamic>.from(value));
      }
    }
    return users.values.toList(growable: false);
  }

  Future<List<BaoCaoRow>> _readReviewGroup() async {
    const batchSize = 400;
    final rows = <BaoCaoRow>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    try {
      while (true) {
        Query<Map<String, dynamic>> query = db
            .collectionGroup('DanhSachYeuCau')
            .orderBy(FieldPath.documentId)
            .limit(batchSize);
        if (cursor != null) query = query.startAfterDocument(cursor);
        final page = await query.get(const GetOptions(source: Source.server));
        rows.addAll(
          page.docs.map(
            (doc) => BaoCaoRow(doc.id, Map<String, dynamic>.from(doc.data())),
          ),
        );
        if (page.docs.length < batchSize) return rows;
        cursor = page.docs.last;
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition' ||
          !(error.message?.toLowerCase().contains('index') ?? false)) {
        rethrow;
      }
      // Compatible with projects that have not created a group-scope index.
      final fallback = <BaoCaoRow>[];
      final parents = await _read('DanhGia');
      for (final parent in parents) {
        DocumentSnapshot<Map<String, dynamic>>? childCursor;
        while (true) {
          var query = db
              .collection('DanhGia')
              .doc(parent.id)
              .collection('DanhSachYeuCau')
              .orderBy(FieldPath.documentId)
              .limit(batchSize);
          if (childCursor != null)
            query = query.startAfterDocument(childCursor);
          final page = await query.get(const GetOptions(source: Source.server));
          fallback.addAll(
            page.docs.map(
              (doc) => BaoCaoRow(doc.id, Map<String, dynamic>.from(doc.data())),
            ),
          );
          if (page.docs.length < batchSize) break;
          childCursor = page.docs.last;
        }
      }
      return fallback;
    }
  }

  // Read the chosen time range at the Firestore level when possible.
  // Legacy ISO string times are queried separately, without schema changes.
  Future<List<BaoCaoRow>> _readRequestsInPeriod(
    DateTime? start,
    DateTime? endExclusive,
  ) async {
    if (start == null || endExclusive == null) {
      return _read('YeuCauCuuHo');
    }
    final startUtc = start.toUtc();
    final endUtc = endExclusive.toUtc();

    Future<List<BaoCaoRow>> paged(Query<Map<String, dynamic>> base) async {
      final result = <BaoCaoRow>[];
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      while (true) {
        var q = base.limit(400);
        if (cursor != null) q = q.startAfterDocument(cursor);
        final page = await q.get(const GetOptions(source: Source.server));
        for (final doc in page.docs) {
          result.add(BaoCaoRow(doc.id, Map<String, dynamic>.from(doc.data())));
        }
        if (page.docs.length < 400) return result;
        cursor = page.docs.last;
      }
    }

    final timestampQuery = db
        .collection('YeuCauCuuHo')
        .where(
          'thoiGianTao',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc),
        )
        .where('thoiGianTao', isLessThan: Timestamp.fromDate(endUtc))
        .orderBy('thoiGianTao')
        .orderBy(FieldPath.documentId);
    final isoStringQuery = db
        .collection('YeuCauCuuHo')
        .where(
          'thoiGianTao',
          isGreaterThanOrEqualTo: startUtc.toIso8601String(),
        )
        .where('thoiGianTao', isLessThan: endUtc.toIso8601String())
        .orderBy('thoiGianTao')
        .orderBy(FieldPath.documentId);
    final groups = await Future.wait([
      paged(timestampQuery),
      paged(isoStringQuery),
    ]);
    final unique = <String, BaoCaoRow>{};
    for (final group in groups) {
      for (final item in group) {
        final raw = baoCaoDate(item.data['thoiGianTao']);
        if (raw != null && !raw.isBefore(start) && raw.isBefore(endExclusive)) {
          unique[item.id] = item;
        }
      }
    }
    return unique.values.toList(growable: false);
  }

  // First screen: request-focused overview, without scanning all rescuer,
  // achievement and historical review collections.
  Future<BaoCaoData> loadOverview({
    DateTime? start,
    DateTime? endExclusive,
  }) async {
    final core = await Future.wait<List<BaoCaoRow>>([
      _readRequestsInPeriod(start, endExclusive),
      _read('LoaiYeuCau'),
    ]);
    return BaoCaoData(
      requests: core[0],
      rescueRecords: const [],
      users: const [],
      achievements: const [],
      professionalProfiles: const [],
      volunteerProfiles: const [],
      requestTypes: core[1],
      reviews: const [],
      reviewLoadError: null,
      loadedAt: DateTime.now(),
    );
  }

  // These heavier datasets are only read after the admin explicitly opens
  // the detailed analytics section. The exact historical data is retained.
  Future<BaoCaoData> loadDetails(BaoCaoData overview) async {
    final core = await Future.wait<List<BaoCaoRow>>([
      _read('HoSoCuuHo'),
      _read('ThanhTichCuuHo'),
      _read('HoSoCuuHoCoCCHN'),
      _read('HoSoCuuHoKhongCCHN'),
    ]);
    final rescuerUsers = await _readRescuerUsers(core[2], core[3]);
    var reviews = <BaoCaoRow>[];
    String? reviewError;
    try {
      reviews = await _readReviewGroup();
    } catch (error) {
      reviewError = error.toString();
    }
    return BaoCaoData(
      requests: overview.requests,
      rescueRecords: core[0],
      users: rescuerUsers,
      achievements: core[1],
      professionalProfiles: core[2],
      volunteerProfiles: core[3],
      requestTypes: overview.requestTypes,
      reviews: reviews,
      reviewLoadError: reviewError,
      loadedAt: DateTime.now(),
    );
  }

  // Legacy full-load entry point for consumers that require every section.
  Future<BaoCaoData> load() async => loadDetails(await loadOverview());
}

DateTime? baoCaoDate(Object? value) {
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return parsed.toLocal();
  }
  if (value is num) {
    final millis = value.toInt();
    if (millis > 0) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      } catch (_) {}
    }
  }
  return null;
}

int baoCaoInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

double baoCaoDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}

String baoCaoRequestStatus(Object? value) {
  const aliases = {
    'user_tinhtrang_chotiepnhan': 'cho_tiep_nhan',
    'user_tinhtrang_quahandieuphoi': 'qua_han_dieu_phoi',
    'user_tinhtrang_daphancong': 'da_phan_cong',
    'user_tinhtrang_dangcuuho': 'dang_cuu_ho',
    'user_tinhtrang_hoanthanh': 'hoan_thanh',
    'user_tinhtrang_dahuy': 'da_huy',
  };
  final raw = value is String ? value.trim() : '';
  return aliases[raw] ?? raw;
}
