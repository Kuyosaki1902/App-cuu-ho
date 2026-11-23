import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String currentAdminUid() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw StateError('Vui lòng đăng nhập Admin.');
  return uid;
}

Future<void> checkAdminTransaction(
  FirebaseFirestore db,
  Transaction tx,
  String actor,
  String target,
) async {
  if (actor == target) {
    throw StateError('Không thao tác trên chính tài khoản Admin.');
  }
  final admin = await tx.get(db.collection('Admin').doc(actor));
  final other = await tx.get(db.collection('Admin').doc(target));
  if (admin.data()?['trangThai'] != 'hoat_dong' || other.exists) {
    throw StateError('Không có quyền xử lý tài khoản này.');
  }
}
