// lib/NguoiThanCuaBan/controllers/nguoi_than_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';

class NguoiThanController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. STREAM LẤY DANH SÁCH NGƯỜI THÂN ĐÃ KẾT NỐI (Chỉ lấy maTrangThai == 'trangthai2')
  Stream<List<Map<String, dynamic>>> getRelativesStream(String currentUserID) {
    if (currentUserID.trim().isEmpty) return Stream.value([]);

    return _firestore
        .collection('NguoiThan')
        .doc(currentUserID)
        .collection('DanhSachNguoiThan')
        .where('trangThai', isEqualTo: 'trangthai2') // trangthai2: Đồng ý
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          final fetchFutures = snapshot.docs.map((doc) async {
            try {
              final data = doc.data();
              final String maNguoiThan = doc.id;
              final String moiQuanHe = data['moiQuanHe'] ?? 'Chưa xác định';

              final userDoc = await _firestore
                  .collection('NguoiDung')
                  .doc(maNguoiThan)
                  .get();

              if (userDoc.exists && userDoc.data() != null) {
                final userData = NguoiDungModel.fromMap(userDoc.data()!);
                return {
                  'relation': moiQuanHe,
                  'id': userData.maNguoiDung,
                  'name': userData.hoTen,
                  'age': tinhTuoi(userData.ngaySinh),
                  'phone': userData.soDienThoai,
                  'email': userData.email,
                  'avatarUrl': 'https://i.pravatar.cc/150',
                };
              }
            } catch (e) {
              print('Lỗi fetch người thân: $e');
            }
            return null;
          }).toList();

          final results = await Future.wait(fetchFutures);
          return results.whereType<Map<String, dynamic>>().toList();
        });
  }

  // 2. GỬI YÊU CẦU: TẠO BẢN GHI PHÍA NGƯỜI GỬI VỚI maTrangThai = 'trangthai1' (Chờ Xem Xét)
  Future<void> sendRelationRequest({
    required String currentUserId,
    required String targetUserId,
    required String myRelation,
    required String targetRelation,
  }) async {
    await _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(targetUserId)
        .set({
          'moiQuanHe': myRelation,
          'targetRelation': targetRelation,
          'trangThai': 'trangthai1', // trangthai1: Chờ Xem Xét
          'ngayTao': FieldValue.serverTimestamp(),
        });
  }

  // 3. STREAM LẤY DANH SÁCH YÊU CẦU ĐÃ GỬI VÀ ĐÃ NHẬN
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream(
    String currentUserId,
  ) {
    if (currentUserId.trim().isEmpty) return Stream.value([]);

    return _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .snapshots()
        .asyncMap((mySnapshot) async {
          List<Map<String, dynamic>> requestsList = [];

          try {
            // A. XỬ LÝ YÊU CẦU ĐÃ GỬI (Gõ yêu cầu có trangThai == 'trangthai1')
            for (var doc in mySnapshot.docs) {
              final data = doc.data();
              if (data['trangThai'] == 'trangthai1') {
                final targetId = doc.id;
                final userDoc = await _firestore
                    .collection('NguoiDung')
                    .doc(targetId)
                    .get();
                if (userDoc.exists && userDoc.data() != null) {
                  DateTime? ngayTao;
                  if (data['ngayTao'] is Timestamp) {
                    ngayTao = (data['ngayTao'] as Timestamp).toDate();
                  }

                  requestsList.add({
                    'type': 'sent',
                    'user': NguoiDungModel.fromMap(userDoc.data()!),
                    'moiQuanHe': data['moiQuanHe'] ?? '',
                    'targetId': targetId,
                    'ngayTao': ngayTao,
                  });
                }
              }
            }

            // B. XỬ LÝ YÊU CẦU ĐÃ NHẬN (Quét danh sách tìm người dùng gửi yêu cầu 'trangthai1' tới mình)
            final allUsersDoc = await _firestore.collection('NguoiThan').get();
            for (var userParentDoc in allUsersDoc.docs) {
              final senderId = userParentDoc.id;
              if (senderId == currentUserId) continue;

              final checkReceivedDoc = await _firestore
                  .collection('NguoiThan')
                  .doc(senderId)
                  .collection('DanhSachNguoiThan')
                  .doc(currentUserId)
                  .get();

              if (checkReceivedDoc.exists && checkReceivedDoc.data() != null) {
                final data = checkReceivedDoc.data()!;
                if (data['trangThai'] == 'trangthai1') {
                  final userDoc = await _firestore
                      .collection('NguoiDung')
                      .doc(senderId)
                      .get();
                  if (userDoc.exists && userDoc.data() != null) {
                    DateTime? ngayTao;
                    if (data['ngayTao'] is Timestamp) {
                      ngayTao = (data['ngayTao'] as Timestamp).toDate();
                    }

                    requestsList.add({
                      'type': 'received',
                      'user': NguoiDungModel.fromMap(userDoc.data()!),
                      'moiQuanHe':
                          data['targetRelation'] ?? data['moiQuanHe'] ?? '',
                      'senderId': senderId,
                      'ngayTao': ngayTao,
                    });
                  }
                }
              }
            }
          } catch (e) {
            print('Lỗi query pending requests: $e');
          }

          return requestsList;
        });
  }

  // 4. CHẤP NHẬN YÊU CẦU -> Cập nhật maTrangThai thành 'trangthai2' (Đồng ý)
  Future<void> acceptRequest(String currentUserId, String senderId) async {
    final batch = _firestore.batch();

    final senderRef = _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    final snap = await senderRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      final targetRel = data['targetRelation'] ?? 'Chưa xác định';

      // 1. Đổi phía người gửi thành 'trangthai2' (Đồng ý)
      batch.update(senderRef, {'trangThai': 'trangthai2'});

      // 2. Tạo bản ghi cho người nhận với 'trangthai2' (Đồng ý)
      final myRef = _firestore
          .collection('NguoiThan')
          .doc(currentUserId)
          .collection('DanhSachNguoiThan')
          .doc(senderId);

      batch.set(myRef, {
        'moiQuanHe': targetRel,
        'trangThai': 'trangthai2',
        'ngayTao': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  // 5. TỪ CHỐI / THU HỒI -> Xóa sạch bản ghi
  Future<void> rejectOrCancelRequest(String senderId, String targetId) async {
    await _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(targetId)
        .delete();
  }

  // Tìm kiếm người dùng theo 100% SĐT/Email
  Future<NguoiDungModel?> searchUserByPhoneOrEmail(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final phoneQuery = await _firestore
        .collection('NguoiDung')
        .where('soDienThoai', isEqualTo: cleanQuery)
        .limit(1)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      return NguoiDungModel.fromMap(phoneQuery.docs.first.data());
    }

    final emailQuery = await _firestore
        .collection('NguoiDung')
        .where('email', isEqualTo: cleanQuery)
        .limit(1)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      return NguoiDungModel.fromMap(emailQuery.docs.first.data());
    }

    return null;
  }

  int tinhTuoi(DateTime ngaySinh) {
    final now = DateTime.now();
    int age = now.year - ngaySinh.year;
    if (now.month < ngaySinh.month ||
        (now.month == ngaySinh.month && now.day < ngaySinh.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }
}
