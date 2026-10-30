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
  String selectedPairLabel = 'Cha / Con';

  // Danh sách các cặp mối quan hệ hiển thị ở Dropdown phía trên
  final List<String> pairOptions = [
    'Cha / Con',
    'Mẹ / Con',
    'Anh / Em',
    'Chị / Em',
    'Chồng / Vợ',
    'Ông / Cháu',
    'Bà / Cháu',
    'Bạn bè / Bạn bè',
    'Khác / Khác',
  ];

  // Cắt chuỗi theo ký tự "/" để gán trực tiếp vai trò
  void updatePair(String pairLabel) {
    selectedPairLabel = pairLabel;
    List<String> parts = pairLabel.split('/');

    if (parts.length == 2) {
      targetRelation = parts[0].trim(); // Phía đối phương
      myRelation = parts[1].trim(); // Phía bạn
    }

    notifyListeners();
  }

  // Hoán đổi 2 chiều (Swap)
  void swapRelations() {
    String temp = myRelation;
    myRelation = targetRelation;
    targetRelation = temp;

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

      // Đã là người thân (Cả 2 đều đồng ý hoặc đang trong quá trình yêu cầu hủy)
      if ((myStatus == 'user_trangthai_nguoithan_dongy' && targetStatus == 'user_trangthai_nguoithan_dongy') ||
          (myStatus == 'user_trangthai_nguoithan_dongyhuy' && targetStatus == 'user_trangthai_nguoithan_huynguoithan') ||
          (myStatus == 'user_trangthai_nguoithan_huynguoithan' && targetStatus == 'user_trangthai_nguoithan_dongyhuy')) {
        status = 'connected'; 
      } 
      // Đã gửi yêu cầu kết nối
      else if (myStatus == 'user_trangthai_nguoithan_dongy' && targetStatus == 'user_trangthai_nguoithan_choketnoi') {
        status = 'pending'; 
      } 
      // Đã nhận yêu cầu kết nối
      else if (myStatus == 'user_trangthai_nguoithan_choketnoi' && targetStatus == 'user_trangthai_nguoithan_dongy') {
        status = 'received'; 
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
      'trangThai': 'user_trangthai_nguoithan_dongy',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    final receiverRef = _firestore
        .collection('NguoiThan')
        .doc(targetUserId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    batch.set(receiverRef, {
      'moiQuanHe': targetRelation,
      'trangThai': 'user_trangthai_nguoithan_choketnoi',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

 // 3. STREAM LẤY DANH SÁCH NGƯỜI THÂN ĐÃ KẾT NỐI
  Stream<List>> getRelativesStream(String currentUserID) {
    if (currentUserID.trim().isEmpty) {
      return Stream<List>>.value([]);
    }

    return _firestore
        .collection('NguoiThan')
        .doc(currentUserID)
        .collection('DanhSachNguoiThan')
        .where('trangThai', whereIn: [
          'user_trangthai_nguoithan_dongy',
          'user_trangthai_nguoithan_dongyhuy',
          'user_trangthai_nguoithan_huynguoithan'
        ])
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return >[];
          }

          List<Future?>> fetchFutures = snapshot.docs.map((doc) async {
            try {
              Map<String, dynamic> data = doc.data();
              String maNguoiThan = doc.id;
              String moiQuanHe = data['moiQuanHe'] ?? 'Chưa xác định';
              String trangThai = data['trangThai'] ?? '';

              var userDoc = await _firestore
                  .collection('NguoiDung')
                  .doc(maNguoiThan)
                  .get();

              if (userDoc.exists && userDoc.data() != null) {
                NguoiDungModel userData = NguoiDungModel.fromMap(userDoc.data()!);
                return <String, dynamic>{
                  'relation': moiQuanHe,
                  'id': userData.maNguoiDung,
                  'name': userData.hoTen,
                  'age': tinhTuoi(userData.ngaySinh),
                  'phone': userData.soDienThoai,
                  'email': userData.email,
                  'avatarUrl': 'https://i.pravatar.cc/150',
                  'trangThai': trangThai,
                };
              }
            } catch (e) {
              print('Lỗi fetch người thân: $e');
            }
            return null;
          }).toList();

          List?> results = await Future.wait(fetchFutures);
          
          List> validResults = >[];
          for (var item in results) {
            if (item != null) {
              validResults.add(item);
            }
          }

          return validResults;
        });
  }
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream(
    String currentUserId,
  ) {
    if (currentUserId.trim().isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .snapshots()
        .asyncMap((mySnapshot) async {
          final futures = mySnapshot.docs.map((doc) async {
            final otherUserId;
            try {
              final data = doc.data();
              final otherUserId = doc.id;
              final trangThai = data['trangThai'] ?? '';

              String? type;
              String? subType;
              String? idField;

              // 1. Nhận yêu cầu kết nối
              if (trangThai == 'user_trangthai_nguoithan_choketnoi') {
                type = 'received';
                subType = 'connect';
                idField = 'senderId';
              }
              // 2. Đã gửi yêu cầu kết nối
              else if (trangThai == 'user_trangthai_nguoithan_dongy') {
                final otherDoc = await _firestore
                    .collection('NguoiThan')
                    .doc(otherUserId)
                    .collection('DanhSachNguoiThan')
                    .doc(currentUserId)
                    .get();

                if (!otherDoc.exists ||
                    otherDoc.data()?['trangThai'] !=
                        'user_trangthai_nguoithan_choketnoi') {
                  return null;
                }

                type = 'sent';
                subType = 'connect';
                idField = 'targetId';
              }
              // 3. Mình gửi yêu cầu hủy
              else if (trangThai == 'user_trangthai_nguoithan_dongyhuy') {
                final otherDoc = await _firestore
                    .collection('NguoiThan')
                    .doc(otherUserId)
                    .collection('DanhSachNguoiThan')
                    .doc(currentUserId)
                    .get();

                if (!otherDoc.exists ||
                    otherDoc.data()?['trangThai'] !=
                        'user_trangthai_nguoithan_huynguoithan') {
                  return null;
                }

                type = 'sent';
                subType = 'cancel';
                idField = 'targetId';
              }
              // 4. Nhận yêu cầu hủy
              else if (trangThai == 'user_trangthai_nguoithan_huynguoithan') {
                type = 'received';
                subType = 'cancel';
                idField = 'senderId';
              }
              // Không thuộc danh sách yêu cầu
              else {
                return null;
              }

              // Lấy thông tin người dùng
              final userDoc = await _firestore
                  .collection('NguoiDung')
                  .doc(otherUserId)
                  .get();

              if (!userDoc.exists || userDoc.data() == null) {
                return null;
              }

              final result = <String, dynamic>{
                'type': type,
                'subType': subType,
                'user': NguoiDungModel.fromMap(userDoc.data()!),
                'moiQuanHe': data['moiQuanHe'] ?? '',
              };

              result[idField] = otherUserId;

              return result;
            } catch (e) {
              debugPrint('Lỗi lấy yêu cầu từ $currentUserId: $e');
              return null;
            }
          }).toList();

          final results = await Future.wait(futures);

          return results.whereType<Map<String, dynamic>>().toList();
        });
  }

  // ===========================================================================
  // CÁC HÀM XỬ LÝ TRẠNG THÁI (ĐỒNG BỘ MÃ CHUẨN)
  // ===========================================================================

  // 5. CHẤP NHẬN YÊU CẦU KẾT NỐI
  Future<void> acceptConnectRequest(
    String currentUserId,
    String senderId,
  ) async {
    final batch = _firestore.batch();
    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId);
    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    batch.update(ref1, {'trangThai': 'user_trangthai_nguoithan_dongy'});
    batch.update(ref2, {'trangThai': 'user_trangthai_nguoithan_dongy'});
    await batch.commit();
  }

  // 6. TỪ CHỐI YÊU CẦU KẾT NỐI
  Future<void> rejectConnectRequest(
    String currentUserId,
    String senderId,
  ) async {
    final batch = _firestore.batch();
    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId);
    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    // Cập nhật trạng thái từ chối trước để lưu vết
    batch.update(ref1, {'trangThai': 'user_trangthai_nguoithan_tuchoi'});
    batch.update(ref2, {'trangThai': 'user_trangthai_nguoithan_tuchoi'});

    // Sau đó xóa để dọn dẹp danh sách chờ
    batch.delete(ref1);
    batch.delete(ref2);
    await batch.commit();
  }

  // 7. THU HỒI YÊU CẦU KẾT NỐI ĐÃ GỬI
  Future<void> cancelConnectRequest(
    String currentUserId,
    String targetId,
  ) async {
    final batch = _firestore.batch();
    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(targetId);
    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(targetId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);
    batch.delete(ref1);
    batch.delete(ref2);
    await batch.commit();
  }

  // 8. GỬI YÊU CẦU HỦY NGƯỜI THÂN (Bấm xóa từ tab Người thân)
  Future<void> requestCancelRelation(
    String currentUserId,
    String targetId,
  ) async {
    await _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(targetId)
        .update({'trangThai': 'user_trangthai_nguoithan_huynguoithan'});
  }

  // 9. ĐỒNG Ý HỦY KẾT NỐI NGƯỜI THÂN
  Future<void> acceptCancelRelation(
    String currentUserId,
    String senderId,
  ) async {
    final batch = _firestore.batch();
    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId);
    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    // Cập nhật trạng thái đồng ý hủy
    batch.update(ref1, {'trangThai': 'user_trangthai_nguoithan_dongyhuy'});
    batch.update(ref2, {'trangThai': 'user_trangthai_nguoithan_dongyhuy'});

    // Xóa sạch để biến mất khỏi danh sách người thân
    batch.delete(ref1);
    batch.delete(ref2);
    await batch.commit();
  }

  // 10. TỪ CHỐI YÊU CẦU HỦY (Bỏ qua/Giữ lại làm người thân)
  Future<void> rejectCancelRelation(
    String currentUserId,
    String senderId,
  ) async {
    final batch = _firestore.batch();
    final ref1 = _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId);
    final ref2 = _firestore
        .collection('NguoiThan')
        .doc(senderId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId);

    // Lưu vết từ chối hủy
    batch.update(ref1, {'trangThai': 'user_trangthai_nguoithan_tuchoihuy'});
    batch.update(ref2, {'trangThai': 'user_trangthai_nguoithan_tuchoihuy'});

    // Khôi phục lại trạng thái đồng ý để tiếp tục hiển thị ở Tab Người thân
    batch.update(ref1, {'trangThai': 'user_trangthai_nguoithan_dongy'});
    batch.update(ref2, {'trangThai': 'user_trangthai_nguoithan_dongy'});
    await batch.commit();
  }

  // 11. HỦY BỎ YÊU CẦU HỦY (Mình đổi ý, không muốn xóa người thân nữa)
  Future<void> cancelCancelRequest(
    String currentUserId,
    String targetId,
  ) async {
    await _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(targetId)
        .update({'trangThai': 'user_trangthai_nguoithan_dongy'});
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
