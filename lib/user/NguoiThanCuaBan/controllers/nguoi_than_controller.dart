// lib/NguoiThanCuaBan/controllers/nguoi_than_controller.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';

class SearchUserResult {
  final NguoiDungModel user;
  final String status;
  final String? avatarUrl;

  SearchUserResult({required this.user, required this.status, this.avatarUrl});
}

class BottomSheetGuiYeuCauController extends ChangeNotifier {
  String myRelation = 'Con';
  String targetRelation = 'Cha';
  String selectedPairLabel = 'Cha / Con';

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

  void updatePair(String pairLabel) {
    selectedPairLabel = pairLabel;
    List<String> parts = pairLabel.split('/');
    if (parts.length == 2) {
      targetRelation = parts[0].trim();
      myRelation = parts[1].trim();
    }
    notifyListeners();
  }

  void swapRelations() {
    String temp = myRelation;
    myRelation = targetRelation;
    targetRelation = temp;
    notifyListeners();
  }
}

class NguoiThanController {
  final FirebaseService _fbService = FirebaseService();

  // 1. TÌM KIẾM NGƯỜI DÙNG
  Future<SearchUserResult?> searchUserByPhoneOrEmail({
    required String query,
    required String currentUserId,
  }) async {
    final userModel = await _fbService.findUserByPhoneOrEmail(query);
    if (userModel == null) return null;

    final targetUserId = userModel.maNguoiDung!;

    if (targetUserId == currentUserId) {
      return null;
    }
    String status = 'none';

    if (currentUserId.isNotEmpty && targetUserId.isNotEmpty) {
      final statuses = await _fbService.getRelationStatusBetweenUsers(
        currentUserId,
        targetUserId,
      );
      final myStatus = statuses['myStatus'] ?? '';
      final targetStatus = statuses['targetStatus'] ?? '';

      if ((myStatus == 'user_trangthai_nguoithan_dongy' &&
              targetStatus == 'user_trangthai_nguoithan_dongy') ||
          (myStatus == 'user_trangthai_nguoithan_dongyhuy' &&
              targetStatus == 'user_trangthai_nguoithan_huynguoithan') ||
          (myStatus == 'user_trangthai_nguoithan_huynguoithan' &&
              targetStatus == 'user_trangthai_nguoithan_dongyhuy')) {
        status = 'connected';
      } else if (myStatus == 'user_trangthai_nguoithan_dongy' &&
          targetStatus == 'user_trangthai_nguoithan_choketnoi') {
        status = 'pending';
      } else if (myStatus == 'user_trangthai_nguoithan_choketnoi' &&
          targetStatus == 'user_trangthai_nguoithan_dongy') {
        status = 'received';
      }
    }

    String? avatarUrl = await _fbService.getUserAvatarUrl(targetUserId);

    return SearchUserResult(
      user: userModel,
      status: status,
      avatarUrl: avatarUrl,
    );
  }

