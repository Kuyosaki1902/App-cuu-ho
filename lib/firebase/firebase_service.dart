// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/gioitinhmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/user/models/loaiyeucaumodel.dart';
import 'package:cuhokhancap/user/models/luuanhmodel.dart';
import 'package:cuhokhancap/user/models/moiquanhe.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/models/nguoithanmodel.dart';
import 'package:cuhokhancap/user/models/phanloaianhmodel.dart';
import 'package:cuhokhancap/user/models/tinhtrangyeucaumodel.dart';
import 'package:cuhokhancap/user/models/trangthaimodel.dart';
import 'package:cuhokhancap/user/models/vaitromodel.dart';
import 'package:cuhokhancap/user/models/yeucaucuuhomodel.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ===========================================================================
  // 1. NGUOI DUNG MODEL (NguoiDung)
  // ===========================================================================

  Future<NguoiDungModel?> getUserById(String userId) async {
    try {
      final docSnap = await _firestore
          .collection('NguoiDung')
          .doc(userId)
          .get();
      if (docSnap.exists && docSnap.data() != null) {
        return NguoiDungModel.fromMap(docSnap.data()!, docSnap.id);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getUserById: $e');
    }
    return null;
  }

  Future<void> saveUser(NguoiDungModel user) async {
    if (user.maNguoiDung == null || user.maNguoiDung!.isEmpty) return;
    await _firestore
        .collection('NguoiDung')
        .doc(user.maNguoiDung)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserLocation({
    required String userId,
    required double viDo,
    required double kinhDo,
    required String geohash,
  }) async {
    await _firestore.collection('NguoiDung').doc(userId).update({
      'viDo': viDo,
      'kinhDo': kinhDo,
      'geohash': geohash,
    });
  }

  Future<void> updateUserOnlineStatus({
    required String userId,
    required bool isOnline,
    bool? nhanCaCuuHo,
  }) async {
    Map<String, dynamic> updateData = {'isOnline': isOnline};
    if (nhanCaCuuHo != null) {
      updateData['nhanCaCuuHo'] = nhanCaCuuHo;
    }
    await _firestore.collection('NguoiDung').doc(userId).update(updateData);
  }

  /// Tìm kiếm NguoiDung theo SĐT hoặc Email
  Future<NguoiDungModel?> findUserByPhoneOrEmail(String query) async {
    try {
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) return null;

      // Tìm theo SĐT
      final phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: cleanQuery)
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        final doc = phoneQuery.docs.first;
        final data = doc.data();
        final String targetUserId =
            (data['maNguoiDung'] != null &&
                data['maNguoiDung'].toString().isNotEmpty)
            ? data['maNguoiDung']
            : doc.id;
        data['maNguoiDung'] = targetUserId;
        return NguoiDungModel.fromMap(data);
      }

      // Tìm theo Email
      final emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: cleanQuery)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final doc = emailQuery.docs.first;
        final data = doc.data();
        final String targetUserId =
            (data['maNguoiDung'] != null &&
                data['maNguoiDung'].toString().isNotEmpty)
            ? data['maNguoiDung']
            : doc.id;
        data['maNguoiDung'] = targetUserId;
        return NguoiDungModel.fromMap(data);
      }
    } catch (e) {
      print('Lỗi FirebaseService.findUserByPhoneOrEmail: $e');
    }
    return null;
  }

  // ===========================================================================
  // 2. YEU CAU CUU HO & CHI TIET MO TA HIEN TRUONG
  // ===========================================================================

  Future<YeuCauCuuHoModel?> getYeuCauCuuHoById(String maYeuCau) async {
    try {
      final docSnap = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();
      if (docSnap.exists && docSnap.data() != null) {
        return YeuCauCuuHoModel.fromMap(docSnap.data()!, docSnap.id);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getYeuCauCuuHoById: $e');
    }
    return null;
  }

  Future<void> saveYeuCauCuuHo(YeuCauCuuHoModel yeuCau) async {
    await _firestore
        .collection('YeuCauCuuHo')
        .doc(yeuCau.maYeuCau)
        .set(yeuCau.toMap(), SetOptions(merge: true));
  }

  Future<ChiTietMoTaHienTruongModel?> getMoTaHienTruongById(
    String maYeuCau,
  ) async {
    try {
      final docSnap = await _firestore
          .collection('ChiTietMoTaHienTruong')
          .doc(maYeuCau)
          .get();
      if (docSnap.exists && docSnap.data() != null) {
        return ChiTietMoTaHienTruongModel.fromMap(docSnap.data()!, docSnap.id);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getMoTaHienTruongById: $e');
    }
    return null;
  }

  Future<void> saveMoTaHienTruong(ChiTietMoTaHienTruongModel moTa) async {
    await _firestore
        .collection('ChiTietMoTaHienTruong')
        .doc(moTa.maYeuCau)
        .set(moTa.toMap(), SetOptions(merge: true));
  }

  // ===========================================================================
  // 3. CHI TIET PHAN CONG CUU HO MODEL
  // ===========================================================================

  Future<int> countAssignmentsByRescuer(String maNguoiCuuHo) async {
    try {
      final snap = await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .where('maNguoiCuuHo', isEqualTo: maNguoiCuuHo)
          .get();
      return snap.docs.length;
    } catch (e) {
      print('Lỗi FirebaseService.countAssignmentsByRescuer: $e');
      return 0;
    }
  }

  Future<void> createPhanCongCuuHo(ChiTietPhanCongCuuHoModel phanCong) async {
    await _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(phanCong.maPhanCong)
        .set(phanCong.toMap(), SetOptions(merge: true));
  }

  // ===========================================================================
  // 4. HO SO CUU HO & QUẢN LÝ CỨU HỘ VIÊN
  // ===========================================================================

  Future<QuerySnapshot<Map<String, dynamic>>> getHoSoCoCCHNSnapshot() async {
    return await _firestore.collection('HoSoCuuHoCoCCHN').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHoSoKhongCCHNSnapshot() async {
    return await _firestore.collection('HoSoCuuHoKhongCCHN').get();
  }

  Future<List<NguoiDungModel>> getUsersByIds(List<String> userIds) async {
    List<NguoiDungModel> users = [];
    try {
      for (var i = 0; i < userIds.length; i += 30) {
        var chunk = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );
        var userSnapshots = await _firestore
            .collection('NguoiDung')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in userSnapshots.docs) {
          if (doc.exists && doc.data() != null) {
            users.add(NguoiDungModel.fromMap(doc.data()!));
          }
        }
      }
    } catch (e) {
      print('Lỗi FirebaseService.getUsersByIds: $e');
    }
    return users;
  }

  Future<Set<String>> getAllRescuerUserIds() async {
    Set<String> rescuerUserIds = {};
    try {
      final results = await Future.wait([
        _firestore.collection('HoSoCuuHoCoCCHN').get(),
        _firestore.collection('HoSoCuuHoKhongCCHN').get(),
      ]);

      for (var doc in results[0].docs) {
        final data = doc.data();
        if (data['maNguoiDung'] != null &&
            data['maNguoiDung'].toString().isNotEmpty) {
          rescuerUserIds.add(data['maNguoiDung'].toString());
        }
      }

      for (var doc in results[1].docs) {
        final data = doc.data();
        if (data['maNguoiDung'] != null &&
            data['maNguoiDung'].toString().isNotEmpty) {
          rescuerUserIds.add(data['maNguoiDung'].toString());
        }
      }
    } catch (e) {
      print('Lỗi FirebaseService.getAllRescuerUserIds: $e');
    }
    return rescuerUserIds;
  }

  // ===========================================================================
  // 5. QUẢN LÝ NGƯỜI THÂN (NguoiThan)
  // ===========================================================================

  /// Lấy trạng thái mối quan hệ giữa 2 người dùng (Parallel Execution)
  Future<Map<String, String>> getRelationStatusBetweenUsers(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
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

      final myStatus = results[0].exists
          ? (results[0].data()?['trangThai'] ?? '')
          : '';
      final targetStatus = results[1].exists
          ? (results[1].data()?['trangThai'] ?? '')
          : '';

      return {'myStatus': myStatus, 'targetStatus': targetStatus};
    } catch (e) {
      print('Lỗi FirebaseService.getRelationStatusBetweenUsers: $e');
      return {'myStatus': '', 'targetStatus': ''};
    }
  }

  /// Gửi yêu cầu kết nối mối quan hệ song song 2 phía bằng Batch Write
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

  /// Stream lấy danh sách người thân đã kết nối (trangthai2)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamConnectedRelatives(
    String currentUserId,
  ) {
    if (currentUserId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .where('trangThai', isEqualTo: 'trangthai2')
        .snapshots();
  }

  /// Stream lấy toàn bộ danh sách mối quan hệ người thân
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllRelatives(
    String currentUserId,
  ) {
    if (currentUserId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .snapshots();
  }

  /// Lấy thông tin tài liệu người thân từ phía đối phương
  Future<DocumentSnapshot<Map<String, dynamic>>> getOtherRelationDoc(
    String otherUserId,
    String currentUserId,
  ) async {
    return await _firestore
        .collection('NguoiThan')
        .doc(otherUserId)
        .collection('DanhSachNguoiThan')
        .doc(currentUserId)
        .get();
  }

  /// Chấp nhận yêu cầu kết nối người thân
  Future<void> acceptRelationRequest(
    String currentUserId,
    String senderId,
  ) async {
    await _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .doc(senderId)
        .update({'trangThai': 'trangthai2'});
  }

  /// Xóa mối quan hệ người thân hai chiều bằng Batch
  Future<void> deleteRelationRequest(String user1, String user2) async {
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
}
