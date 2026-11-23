import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/kiem_tra_quyen_ghi.dart';
import '../../../models/ban_ghi.dart';
import '../../../core/luong_truc_tiep.dart';
import '../models/dieu_phoi_model.dart';
import '../models/yeu_cau_ho_tro_model.dart';
import '../models/chi_tiet_yeu_cau_model.dart';
import '../../../models/trang_thai_ho_so.dart';

class DieuPhoiService {
  final FirebaseFirestore db;
  DieuPhoiService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;
  final Map<String, Future<Set<String>>> _skillsByUser = {};
  String get actor => currentAdminUid();
  Stream<BanGhi?> watch(String id) => db
      .collection('YeuCauCuuHo')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? BanGhi.fromDoc(d) : null);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCaseInvitations(String id) =>
      db
          .collectionGroup('DanhSachPhanCong')
          .where('maYeuCau', isEqualTo: id)
          .snapshots();
  String get dispatchDay => DateTime.now()
      .toUtc()
      .add(const Duration(hours: 7))
      .toIso8601String()
      .substring(0, 10);

  final _pending = <String, Map<String, dynamic>>{};
  bool _expiring = false;
  DateTime? _lastExpiryAttempt;

  void trackInvitation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data != null &&
        pendingAssignmentCodes.contains(data['maTrangThaiTiepNhan'])) {
      _pending[doc.reference.path] = data;
    } else {
      _pending.remove(doc.reference.path);
    }
  }

  Future<void> expireRows(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> rows,
  ) async {
    final invitations = [
      for (final row in rows)
        if (pendingAssignmentCodes.contains(
              row.data()?['maTrangThaiTiepNhan'],
            ) &&
            row.data()?['maPhanCong'] is String)
          {'path': row.reference.path, 'id': row.data()!['maPhanCong']},
    ];
    for (var i = 0; i < invitations.length; i += 20) {
      await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('ketThucLoiMoiHetHan')
          .call({'invitations': invitations.skip(i).take(20).toList()});
    }
  }

  Future<void> expireDue() async {
    final now = DateTime.now();
    if (_expiring ||
        (_lastExpiryAttempt != null &&
            now.difference(_lastExpiryAttempt!).inSeconds < 5)) {
      return;
    }
    final due = _pending.entries
        .where((entry) {
          final deadline = hanLoiMoi(entry.value);
          return deadline == null || !deadline.isAfter(now);
        })
        .take(20)
        .toList();
    if (due.isEmpty) return;
    _expiring = true;
    _lastExpiryAttempt = now;
    try {
      final response =
          await FirebaseFunctions.instanceFor(
            region: 'asia-southeast1',
          ).httpsCallable('ketThucLoiMoiHetHan').call({
            'invitations': [
              for (final entry in due)
                {'path': entry.key, 'id': entry.value['maPhanCong']},
            ],
          });
      final data = response.data;
      if (data is Map && data['finished'] is List) {
        for (final row in data['finished'] as List) {
          if (row is Map && _pending[row['path']]?['maPhanCong'] == row['id']) {
            _pending.remove(row['path']);
          }
        }
      }
    } finally {
      _expiring = false;
    }
  }

  Query<Map<String, dynamic>> dayAssignments(String uid, String day) => db
      .collectionGroup('DanhSachPhanCong')
      .where('maNguoiCuuHo', isEqualTo: uid)
      .where('maTrangThaiTiepNhan', whereIn: openAssignmentCodes);

  bool blocksInvitation(DocumentSnapshot<Map<String, dynamic>> request) => ![
    'hoan_thanh',
    'da_huy',
  ].contains(normalizeRequestStatus(request.data()?['maTinhTrangYeuCau']));

  Stream<Map<String, String>> watchBusy(List<String> ids, String day) =>
      gopLuong<Map<String, String>>([
        for (final uid in ids)
          chuyenLuong(dayAssignments(uid, day).snapshots(), (page) {
            _pending.removeWhere((_, data) => data['maNguoiCuuHo'] == uid);
            for (final row in page.docs) {
              trackInvitation(row);
            }
            return gopLuong<String?>([
              for (final row in page.docs)
                db.collection('YeuCauCuuHo').doc(row.id).snapshots().map((
                  request,
                ) {
                  if (!blocksInvitation(request)) return null;
                  if (!request.exists) {
                    return 'Không xác định được trạng thái ca ${row.id}';
                  }
                  return pendingAssignmentCodes.contains(
                        row.data()['maTrangThaiTiepNhan'],
                      )
                      ? 'Đang chờ phản hồi lời mời cho ca ${row.id}'
                      : 'Đang hỗ trợ ca ${row.id}';
                }),
            ]).map(
              (values) => {
                if (values.whereType<String>().isNotEmpty)
                  uid: values.whereType<String>().join(' · '),
              },
            );
          }),
      ]).map((rows) => {for (final row in rows) ...row});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProfiles(
    String collection,
  ) => db.collection(collection).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRestrictions() =>
      db.collection('HanCheNguoiDung').snapshots();

  Stream<BanGhi?> invitation(String id) => db
      .collectionGroup('DanhSachPhanCong')
      .where('maPhanCong', isEqualTo: id)
      .limit(1)
      .snapshots()
      .map((page) {
        for (final row in page.docs) {
          trackInvitation(row);
        }
        return page.docs.isEmpty ? null : BanGhi.fromDoc(page.docs.first);
      });

  DocumentReference<Map<String, dynamic>> daily(
    String uid,
    String day,
    String ca,
  ) => db
      .collection('ChiTietPhanCongCuuHo')
      .doc(uid)
      .collection('DanhSachNgay')
      .doc(day)
      .collection('DanhSachPhanCong')
      .doc(ca);

  Stream<QuerySnapshot<Map<String, dynamic>>> users(
    int limit,
    double latitude,
    double km,
  ) async* {
    final base = db
        .collection('NguoiDung')
        .where('viDo', isGreaterThanOrEqualTo: latitude - km / 110)
        .where('viDo', isLessThanOrEqualTo: latitude + km / 110)
        .orderBy('viDo')
        .limit(limit);
    final byRescuerRole = base.where(
      'maVaiTro',
      whereIn: const ['vaitro_cuuhococc', 'vaitro_cuuhochuacocc'],
    );
    try {
      await for (final page in byRescuerRole.snapshots()) {
        yield page;
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
      await for (final page in base.snapshots()) {
        yield page;
      }
    }
  }

  Future<Set<String>> _skills(String uid) {
    if (_skillsByUser.length > 300) _skillsByUser.clear();
    return _skillsByUser.putIfAbsent(uid, () async {
      try {
        final skillPages = await Future.wait([
          db
              .collection('ChiTietKyNang')
              .where('maNguoiDung', isEqualTo: uid)
              .get(),
          db
              .collection('ChiTietKyNang')
              .doc(uid)
              .collection('DanhSachKyNang')
              .get(),
          db
              .collection('ChiTietKyNangCuuHo')
              .where('maNguoiDung', isEqualTo: uid)
              .get(),
        ]);
        final skillIds = <String>{};
        for (var pageIndex = 0; pageIndex < skillPages.length; pageIndex++) {
          for (final doc in skillPages[pageIndex].docs) {
            final data = doc.data();
            final rawId = data['maKyNangCuuHo'] ?? data['maKyNang'];
            final id = rawId is String && rawId.trim().isNotEmpty
                ? rawId.trim()
                : (pageIndex > 0 ? doc.id : '');
            if (id.isNotEmpty && !id.contains('/')) skillIds.add(id);
          }
        }
        return skillIds;
      } catch (_) {
        _skillsByUser.remove(uid);
        rethrow;
      }
    });
  }

  Future<UngVienDieuPhoi?> candidate(
    QueryDocumentSnapshot<Map<String, dynamic>> user,
    YeuCauHoTro request,
    double km,
  ) async {
    final point = YeuCauHoTro(user.id, user.data());
    final raw = user.data();
    final role = raw['maVaiTro'];
    if (!const ['vaitro_cuuhococc', 'vaitro_cuuhochuacocc'].contains(role) ||
        raw['isOnline'] != true ||
        raw['nhanCaCuuHo'] == true ||
        !point.hasLocation ||
        !request.hasLocation ||
        user.id == maNanNhan(request.data)) {
      return null;
    }
    final distance = khoangCachKm(
      request.latitude!,
      request.longitude!,
      point.latitude!,
      point.longitude!,
    );
    if (distance > km) return null;
    final docs = await Future.wait([
      db.collection('HoSoCuuHoCoCCHN').doc(user.id).get(),
      db.collection('HoSoCuuHoKhongCCHN').doc(user.id).get(),
      db.collection('HanCheNguoiDung').doc(user.id).get(),
      db.collection('Admin').doc(user.id).get(),
    ]);
    if (docs[3].exists) return null;
    final professional = docs[0].data();
    final volunteer = docs[1].data();
    final approvedProfessional =
        professional != null &&
        normalizeProfileStatus(professional['maTrangThaiHoSo']) == 'da_duyet';
    final approvedVolunteer =
        volunteer != null &&
        normalizeProfileStatus(volunteer['maTrangThaiHoSo']) == 'da_duyet';
    if (!approvedProfessional && !approvedVolunteer) return null;
    final skillIds = await _skills(user.id);
    return UngVienDieuPhoi(
      uid: user.id,
      name: '${user.data()['hoTen'] ?? user.id}',
      unit: '${professional?['donViCongTac'] ?? volunteer?['doiNhom'] ?? ''}',
      coCCHN: approvedProfessional,
      khongCCHN: approvedVolunteer,
      restrictionReason: docs[2].data()?['khoa'] == true
          ? 'Tài khoản bị khóa'
          : docs[2].data()?['tamNgungHoTro'] == true
          ? 'Đang tạm ngưng hỗ trợ'
          : '',
      ready: false,
      eligible: sanSangHoTro(
        user.data(),
        docs[2].data() ?? {},
        hasOpenAssignment: false,
      ),
      latitude: point.latitude!,
      longitude: point.longitude!,
      distance: distance,
      skills: skillIds,
    );
  }

  Future<Map<String, String>> skills() async {
    final result = await db.collection('KyNangCuuHo').get();
    return {
      for (final d in result.docs) d.id: '${d.data()['tenKyNang'] ?? d.id}',
    };
  }

  Future<Map<String, DiemDanhGiaCuuHo>> ratings(List<String> uids) async {
    if (uids.isEmpty) return {};
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (var i = 0; i < uids.length; i += 10) {
      final group = uids.skip(i).take(10).toList();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews;
      try {
        final page = await db
            .collectionGroup('DanhSachYeuCau')
            .where('maNguoiCuuHo', whereIn: group)
            .get(const GetOptions(source: Source.server));
        reviews = page.docs;
      } on FirebaseException catch (error) {
        if (error.code != 'failed-precondition' ||
            !(error.message?.toLowerCase().contains('index') ?? false)) {
          rethrow;
        }
        // Without a collection-group index, read the same records by rescuer.
        final pages = await Future.wait(
          group.map(
            (uid) => db
                .collection('DanhGia')
                .doc(uid)
                .collection('DanhSachYeuCau')
                .get(const GetOptions(source: Source.server)),
          ),
        );
        reviews = [for (final page in pages) ...page.docs];
      }
      for (final row in reviews) {
        final uid = row.data()['maNguoiCuuHo'];
        final score = row.data()['diemDanhGia'];
        if (uid is String && score is num) {
          sums[uid] = (sums[uid] ?? 0) + score.toDouble();
          counts[uid] = (counts[uid] ?? 0) + 1;
        }
      }
    }
    return {
      for (final uid in sums.keys)
        uid: DiemDanhGiaCuuHo(sums[uid]! / counts[uid]!, counts[uid]!),
    };
  }

  Future<int> sendTop3Invitations(
    String id, {
    required List<String> uids,
    required double radius,
    required bool additional,
  }) async {
    final result =
        await FirebaseFunctions.instanceFor(
          region: 'asia-southeast1',
        ).httpsCallable('adminMoiTop3CuuHo').call({
          'maYeuCau': id,
          'uids': uids,
          'radius': radius,
          'additional': additional,
        });
    final data = result.data;
    return data is Map && data['soLoiMoi'] is num
        ? (data['soLoiMoi'] as num).toInt()
        : uids.length;
  }

  Future<void> act(
    String id,
    String action, {
    String? uid,
    String? invitationId,
    String? invitationPath,
    double radius = 5,
    bool additional = false,
  }) async {
    if (action == 'invite' && !const [1.0, 3.0, 5.0].contains(radius)) {
      throw StateError('Bán kính phải là 1, 3 hoặc 5 km.');
    }
    final adminId = actor;
    final ref = db.collection('YeuCauCuuHo').doc(id);
    final day = dispatchDay;

    QuerySnapshot<Map<String, dynamic>>? requestOpenSnapshot;
    QuerySnapshot<Map<String, dynamic>>? targetOpenSnapshot;
    if (action == 'invite' || action == 'complete') {
      requestOpenSnapshot = await db
          .collectionGroup('DanhSachPhanCong')
          .where('maYeuCau', isEqualTo: id)
          .where('maTrangThaiTiepNhan', whereIn: openAssignmentCodes)
          .limit(100)
          .get(const GetOptions(source: Source.server));

      if (action == 'invite' && uid != null) {
        targetOpenSnapshot = await dayAssignments(
          uid,
          day,
        ).get(const GetOptions(source: Source.server));
      }
    }

    if (action == 'invite' || action == 'complete') {
      await expireRows([
        ...?requestOpenSnapshot?.docs,
        ...?targetOpenSnapshot?.docs,
      ]);
    }
    await db.runTransaction((tx) async {
      final admin = await tx.get(db.collection('Admin').doc(adminId));
      final request = await tx.get(ref);
      final data = request.data();
      if (admin.data()?['trangThai'] != 'hoat_dong' || data == null) {
        throw StateError('Không thể cập nhật yêu cầu.');
      }
      final version = (data['phienBanDieuPhoi'] as num? ?? 0).toInt() + 1;
      final pendingId = data['maLoiMoiDieuPhoi'];
      final owner = data['maAdminDieuPhoi'];
      if (owner != null && owner != '' && owner != adminId) {
        throw StateError('Ca đã có Admin khác phụ trách.');
      }
      if (action == 'complete') {
        final status = normalizeRequestStatus(data['maTinhTrangYeuCau']);
        if (!requestStatuses.containsKey(status) ||
            ['hoan_thanh', 'da_huy'].contains(status)) {
          throw StateError('Yêu cầu không còn mở.');
        }
        final openRows = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final candidate
            in requestOpenSnapshot?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final current = await tx.get(candidate.reference);
          final currentData = current.data();
          if (current.exists &&
              currentData?['maYeuCau'] == id &&
              openAssignmentCodes.contains(
                currentData?['maTrangThaiTiepNhan'],
              )) {
            openRows.add(current);
          }
        }
        if (openRows.any(
          (row) => pendingAssignmentCodes.contains(
            row.data()?['maTrangThaiTiepNhan'],
          ),
        )) {
          throw StateError(
            'Hãy xử lý tất cả lời mời đang chờ trước khi hoàn thành.',
          );
        }
        tx.update(ref, {
          'maTinhTrangYeuCau': 'user_tinhtrang_hoanthanh',
          'maAdminHoanThanh': adminId,
          'thoiGianHoanThanh': FieldValue.serverTimestamp(),
          'canBoSungNhanLuc': false,
          'canKiemTra': false,
          'ngayDieuPhoi': FieldValue.serverTimestamp(),
          'phienBanDieuPhoi': version,
        });
        return;
      }
      if (!coTheDieuPhoi(data['maTinhTrangYeuCau'])) {
        throw StateError('Ca không còn đủ điều kiện điều phối.');
      }
      if (action == 'claim') {
        if (owner != null && owner != '') {
          throw StateError('Ca đã có Admin phụ trách.');
        }
        tx.update(ref, {
          'maAdminDieuPhoi': adminId,
          'phienBanDieuPhoi': version,
          'ngayDieuPhoi': FieldValue.serverTimestamp(),
        });
        return;
      }
      if (owner != adminId) {
        throw StateError('Hãy nhận điều phối trước.');
      }
      DocumentSnapshot<Map<String, dynamic>>? pending;
      final lastUid = data['nguoiDuocMoi'], lastDay = data['ngayGuiLoiMoi'];
      if (action == 'cancel' && invitationPath != null) {
        if (!RegExp(
          r'^ChiTietPhanCongCuuHo/[^/]+/DanhSachNgay/\d{4}-\d{2}-\d{2}/DanhSachPhanCong/[^/]+$',
        ).hasMatch(invitationPath)) {
          throw StateError('Đường dẫn lời mời không hợp lệ.');
        }
        pending = await tx.get(db.doc(invitationPath));
      } else if (pendingId is String && pendingId.isNotEmpty) {
        if (lastUid is String && lastDay is String) {
          pending = await tx.get(daily(lastUid, lastDay, id));
        } else if (invitationPath != null) {
          pending = await tx.get(db.doc(invitationPath));
        }
      }
      if (action == 'cancel' &&
          (pending?.data()?['maPhanCong'] != invitationId ||
              pending?.data()?['maYeuCau'] != id ||
              pending?.data()?['maAdmin'] != adminId)) {
        throw StateError('Lời mời đã thay đổi. Hãy tải lại ca.');
      }
      final status = assignmentStatus(pending?.data()?['maTrangThaiTiepNhan']);
      if (action == 'invite') {
        if (pending != null && status == 'da_gui_thong_bao') {
          throw StateError(
            'Hãy xử lý lời mời hiện tại trước khi gửi lời mời khác.',
          );
        }
        if (uid == null || uid == maNanNhan(data)) {
          throw StateError('Người hỗ trợ không hợp lệ.');
        }
        final attempt =
            'phancong_${id}_${uid}_v${version.toString().padLeft(6, '0')}';
        final requestOpen = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final candidate
            in requestOpenSnapshot?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final current = await tx.get(candidate.reference);
          final currentData = current.data();
          if (current.exists &&
              currentData?['maYeuCau'] == id &&
              openAssignmentCodes.contains(
                currentData?['maTrangThaiTiepNhan'],
              )) {
            requestOpen.add(current);
          }
        }
        if (requestOpen.any(
          (d) =>
              pendingAssignmentCodes.contains(d.data()?['maTrangThaiTiepNhan']),
        )) {
          throw StateError('Ca còn lời mời đang chờ phản hồi.');
        }
        final alreadyAssigned = requestOpen.where(
          (d) =>
              activeAssignmentCodes.contains(d.data()?['maTrangThaiTiepNhan']),
        );
        if (alreadyAssigned.any((d) => d.data()?['maNguoiCuuHo'] == uid)) {
          throw StateError('Người này đã nhận ca.');
        }
        if (!additional && alreadyAssigned.isNotEmpty) {
          throw StateError('Ca đã có người nhận. Chọn chế độ hỗ trợ bổ sung.');
        }
        var targetHasOpenAssignment = false;
        for (final candidate
            in targetOpenSnapshot?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final current = await tx.get(candidate.reference);
          final currentData = current.data();
          if (current.exists &&
              currentData?['maNguoiCuuHo'] == uid &&
              openAssignmentCodes.contains(
                currentData?['maTrangThaiTiepNhan'],
              )) {
            final linked = await tx.get(
              db.collection('YeuCauCuuHo').doc(current.id),
            );
            if (blocksInvitation(linked)) {
              targetHasOpenAssignment = true;
              break;
            }
          }
        }
        if (targetHasOpenAssignment) {
          throw StateError(
            'Người này đang có lời mời hoặc đang hỗ trợ ca khác.',
          );
        }
        final person = await tx.get(db.collection('NguoiDung').doc(uid));
        final restriction = await tx.get(
          db.collection('HanCheNguoiDung').doc(uid),
        );
        final targetAdmin = await tx.get(db.collection('Admin').doc(uid));
        final pro = await tx.get(db.collection('HoSoCuuHoCoCCHN').doc(uid));
        final volunteer = await tx.get(
          db.collection('HoSoCuuHoKhongCCHN').doc(uid),
        );
        final proApproved =
            pro.exists &&
            normalizeProfileStatus(pro.data()?['maTrangThaiHoSo']) ==
                'da_duyet';
        final volunteerApproved =
            volunteer.exists &&
            normalizeProfileStatus(volunteer.data()?['maTrangThaiHoSo']) ==
                'da_duyet';
        if (!person.exists ||
            targetAdmin.exists ||
            (!proApproved && !volunteerApproved) ||
            !const [
              'vaitro_cuuhococc',
              'vaitro_cuuhochuacocc',
            ].contains(person.data()?['maVaiTro']) ||
            !sanSangHoTro(
              person.data()!,
              restriction.data() ?? {},
              hasOpenAssignment: false,
            )) {
          throw StateError('Người này không còn đủ điều kiện nhận ca.');
        }
        final point = YeuCauHoTro(uid, person.data()!);
        final incident = YeuCauHoTro(id, data);
        if (!point.hasLocation ||
            !incident.hasLocation ||
            khoangCachKm(
                  point.latitude!,
                  point.longitude!,
                  incident.latitude!,
                  incident.longitude!,
                ) >
                radius) {
          throw StateError('Người hỗ trợ đã ra ngoài bán kính tìm kiếm.');
        }
        final newInvitation = daily(uid, day, id);
        final prior = await tx.get(newInvitation);
        if (prior.exists &&
            !['da_huy', 'tu_choi', 'hoan_thanh'].contains(
              assignmentStatus(prior.data()?['maTrangThaiTiepNhan']),
            )) {
          throw StateError(
            'Người này còn lời mời hoặc phân công đang hoạt động.',
          );
        }
        tx.set(newInvitation, {
          if (prior.exists)
            'lichSuLoiMoi': [
              ...(prior.data()?['lichSuLoiMoi'] as List? ?? const []),
              {
                for (final key in [
                  'maPhanCong',
                  'maTrangThaiTiepNhan',
                  'thoiGianGui',
                  'thoiGianPhanHoi',
                ])
                  key: prior.data()?[key],
              },
            ],
          'maPhanCong': attempt,
          'maYeuCau': id,
          'maNguoiCuuHo': uid,
          'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_chotiepnhan',
          'maLoaiPhanCong': 'phancong_thucong',
          'loaiPhanCong': 'Điều phối thủ công',
          'maAdmin': adminId,
          'boSung': additional,
          'thoiGianGui': FieldValue.serverTimestamp(),
          'hanPhanHoi': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 3)),
          ),
        });
        tx.update(ref, {
          'maLoiMoiDieuPhoi': attempt,
          'nguoiDuocMoi': uid,
          'ngayGuiLoiMoi': day,
          'phienBanDieuPhoi': version,
          'ngayDieuPhoi': FieldValue.serverTimestamp(),
        });
      } else if (action == 'cancel') {
        if (pending == null ||
            !pendingAssignmentCodes.contains(
              pending.data()?['maTrangThaiTiepNhan'],
            )) {
          throw StateError('Lời mời đã thay đổi hoặc không còn chờ phản hồi.');
        }
        tx.update(pending.reference, {
          'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_dahuy',
          'thoiGianPhanHoi': FieldValue.serverTimestamp(),
        });
        final requestPatch = <String, dynamic>{
          'phienBanDieuPhoi': version,
          'ngayDieuPhoi': FieldValue.serverTimestamp(),
        };
        if (pendingId == invitationId) {
          requestPatch.addAll({
            'maLoiMoiDieuPhoi': null,
            'nguoiDuocMoi': null,
            'ngayGuiLoiMoi': null,
          });
        }
        tx.update(ref, requestPatch);
      } else {
        throw StateError('Thao tác không hợp lệ.');
      }
    });
  }
}