  // 2. GỬI YÊU CẦU KẾT NỐI SONG SONG
  Future<void> sendRelationRequest({
    required String currentUserId,
    required String targetUserId,
    required String myRelation,
    required String targetRelation,
  }) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: targetUserId,
      status1: 'user_trangthai_nguoithan_dongy',
      status2: 'user_trangthai_nguoithan_choketnoi',
      relation1: myRelation,
      relation2: targetRelation,
    );
  }

  // 3. STREAM LẤY DANH SÁCH NGƯỜI THÂN (Đã fix kiểm tra 2 chiều chuẩn xác)
  Stream<List<Map<String, dynamic>>> getRelativesStream(String currentUserID) {
    if (currentUserID.trim().isEmpty) return Stream.value([]);

    return _fbService
        .streamRelativesByStatus(currentUserID, [
          'user_trangthai_nguoithan_dongy',
          'user_trangthai_nguoithan_dongyhuy',
          'user_trangthai_nguoithan_huynguoithan',
        ])
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];

          final fetchFutures = snapshot.docs.map((doc) async {
            try {
              final data = doc.data();
              String maNguoiThan = doc.id;
              String myStatus = data['trangThai'] ?? '';

              // Nếu bên mình 'dongy' nhưng đối phương vẫn 'choketnoi' -> Bỏ qua chưa hiện ở Tab Người thân
              if (myStatus == 'user_trangthai_nguoithan_dongy') {
                final otherDoc = await _fbService.getOtherRelationDoc(
                  maNguoiThan,
                  currentUserID,
                );
                if (!otherDoc.exists) return null;
                final targetStatus = otherDoc.data()?['trangThai'] ?? '';
                if (targetStatus == 'user_trangthai_nguoithan_choketnoi') {
                  return null;
                }
              }

              NguoiDungModel? userData = await _fbService.getUserById(
                maNguoiThan,
              );

              if (userData != null) {
                String? avatar = await _fbService.getUserAvatarUrl(maNguoiThan);

                return <String, dynamic>{
                  'relation': data['moiQuanHe'] ?? 'Chưa xác định',
                  'id': userData.maNguoiDung,
                  'name': userData.hoTen,
                  'age': tinhTuoi(userData.ngaySinh),
                  'phone': userData.soDienThoai,
                  'email': userData.email,
                  'avatarUrl': avatar,
                  'trangThai': myStatus,
                };
              }
            } catch (e) {
              debugPrint('Lỗi fetch người thân: $e');
            }
            return null;
          }).toList();

          final results = await Future.wait(fetchFutures);
          return results.whereType<Map<String, dynamic>>().toList();
        });
  }

  // 4. STREAM LẤY DANH SÁCH YÊU CẦU CẦN XỬ LÝ
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream(
    String currentUserId,
  ) {
    if (currentUserId.trim().isEmpty) return Stream.value([]);

    return _fbService.streamAllRelatives(currentUserId).asyncMap((
      mySnapshot,
    ) async {
      final futures = mySnapshot.docs.map((doc) async {
        try {
          final data = doc.data();
          final otherUserId = doc.id;
          final trangThai = data['trangThai'] ?? '';

          String? type, subType, idField;

          if (trangThai == 'user_trangthai_nguoithan_choketnoi') {
            type = 'received';
            subType = 'connect';
            idField = 'senderId';
          } else if (trangThai == 'user_trangthai_nguoithan_dongy') {
            final otherDoc = await _fbService.getOtherRelationDoc(
              otherUserId,
              currentUserId,
            );
            if (!otherDoc.exists ||
                otherDoc.data()?['trangThai'] !=
                    'user_trangthai_nguoithan_choketnoi') {
              return null;
            }
            type = 'sent';
            subType = 'connect';
            idField = 'targetId';
          } else if (trangThai == 'user_trangthai_nguoithan_dongyhuy') {
            final otherDoc = await _fbService.getOtherRelationDoc(
              otherUserId,
              currentUserId,
            );
            if (!otherDoc.exists ||
                otherDoc.data()?['trangThai'] !=
                    'user_trangthai_nguoithan_huynguoithan') {
              return null;
            }
            type = 'sent';
            subType = 'cancel';
            idField = 'targetId';
          } else if (trangThai == 'user_trangthai_nguoithan_huynguoithan') {
            type = 'received';
            subType = 'cancel';
            idField = 'senderId';
          } else {
            return null;
          }

          NguoiDungModel? userData = await _fbService.getUserById(otherUserId);
          if (userData == null) return null;

          String? avatar = await _fbService.getUserAvatarUrl(otherUserId);

          final result = <String, dynamic>{
            'type': type,
            'subType': subType,
            'user': userData,
            'moiQuanHe': data['moiQuanHe'] ?? '',
            'avatarUrl': avatar,
          };
          result[idField!] = otherUserId;
          return result;
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Map<String, dynamic>>().toList();
    });
  }

  // 5. CÁC HÀM XỬ LÝ TRẠNG THÁI
  Future<void> acceptConnectRequest(
    String currentUserId,
    String senderId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: senderId,
      status1: 'user_trangthai_nguoithan_dongy',
      status2: 'user_trangthai_nguoithan_dongy',
    );
  }

  Future<void> rejectConnectRequest(
    String currentUserId,
    String senderId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: senderId,
      status1: 'user_trangthai_nguoithan_tuchoi',
      status2: 'user_trangthai_nguoithan_tuchoi',
    );
    await _fbService.deleteTwoWayRelation(currentUserId, senderId);
  }

  Future<void> cancelConnectRequest(
    String currentUserId,
    String targetId,
  ) async {
    await _fbService.deleteTwoWayRelation(currentUserId, targetId);
  }

  Future<void> requestCancelRelation(
    String currentUserId,
    String targetId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: targetId,
      status1: 'user_trangthai_nguoithan_dongyhuy',
      status2: 'user_trangthai_nguoithan_huynguoithan',
    );
  }

  Future<void> acceptCancelRelation(
    String currentUserId,
    String senderId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: senderId,
      status1: 'user_trangthai_nguoithan_dongyhuy',
      status2: 'user_trangthai_nguoithan_dongyhuy',
    );
    await _fbService.deleteTwoWayRelation(currentUserId, senderId);
  }

  Future<void> rejectCancelRelation(
    String currentUserId,
    String senderId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: senderId,
      status1: 'user_trangthai_nguoithan_dongy',
      status2: 'user_trangthai_nguoithan_dongy',
    );
  }

  Future<void> cancelCancelRequest(
    String currentUserId,
    String targetId,
  ) async {
    await _fbService.setTwoWayRelation(
      user1: currentUserId,
      user2: targetId,
      status1: 'user_trangthai_nguoithan_dongy',
      status2: 'user_trangthai_nguoithan_dongy',
    );
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
