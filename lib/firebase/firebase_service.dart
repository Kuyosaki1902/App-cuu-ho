// lib/firebase/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart'; // Import RTDB
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
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app/',
    // ^ Replace link từ Firebase Console của Bảo vào giữa 2 dấu ngoặc đơn ở trên nhé!
  ); // RTDB Reference

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

  /// Lấy danh sách cứu hộ viên đang Online
  Future<List<NguoiDungModel>> getOnlineRescuers() async {
    List<NguoiDungModel> rescuers = [];
    try {
      final snap = await _firestore
          .collection('NguoiDung')
          .where('isOnline', isEqualTo: true)
          .where(
            'maVaiTro',
            whereIn: ['vaitro_cuuhococc', 'vaitro_cuhochuacocc'],
          )
          .get();

      for (var doc in snap.docs) {
        rescuers.add(NguoiDungModel.fromMap(doc.data(), doc.id));
      }
    } catch (e) {
      print('Lỗi FirebaseService.getOnlineRescuers: $e');
    }
    return rescuers;
  }

  // ===========================================================================
  // 2. YEU CAU CUU HO & CHI TIET MO TA HIEN TRUONG & LƯU ẢNH
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

  /// Lấy danh sách ảnh thuộc về maMoTa (chứa dữ liệu Base64)
  Future<List<LuuAnhModel>> getImagesByMoTaId(String maMoTa) async {
    List<LuuAnhModel> list = [];
    try {
      final snap = await _firestore
          .collection('LuuAnh')
          .where('maMoTa', isEqualTo: maMoTa)
          .get();

      for (var doc in snap.docs) {
        list.add(LuuAnhModel.fromMap(doc.data(), doc.id));
      }
    } catch (e) {
      print('Lỗi FirebaseService.getImagesByMoTaId: $e');
    }
    return list;
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

  Stream<List<ChiTietPhanCongCuuHoModel>> streamPhanCongByYeuCau(
    String maYeuCau,
  ) {
    return _firestore
        .collection('ChiTietPhanCongCuuHo')
        .where('maYeuCau', isEqualTo: maYeuCau)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ChiTietPhanCongCuuHoModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  Future<void> updateTinhTrangYeuCau(
    String maYeuCau,
    String maTinhTrang,
  ) async {
    try {
      await _firestore.collection('YeuCauCuuHo').doc(maYeuCau).update({
        'maTinhTrangYeuCau': maTinhTrang,
      });
    } catch (e) {
      print('Lỗi FirebaseService.updateTinhTrangYeuCau: $e');
    }
  }

  /// 🌟 Tạo Phân Công Theo Ngày với Document ID là maYeuCau và đổi nhanCaCuuHo = true
  Future<void> createPhanCongTheoNgay({
    required String maNguoiCuuHo,
    required ChiTietPhanCongCuuHoModel phanCong,
  }) async {
    try {
      final String todayStr = DateTime.now().toString().substring(0, 10);

      // 🌟 Path chuẩn: ChiTietPhanCongCuuHo/{maNguoiCuuHo}/DanhSachNgay/{todayStr}/DanhSachPhanCong/{maYeuCau}
      await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(maNguoiCuuHo)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(phanCong.maYeuCau)
          .set(phanCong.toMap(), SetOptions(merge: true));

      // 🌟 Đổi trạng thái nhanCaCuuHo thành true trên NguoiDung
      await _firestore.collection('NguoiDung').doc(maNguoiCuuHo).update({
        'nhanCaCuuHo': true,
      });

      print(
        '✅ Đã nạp thành công phân công hôm nay ($todayStr) cho $maNguoiCuuHo!',
      );
    } catch (e) {
      print('❌ Lỗi FirebaseService.createPhanCongTheoNgay: $e');
    }
  }

  /// Hủy tất cả phân công còn lại khi đã đủ 5 người nhận
  Future<void> cancelRemainingAssignments(String maYeuCau) async {
    try {
      final snap = await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .where('maYeuCau', isEqualTo: maYeuCau)
          .where(
            'maTrangThaiTiepNhan',
            isEqualTo: 'cuuho_trangthai_phancong_chotiepnhan',
          )
          .get();

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {
          'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_dahuy',
        });
      }
      await batch.commit();
    } catch (e) {
      print('Lỗi FirebaseService.cancelRemainingAssignments: $e');
    }
  }

  // ===========================================================================
  // 4. HO SO CUU HO & QUẢN LÝ CỨU HỘ VIÊN
  // ===========================================================================

  Future<HoSoCuuHoCoCCHNModel?> getHoSoCoCCHN(String userId) async {
    try {
      final snap = await _firestore
          .collection('HoSoCuuHoCoCCHN')
          .where('maNguoiDung', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        return HoSoCuuHoCoCCHNModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getHoSoCoCCHN: $e');
    }
    return null;
  }

  Future<HoSoCuuHoKhongCCHNModel?> getHoSoKhongCCHN(String userId) async {
    try {
      final snap = await _firestore
          .collection('HoSoCuuHoKhongCCHN')
          .where('maNguoiDung', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        return HoSoCuuHoKhongCCHNModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getHoSoKhongCCHN: $e');
    }
    return null;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHoSoCoCCHNSnapshot() async {
    return await _firestore.collection('HoSoCuuHoCoCCHN').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHoSoKhongCCHNSnapshot() async {
    return await _firestore.collection('HoSoKhongCCHN').get();
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
  // 5. QUẢN LÝ NGƯỜI THÂN & THÔNG BÁO REALTIME DATABASE
  // ===========================================================================

  /// 🌟 TRUY VẾT NGƯỜI THÂN VÀ BẮN THÔNG BÁO TỐI GIẢN CHỈ GỒM maYeuCau VÀ maNanNhan
  Future<void> notifyConnectedRelatives({
    required String maNguoiYeuCau, // maNanNhan
    required String maYeuCau,
    required double viDo,
    required double kinhDo,
  }) async {
    try {
      // 1. Truy vết danh sách người thân đã kết nối (trangthai2) từ Firestore[cite: 28]
      final snap = await _firestore
          .collection('NguoiThan')
          .doc(maNguoiYeuCau)
          .collection('DanhSachNguoiThan')
          .where('trangThai', isEqualTo: 'trangthai2')
          .get();

      if (snap.docs.isEmpty) return;

      // 2. Ghi trực tiếp 2 trường maYeuCau và maNanNhan vào node ThongBaoKhanCap/$maNguoiThan
      for (var doc in snap.docs) {
        String maNguoiThan = doc.id;

        DatabaseReference notifRef = _realtimeDb.ref(
          'ThongBaoKhanCap/$maNguoiThan',
        );

        await notifRef.set({'maYeuCau': maYeuCau, 'maNanNhan': maNguoiYeuCau});
      }
      print('✅ Đã phát thông báo tối giản tới ${snap.docs.length} người thân!');
    } catch (e) {
      print('❌ Lỗi notifyConnectedRelatives RTDB: $e');
    }
  }

  /// 🌟 XÓA NODE THÔNG BÁO CỦA NGƯỜI THÂN KHI HỦY HOẶC HOÀN THÀNH CA
  Future<void> removeEmergencyNotification({required String maNanNhan}) async {
    try {
      // 1. Lấy danh sách người thân đã nhận thông báo
      final snap = await _firestore
          .collection('NguoiThan')
          .doc(maNanNhan)
          .collection('DanhSachNguoiThan')
          .where('trangThai', isEqualTo: 'trangthai2')
          .get();

      // 2. Xóa node ThongBaoKhanCap/$maNguoiThan
      for (var doc in snap.docs) {
        String maNguoiThan = doc.id;
        await _realtimeDb.ref('ThongBaoKhanCap/$maNguoiThan').remove();
      }
      print('✅ Đã xóa node thông báo RTDB của người thân!');
    } catch (e) {
      print('❌ Lỗi xóa thông báo RTDB: $e');
    }
  }

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

  Future<void> updateYeuCauLocation({
    required String maYeuCau,
    required double viDo,
    required double kinhDo,
  }) async {
    try {
      await _firestore.collection('YeuCauCuuHo').doc(maYeuCau).update({
        'viDo': viDo,
        'kinhDo': kinhDo,
      });
    } catch (e) {
      print('Lỗi FirebaseService.updateYeuCauLocation: $e');
    }
  }

  // ===========================================================================
  // 6. QUẢN LÝ KỸ NĂNG CỨU HỘ
  // ===========================================================================

  Future<List<String>> getSkillIdsByUserId(String userId) async {
    List<String> skillIds = [];
    try {
      final snap = await _firestore
          .collection('ChiTietKiNang')
          .doc(userId)
          .collection('DanhSachKiNang')
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        String maKN =
            (data['maKiNangCuuHo'] != null &&
                data['maKiNangCuuHo'].toString().isNotEmpty)
            ? data['maKiNangCuuHo'].toString()
            : doc.id;
        skillIds.add(maKN);
      }
    } catch (e) {
      print('Lỗi FirebaseService.getSkillIdsByUserId: $e');
    }
    return skillIds;
  }

  Future<List<String>> getSkillNamesByIds(List<String> skillIds) async {
    List<String> skillNames = [];
    if (skillIds.isEmpty) return skillNames;

    try {
      for (var i = 0; i < skillIds.length; i += 30) {
        var chunk = skillIds.sublist(
          i,
          i + 30 > skillIds.length ? skillIds.length : i + 30,
        );

        var snap = await _firestore
            .collection('KyNangCuuHo')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snap.docs) {
          final data = doc.data();
          if (data['ten'] != null)
            skillNames.add(data['ten'].toString().toLowerCase());
          if (data['moTa'] != null)
            skillNames.add(data['moTa'].toString().toLowerCase());
        }
      }
    } catch (e) {
      print('Lỗi FirebaseService.getSkillNamesByIds: $e');
    }
    return skillNames;
  }
  // ===========================================================================
  // 7. LẤY AVATAR NGƯỜI DÙNG (TỪ LuuAnhModel)
  // ===========================================================================

  Future<String?> getUserAvatarUrl(String userId) async {
    try {
      final snap = await _firestore
          .collection('LuuAnh')
          .where('maNguoiDung', isEqualTo: userId)
          .where('maPhanLoaiAnh', isEqualTo: 'phanloaianh_avatar')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.first.data()['anhURL'] as String?;
      }
    } catch (e) {
      print('Lỗi getUserAvatarUrl: $e');
    }
    return null; // Trả về null nếu không có ảnh
  }

  Future<void> updateDanhSachPhanCongVien({
    required String maYeuCau,
    required String maNguoiCuuHo,
    required String trangThai,
  }) async {
    try {
      await _firestore.collection('YeuCauCuuHo').doc(maYeuCau).update({
        'danhSachPhanCongVien.$maNguoiCuuHo': trangThai,
      });
    } catch (e) {
      print('Lỗi updateDanhSachPhanCongVien: $e');
    }
  }
}
