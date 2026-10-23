// lib/NguoiThanCuaBan/controllers/nguoi_than_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';

// Class chứa kết quả tìm kiếm kèm trạng thái quan hệ
class SearchUserResult {
  final NguoiDungModel user;
  final String status; // 'connected' | 'pending' | 'received' | 'none'

  SearchUserResult({required this.user, required this.status});
}

// 🌟 CONTROLLER QUẢN LÝ LOGIC BOTTOM SHEET CHỌN MỐI QUAN HỆ CỦA NGƯỜI THÂN
class BottomSheetGuiYeuCauController extends ChangeNotifier {
  String myRelation = 'Con';
  String targetRelation = 'Cha';

  // Danh sách đầy đủ các mối quan hệ phía "Bạn là"
  final List<String> myRelationOptions = [
    'Con',
    'Cha',
    'Mẹ',
    'Anh',
    'Chị',
    'Em',
    'Chồng',
    'Vợ',
    'Cháu',
    'Ông',
    'Bà',
    'Bạn bè',
    'Khác',
  ];

  // Logic lọc danh sách đối ứng vế phải
  List<String> getTargetOptions() {
    switch (myRelation) {
      case 'Con':
        return ['Cha', 'Mẹ'];
      case 'Cha':
      case 'Mẹ':
        return ['Con'];
      case 'Anh':
      case 'Chị':
        return ['Em'];
      case 'Em':
        return ['Anh', 'Chị'];
      case 'Chồng':
        return ['Vợ'];
      case 'Vợ':
        return ['Chồng'];
      case 'Cháu':
        return ['Ông', 'Bà'];
      case 'Ông':
      case 'Bà':
        return ['Cháu'];
      case 'Bạn bè':
        return ['Bạn bè'];
      default:
        return ['Khác'];
    }
  }

  // Xử lý chọn quan hệ phía mình
  void updateMyRelation(String newMyRel) {
    myRelation = newMyRel;
    List<String> targetOpts = getTargetOptions();
    if (!targetOpts.contains(targetRelation)) {
      targetRelation = targetOpts.first;
    }
    notifyListeners();
  }

  // Xử lý chọn quan hệ phía đối phương
  void updateTargetRelation(String newTargetRel) {
    targetRelation = newTargetRel;
    notifyListeners();
  }

  // Xử lý hoán đổi 2 chiều (Swap)
  void swapRelations() {
    String tempMy = targetRelation;
    String tempTarget = myRelation;

    if (!myRelationOptions.contains(tempMy)) {
      tempMy = 'Khác';
    }

    myRelation = tempMy;
    List<String> targetOpts = getTargetOptions();
    if (!targetOpts.contains(tempTarget)) {
      tempTarget = targetOpts.first;
    }
    targetRelation = tempTarget;

    notifyListeners();
  }
}

