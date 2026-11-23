import 'package:cloud_firestore/cloud_firestore.dart';

String friendlyError(Object e) {
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'Không có quyền truy cập. Kiểm tra tài khoản Admin và Security Rules.';
    }
    if (e.code == 'unavailable') {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    return 'Lỗi Firebase: ${e.code}';
  }
  return e is StateError
      ? e.message.toString()
      : 'Không tải được dữ liệu. Hãy thử lại.';
}
