import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'account.dart';

class AccountPage {
  final List<Account> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  const AccountPage(this.items, this.cursor, this.hasMore);
}

class AccountRepository {
  final FirebaseFirestore db;
  final FirebaseFunctions functions;
  AccountRepository({FirebaseFirestore? db, FirebaseFunctions? functions})
    : db = db ?? FirebaseFirestore.instance,
      functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  Future<Account> hydrate(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final profiles = await Future.wait([
      db
          .collection('HoSoCuuHoCoCCHN')
          .doc(doc.id)
          .get(const GetOptions(source: Source.server)),
      db
          .collection('HoSoCuuHoKhongCCHN')
          .doc(doc.id)
          .get(const GetOptions(source: Source.server)),
    ]);
    return Account(doc.id, doc.data()!, profiles[0].data(), profiles[1].data());
  }

  Future<Account> get(String uid) async {
    final doc = await db
        .collection('NguoiDung')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) throw StateError('Không tìm thấy tài khoản.');
    return hydrate(doc);
  }

  Future<AccountPage> page({
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query = db
        .collection('NguoiDung')
        .orderBy(FieldPath.documentId)
        .limit(20);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get(const GetOptions(source: Source.server));
    final accounts = await Future.wait(result.docs.map(hydrate));
    return AccountPage(
      accounts,
      result.docs.isEmpty ? after : result.docs.last,
      result.docs.length == 20,
    );
  }

  Future<Map<String, String>> roles() async {
    final docs = await db
        .collection('VaiTro')
        .get(const GetOptions(source: Source.server));
    return {for (final d in docs.docs) d.id: textOf(d.data(), 'vaiTro', d.id)};
  }

  Future<void> action(Account account, String action, String reason) async {
    await functions
        .httpsCallable(
          'adminAccountAction',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 125)),
        )
        .call({
          'uid': account.uid,
          'action': action,
          'reason': reason,
          'version': account.version,
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> logs(String uid) => db
      .collection('NguoiDung')
      .doc(uid)
      .collection('NhatKyQuanTri')
      .orderBy('thoiGian', descending: true)
      .limit(30)
      .snapshots();
}
