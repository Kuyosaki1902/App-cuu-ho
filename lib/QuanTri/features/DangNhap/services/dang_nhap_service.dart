import '../../YeuCauHoTro/services/thong_bao_day_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhienQuanTri {
  final String uid, email, name, phone;
  const PhienQuanTri(this.uid, this.email, {this.name = '', this.phone = ''});
}

/// Abstraction used by the controller, allowing permission failures and
/// session recovery to be tested without a live Firebase project.
abstract class NguonDangNhap {
  Stream<User?> get changes;
  User? get currentUser;
  Stream<PhienQuanTri?> watchSession(User user);
  Future<void> login(String email, String password);
  Future<void> syncAdminMirror();
  Future<void> logout();
}

class DangNhapService implements NguonDangNhap {
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  DangNhapService({FirebaseAuth? auth, FirebaseFirestore? db})
    : auth = auth ?? FirebaseAuth.instance,
      db = db ?? FirebaseFirestore.instance;

  // Only account transitions, not profile/token updates for the same UID.
  @override
  Stream<User?> get changes => auth.authStateChanges();

  @override
  User? get currentUser => auth.currentUser;

  Stream<bool> active(String uid) => db
      .collection('Admin')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data()?['trangThai'] == 'hoat_dong');

  // One listener for BOTH initial verification and later revocations.
  // A cached/offline Admin document must never grant access to the UI.
  @override
  Stream<PhienQuanTri?> watchSession(User user) => db
      .collection('Admin')
      .doc(user.uid)
      .snapshots(includeMetadataChanges: true)
      .where(
        (doc) => !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites,
      )
      .map((doc) {
        final data = doc.data();
        if (data?['trangThai'] != 'hoat_dong') return null;
        final email = data?['email'];
        return PhienQuanTri(
          user.uid,
          email is String ? email : user.email ?? '',
          name: '${data?['hoTen'] ?? ''}',
          phone: '${data?['soDienThoai'] ?? ''}',
        );
      });

  @override
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> syncAdminMirror() async {
    await FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('dongBoHoSoAdmin').call();
  }

  @override
  Future<void> logout() async {
    try {
      await ThongBaoDayService.instance.unregister();
    } finally {
      await auth.signOut();
    }
  }
}