class NguoiThanController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. TÌM KIẾM & KIỂM TRA TRẠNG THÁI MỐI QUAN HỆ CÙNG LÚC
  Future<SearchUserResult?> searchUserByPhoneOrEmail({
    required String query,
    required String currentUserId,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    DocumentSnapshot<Map<String, dynamic>>? userDocSnap;

    // A. Query tìm NguoiDung theo SĐT
    final phoneQuery = await _firestore
        .collection('NguoiDung')
        .where('soDienThoai', isEqualTo: cleanQuery)
        .limit(1)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      userDocSnap = phoneQuery.docs.first;
    } else {
      // B. Query tìm NguoiDung theo Email nếu SĐT không có
      final emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: cleanQuery)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        userDocSnap = emailQuery.docs.first;
      }
    }

    if (userDocSnap == null || userDocSnap.data() == null) return null;

    final data = userDocSnap.data()!;
    final String targetUserId =
        (data['maNguoiDung'] != null &&
            data['maNguoiDung'].toString().isNotEmpty)
        ? data['maNguoiDung']
        : userDocSnap.id;
    data['maNguoiDung'] = targetUserId;

    final userModel = NguoiDungModel.fromMap(data);

    // C. GỘP LẤY TRẠNG THÁI QUAN HỆ PHÍA MÌNH VÀ ĐỐI PHƯƠNG CÙNG LÚC (Parallel Execution)
    String status = 'none';
    if (currentUserId.isNotEmpty && targetUserId.isNotEmpty) {
      final results = await Future.wait([
        _firestore
            .collection('NguoiThan')
            .doc(currentUserId)
            .collection('DanhSachNguoiThan')
            .doc(targetUserId)
            .get(),
        _firestore
            .collection('NguoiThan')
            .doc(targetUserId)
            .collection('DanhSachNguoiThan')
            .doc(currentUserId)
            .get(),
      ]);

      final myDoc = results[0];
      final targetDoc = results[1];

      final myStatus = myDoc.exists ? (myDoc.data()?['trangThai'] ?? '') : '';
      final targetStatus = targetDoc.exists
          ? (targetDoc.data()?['trangThai'] ?? '')
          : '';

      if (myStatus == 'trangthai2' && targetStatus == 'trangthai2') {
        status = 'connected'; // Đã là người thân
      } else if (myStatus == 'trangthai2' && targetStatus == 'trangthai1') {
        status = 'pending'; // Đã gửi yêu cầu
      } else if (myStatus == 'trangthai1') {
        status = 'received'; // Đã nhận yêu cầu từ đối phương
      }
    }

    return SearchUserResult(user: userModel, status: status);
  }

  // 2. GỬI YÊU CẦU SONG SONG 2 BÊN
  Future<void> sendRelationRequest({
    required String currentUserId,
    required String targetUserId,
    required String myRelation,
    required String targetRelation,
  }) async {
    final batch = _firestore.batch();

    final senderRef = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(targetUserId);

    batch.set(senderRef, {
      'moiQuanHe': myRelation,
      'trangThai': 'trangthai2',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    final receiverRef = _firestore
        .collection('NguoiThan')
        .doc(targetUserId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    batch.set(receiverRef, {
      'moiQuanHe': targetRelation,
      'trangThai': 'trangthai1',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 3. STREAM LẤY DANH SÁCH NGƯỜI THÂN ĐÃ KẾT NỐI
  Stream<List<Map<String, dynamic>>> getRelativesStream(String currentUserID) {
    if (currentUserID.trim().isEmpty) return Stream.value([]);

    return _firestore
        .collection('NguoiThan')
        .doc(currentUserID)
        .collection('DanhSachNguoiThan')
        .where('trangThai', isEqualTo: 'trangthai2')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          final fetchFutures = snapshot.docs.map((doc) async {
            try {
              final data = doc.data();
              final String maNguoiThan = doc.id;
              final String moiQuanHe = data['moiQuanHe'] ?? 'Chưa xác định';

              final otherDoc = await _firestore
                  .collection('NguoiThan')
                  .doc(maNguoiThan)
                  .collection('DanhSachNguoiThan')
                  .doc(currentUserID)
                  .get();

              if (!otherDoc.exists ||
                  otherDoc.data()?['trangThai'] != 'trangthai2') {
                return null;
              }

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

  // 4. STREAM LẤY DANH SÁCH YÊU CẦU PENDING
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
            for (var doc in mySnapshot.docs) {
              final data = doc.data();
              final String otherUserId = doc.id;

              if (data['trangThai'] == 'trangthai1') {
                final userDoc = await _firestore
                    .collection('NguoiDung')
                    .doc(otherUserId)
                    .get();

                if (userDoc.exists && userDoc.data() != null) {
                  requestsList.add({
                    'type': 'received',
                    'user': NguoiDungModel.fromMap(userDoc.data()!),
                    'moiQuanHe': data['moiQuanHe'] ?? '',
                    'senderId': otherUserId,
                  });
                }
              } else if (data['trangThai'] == 'trangthai2') {
                final otherDoc = await _firestore
                    .collection('NguoiThan')
                    .doc(otherUserId)
                    .collection('DanhSachNguoiThan')
                    .doc(currentUserId)
                    .get();

                if (otherDoc.exists &&
                    otherDoc.data()?['trangThai'] == 'trangthai1') {
                  final userDoc = await _firestore
                      .collection('NguoiDung')
                      .doc(otherUserId)
                      .get();

                  if (userDoc.exists && userDoc.data() != null) {
                    requestsList.add({
                      'type': 'sent',
                      'user': NguoiDungModel.fromMap(userDoc.data()!),
                      'moiQuanHe': data['moiQuanHe'] ?? '',
                      'targetId': otherUserId,
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

  // 5. CHẤP NHẬN YÊU CẦU
  Future<void> acceptRequest(String currentUserId, String senderId) async {
    await _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId)
        .update({'trangThai': 'trangthai2'});
  }

  // 6. TỪ CHỐI / THU HỒI -> XÓA 2 BÊN
  Future<void> rejectOrCancelRequest(String user1, String user2) async {
    final batch = _firestore.batch();

    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(user1)
        .collection('DanhSachNguoiThan')
        .doc(user2);

    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(user2)
        .collection('DanhSachNguoiThan')
        .doc(user1);

    batch.delete(ref1);
    batch.delete(ref2);

    await batch.commit();
  }

  int tinhTuoi(DateTime ngaySinh) {
    final now = DateTime.now();
    int age = now.year - ngaySinh.year;
    if (now.month < ngaySinh.month ||
        (now.month == ngaySinh.month && now.day < ngaySinh.day)) {
      age--;
    }
    return age;
  }
}
