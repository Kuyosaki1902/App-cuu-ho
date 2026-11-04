import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart';// Import RTDB
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/Models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/Models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/Models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/user/Models/luuanhmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _serviceId = 'service_mjq8s5n';
  final String _templateId = 'template_xgoatgh';
  final String _publicKey = 'ui8hvA1YiR6O-spA1';
  final String _privateKey = 'iGWSAbxAHAOt3koQgtpHz';
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // --- Các hàm cơ bản giữ nguyên ---
  Future<bool> taoTaiKhoan(NguoiDungModel nguoiDung) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('NguoiDung').get();
      int nextIdNumber = snapshot.docs.length + 1;
      String maNguoiDungMoi = 'nguoidung${nextIdNumber.toString()}';

      DocumentReference docRef = _firestore
          .collection('NguoiDung')
          .doc(maNguoiDungMoi);
      Map<String, dynamic> data = nguoiDung.toMap();
      data['maNguoiDung'] = maNguoiDungMoi;

      await docRef.set(data);
      return true;
    } catch (e) {
      print('Lỗi khi tạo mã: $e');
      return false;
    }
  }

  Future<NguoiDungModel?> dangNhap(String taiKhoan, String matKhau) async {
    try {
      QuerySnapshot phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(
          phoneQuery.docs.first.data() as Map<String, dynamic>,
        );
      }

      QuerySnapshot emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(
          emailQuery.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<NguoiDungModel?> layThongTinNguoiDungRealTime(String maNguoiDung) {
    try {
      return _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .snapshots()
          .map((querySnapshot) {
            if (querySnapshot.docs.isNotEmpty)
              return NguoiDungModel.fromMap(querySnapshot.docs.first.data());
            return null;
          });
    } catch (e) {
      return Stream.value(null);
    }
  }

  Future<NguoiDungModel?> timTaiKhoanQuenMatKhau(String taiKhoan) async {
    try {
      QuerySnapshot phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .get();
      if (phoneQuery.docs.isNotEmpty)
        return NguoiDungModel.fromMap(
          phoneQuery.docs.first.data() as Map<String, dynamic>,
        );

      QuerySnapshot emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .get();
      if (emailQuery.docs.isNotEmpty)
        return NguoiDungModel.fromMap(
          emailQuery.docs.first.data() as Map<String, dynamic>,
        );
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> capNhatMatKhau(String maNguoiDung, String matKhauMoi) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update({'matKhau': matKhauMoi});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> capNhatThongTinCaNhan(
    String maNguoiDung,
    Map<String, dynamic> dataUpdate,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update(dataUpdate);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> guiEmailOTP(String email, String otpCode) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': {'to_email': email, 'otp_code': otpCode},
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> taoVaGuiOTP(String email) async {
    try {
      String otpCode = (100000 + Random().nextInt(900000)).toString();
      DateTime expireTime = DateTime.now().add(const Duration(minutes: 5));
      await _firestore.collection('XacThucOTP').doc(email).set({
        'email': email,
        'otp': otpCode,
        'expireTime': expireTime,
        'createdAt': DateTime.now(),
      });
      bool sent = await guiEmailOTP(email, otpCode);
      return sent ? otpCode : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> xacNhanMaOTP(String email, String otpNhap) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('XacThucOTP')
          .doc(email)
          .get();
      if (!doc.exists || doc.data() == null) return false;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String otpLuu = data['otp'] ?? '';
      DateTime expireTime = (data['expireTime'] as Timestamp).toDate();
      if (otpNhap == otpLuu && DateTime.now().isBefore(expireTime)) {
        await _firestore.collection('XacThucOTP').doc(email).delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> capNhatViTriVaTrangThai(
    String maNguoiDung,
    double viDo,
    double kinhDo,
    String geohash,
    bool isOnline,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update({
              'viDo': viDo,
              'kinhDo': kinhDo,
              'geohash': geohash,
              'isOnline': isOnline,
            });
      }
    } catch (e) {}
  }

  Future<void> capNhatTrangThaiOnline(String maNguoiDung, bool isOnline) async {
    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await rtdb.ref('NguoiDung/$maNguoiDung/isOnline').set(isOnline);
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update({'isOnline': isOnline});
      }
    } catch (e) {}
  }

  Future<bool> capNhatVaiTro(String maNguoiDung, String maVaiTro) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();
      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update({'maVaiTro': maVaiTro});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== CÁC HÀM XỬ LÝ CHỐNG ĐĂNG NHẬP TRÙNG LẶP ====================

  // 1. Kiểm tra xem tài khoản có đang online trên RTDB không
  Future<bool> kiemTraDangOnlineRealtime(String maNguoiDung) async {
    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      final snapshot = await rtdb.ref('NguoiDung/$maNguoiDung/isOnline').get();
      return snapshot.value == true;
    } catch (e) {
      return false;
    }
  }

  // 2. Thiết lập trạng thái kèm Mã Thiết Bị
  void thietLapTrangThaiOnline(String maNguoiDung, String maThietBi) {
    final rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final connectedRef = rtdb.ref('.info/connected');
    final userRef = rtdb.ref('NguoiDung/$maNguoiDung');

    connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        // Chỉ đổi isOnline thành false khi rớt mạng, giữ nguyên maThietBi trên server
        userRef.child('isOnline').onDisconnect().set(false).then((_) {
          // Báo true và đính kèm maThietBi
          userRef.update({'isOnline': true, 'maThietBi': maThietBi});
        });
      }
    });
  }

  // 3. Hủy bỏ onDisconnect khi bị máy khác đá văng để không làm tắt nhầm trạng thái của máy mới
  Future<void> huyOnDisconnect(String maNguoiDung) async {
    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await rtdb.ref('NguoiDung/$maNguoiDung/isOnline').onDisconnect().cancel();
    } catch (e) {}
  }

  // ==================== CÁC HÀM TẠO YÊU CẦU CỨU HỘ TỰ ĐỘNG ====================
  Future<String?> taoYeuCauTimBacSiTuDong({
    required String maNguoiYeuCau,
    required double viDo,
    required double kinhDo,
    List<String>? trieuChung,
    String? moTaChiTiet,
    File? fileAnh,
    File? fileGhiAm,
    String maLoaiYeuCau = 'loaiyeucau_timtudong',
  }) async {
    try {
      // 1. TÍNH MÃ YÊU CẦU TỰ TĂNG (yeucau1, yeucau2, yeucau3...)
      QuerySnapshot yeuCauSnapshot = await _firestore
          .collection('YeuCauCuuHo')
          .get();
      int maxIndex = 0;

      for (var doc in yeuCauSnapshot.docs) {
        String docId = doc.id;
        if (docId.startsWith('yeucau')) {
          int? numVal = int.tryParse(docId.replaceFirst('yeucau', ''));
          if (numVal != null && numVal > maxIndex) {
            maxIndex = numVal;
          }
        }
      }

      int nextIndex = maxIndex > 0
          ? maxIndex + 1
          : yeuCauSnapshot.docs.length + 1;
      String maYeuCau = 'yeucau$nextIndex'; // Đơn tiếp theo sẽ là yeucau6...

      WriteBatch batch = _firestore.batch();
      DocumentReference yeuCauRef = _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau);

      String? anhDownloadUrl;
      String? ghiAmDownloadUrl;

      // 2. UPLOAD ẢNH LÊN FIREBASE STORAGE
      if (fileAnh != null && await fileAnh.exists()) {
        try {
          print("👉 Đang upload ảnh lên Firebase Storage...");
          final String fileName =
              '${maYeuCau}_anh_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference ref = FirebaseStorage.instance.ref().child(
            'LuuAnh/$fileName',
          );

          final UploadTask uploadTask = ref.putFile(
            fileAnh,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final TaskSnapshot snapshot = await uploadTask;
          anhDownloadUrl = await snapshot.ref.getDownloadURL();
          print("✅ Upload ảnh thành công! URL: $anhDownloadUrl");
        } catch (e) {
          print('❌ Lỗi upload ảnh lên Storage: $e');
        }
      } else {
        print("⚠️ Không tìm thấy file ảnh hoặc người dùng không chụp ảnh.");
      }

      // 3. UPLOAD GHI ÂM LÊN FIREBASE STORAGE
      if (fileGhiAm != null && await fileGhiAm.exists()) {
        try {
          print("👉 Đang upload ghi âm lên Firebase Storage...");
          final String fileName =
              '${maYeuCau}_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final Reference ref = FirebaseStorage.instance.ref().child(
            'GhiAm/$fileName',
          );

          final UploadTask uploadTask = ref.putFile(
            fileGhiAm,
            SettableMetadata(contentType: 'audio/m4a'),
          );
          final TaskSnapshot snapshot = await uploadTask;
          ghiAmDownloadUrl = await snapshot.ref.getDownloadURL();
          print("✅ Upload ghi âm thành công! URL: $ghiAmDownloadUrl");
        } catch (e) {
          print('❌ Lỗi upload ghi âm lên Storage: $e');
        }
      } else {
        print("⚠️ Không tìm thấy file ghi âm hoặc người dùng không ghi âm.");
      }

      // 4. LƯU BẢNG YeuCauCuuHo
      batch.set(yeuCauRef, {
        'maYeuCau': maYeuCau,
        'thoiGianTao': FieldValue.serverTimestamp(),
        'viDo': viDo,
        'kinhDo': kinhDo,
        'mucDoKhanCap': 2,
        'soNguoiCanCuuHo': 3,
        'soNguoiCuuHo': 0,
        'maNguoiYeuCau': maNguoiYeuCau,
        'maAdminDieuPhoi': null,
        'thoiGianPhanCong': null,
        'thoiGianHoanThanh': null,
        'maLoaiYeuCau': maLoaiYeuCau,
        'maTinhTrangYeuCau': 'user_tinhtrang_chotiepnhan',
        'danhSachPhanCongVien': {},
      });

      // 5. LƯU BẢNG ChiTietMoTaHienTruong VỚI DOCUMENT ID LÀ maYeuCau
      bool hasMoTa =
          (trieuChung != null && trieuChung.isNotEmpty) ||
          (moTaChiTiet != null && moTaChiTiet.isNotEmpty) ||
          anhDownloadUrl != null ||
          ghiAmDownloadUrl != null;

      if (hasMoTa) {
        DocumentReference moTaRef = _firestore
            .collection('ChiTietMoTaHienTruong')
            .doc(maYeuCau);
        batch.set(moTaRef, {
          'maYeuCau': maYeuCau,
          'thoiGianTao': FieldValue.serverTimestamp(),
          'videoUrl': anhDownloadUrl, // Lưu URL ảnh vào trường videoUrl
          'ghiAmUrl': ghiAmDownloadUrl, // Lưu URL ghi âm
          'ghiChuText': {
            'trieuChung': trieuChung ?? [],
            'moTaChiTiet': moTaChiTiet ?? "",
          },
        });

        // 6. LƯU BẢNG LuuAnh VÀO COLLECTION LuuAnh
        if (anhDownloadUrl != null) {
          String idLuuAnh = 'anh_${DateTime.now().millisecondsSinceEpoch}_0';
          DocumentReference luuAnhRef = _firestore
              .collection('LuuAnh')
              .doc(idLuuAnh);
          batch.set(luuAnhRef, {
            'maAnh': idLuuAnh,
            'anhURL': anhDownloadUrl,
            'maNguoiDung': maNguoiYeuCau,
            'maPhanLoaiAnh': 'phanloaianh_hientruong',
            'maYeuCau': maYeuCau,
          });
        }
      }

      await batch.commit();
      print("🎉 Đã tạo thành công đơn: $maYeuCau");
      return maYeuCau; // 🌟 Trả về mã yêu cầu luôn
    } catch (e) {
      print("❌ Lỗi tạo đơn cứu hộ: $e");
      return null; // 🌟 Thất bại trả về null
    }
  }




  // ===========================================================================
  // --------------------------NGÔ THIÊN BẢO------------------------------
  // ===========================================================================





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
        return NguoiDungModel.fromMap(docSnap.data()!);
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

  Future<NguoiDungModel?> findUserByPhoneOrEmail(String query) async {
    try {
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) return null;

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
        rescuers.add(NguoiDungModel.fromMap(doc.data()));
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
        .collectionGroup(
          'DanhSachPhanCong',
        ) // 🌟 Đổi từ collection thành collectionGroup
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

  Future<void> createPhanCongTheoNgay({
    required String maNguoiCuuHo,
    required ChiTietPhanCongCuuHoModel phanCong,
  }) async {
    try {
      final String todayStr = DateTime.now().toString().substring(0, 10);
      await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(maNguoiCuuHo)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(phanCong.maYeuCau)
          .set(phanCong.toMap(), SetOptions(merge: true));

      await _firestore.collection('NguoiDung').doc(maNguoiCuuHo).update({
        'nhanCaCuuHo': true,
      });
    } catch (e) {
      print('❌ Lỗi FirebaseService.createPhanCongTheoNgay: $e');
    }
  }

  Future<void> cancelRemainingAssignments(String maYeuCau) async {
    try {
      final snap = await _firestore
          .collectionGroup(
            'DanhSachPhanCong',
          ) // 🌟 Đổi từ collection thành collectionGroup
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
      if (snap.docs.isNotEmpty)
        return HoSoCuuHoCoCCHNModel.fromMap(
          snap.docs.first.data(),
          snap.docs.first.id,
        );
    } catch (e) {}
    return null;
  }

  Future<HoSoCuuHoKhongCCHNModel?> getHoSoKhongCCHN(String userId) async {
    try {
      final snap = await _firestore
          .collection('HoSoCuuHoKhongCCHN')
          .where('maNguoiDung', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty)
        return HoSoCuuHoKhongCCHNModel.fromMap(
          snap.docs.first.data(),
          snap.docs.first.id,
        );
    } catch (e) {}
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
          if (doc.exists && doc.data() != null)
            users.add(NguoiDungModel.fromMap(doc.data()!));
        }
      }
    } catch (e) {}
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
        if (doc.data()['maNguoiDung'] != null)
          rescuerUserIds.add(doc.data()['maNguoiDung'].toString());
      }
      for (var doc in results[1].docs) {
        if (doc.data()['maNguoiDung'] != null)
          rescuerUserIds.add(doc.data()['maNguoiDung'].toString());
      }
    } catch (e) {}
    return rescuerUserIds;
  }

  // ===========================================================================
  // 5. QUẢN LÝ NGƯỜI THÂN & THÔNG BÁO REALTIME DATABASE
  // ===========================================================================

  Future<void> notifyConnectedRelatives({
    required String maNguoiYeuCau,
    required String maYeuCau,
    required double viDo,
    required double kinhDo,
  }) async {
    try {
      final snap = await _firestore
          .collection('NguoiThan')
          .doc(maNguoiYeuCau)
          .collection('DanhSachNguoiThan')
          .where('trangThai', isEqualTo: 'user_trangthai_nguoithan_dongy')
          .get();

      if (snap.docs.isEmpty) return;

      for (var doc in snap.docs) {
        String maNguoiThan = doc.id;
        DatabaseReference notifRef = _realtimeDb.ref(
          'ThongBaoKhanCap/$maNguoiThan',
        );
        await notifRef.set({'maYeuCau': maYeuCau, 'maNanNhan': maNguoiYeuCau});
      }
    } catch (e) {
      print('❌ Lỗi notifyConnectedRelatives RTDB: $e');
    }
  }

  Future<void> removeEmergencyNotification({required String maNanNhan}) async {
    try {
      final snap = await _firestore
          .collection('NguoiThan')
          .doc(maNanNhan)
          .collection('DanhSachNguoiThan')
          .where('trangThai', isEqualTo: 'user_trangthai_nguoithan_dongy')
          .get();

      for (var doc in snap.docs) {
        String maNguoiThan = doc.id;
        await _realtimeDb.ref('ThongBaoKhanCap/$maNguoiThan').remove();
      }
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
      return {'myStatus': '', 'targetStatus': ''};
    }
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

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRelativesByStatus(
    String currentUserId,
    List<String> statuses,
  ) {
    if (currentUserId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('NguoiThan')
        .doc(currentUserId)
        .collection('DanhSachNguoiThan')
        .where('trangThai', whereIn: statuses)
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

  Future<void> setTwoWayRelation({
    required String user1,
    required String user2,
    required String status1,
    required String status2,
    String? relation1,
    String? relation2,
  }) async {
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

    Map<String, dynamic> data1 = {'trangThai': status1};
    Map<String, dynamic> data2 = {'trangThai': status2};

    if (relation1 != null) {
      data1['moiQuanHe'] = relation1;
      data1['ngayTao'] = FieldValue.serverTimestamp();
    }
    if (relation2 != null) {
      data2['moiQuanHe'] = relation2;
      data2['ngayTao'] = FieldValue.serverTimestamp();
    }

    batch.set(ref1, data1, SetOptions(merge: true));
    batch.set(ref2, data2, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> deleteTwoWayRelation(String user1, String user2) async {
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
        String maKN =
            (doc.data()['maKiNangCuuHo'] != null &&
                doc.data()['maKiNangCuuHo'].toString().isNotEmpty)
            ? doc.data()['maKiNangCuuHo'].toString()
            : doc.id;
        skillIds.add(maKN);
      }
    } catch (e) {}
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
          if (doc.data()['ten'] != null)
            skillNames.add(doc.data()['ten'].toString().toLowerCase());
          if (doc.data()['moTa'] != null)
            skillNames.add(doc.data()['moTa'].toString().toLowerCase());
        }
      }
    } catch (e) {}
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
    return null;
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
    } catch (e) {}
  }
  // ===========================================================================
  // 8. QUẢN LÝ PHÒNG CHAT
  // ===========================================================================

  /// Lấy Stream danh sách tin nhắn (Sắp xếp cũ -> mới)
  Stream<List<ChiTietTinNhanModel>> streamTinNhan({
    required String maPhongChat,
    required String maNguoiCuuHo,
  }) {
    return _firestore
        .collection('PhongChatCuuHo')
        .doc(maPhongChat)
        .collection('DanhSachCuuHoVien')
        .doc(maNguoiCuuHo)
        .collection('ChiTietTinNhan')
        .orderBy('thoiGianGui', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ChiTietTinNhanModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Gửi tin nhắn mới
  Future<void> guiTinNhan({
    required String maPhongChat,
    required String maNguoiCuuHo,
    required ChiTietTinNhanModel tinNhan,
  }) async {
    try {
      final docRef = _firestore
          .collection('PhongChatCuuHo')
          .doc(maPhongChat)
          .collection('DanhSachCuuHoVien')
          .doc(maNguoiCuuHo)
          .collection('ChiTietTinNhan')
          .doc(); // Tự phát sinh ID

      await docRef.set(tinNhan.toMap());
    } catch (e) {
      print('Lỗi FirebaseService.guiTinNhan: $e');
    }
  }

  // ===========================================================================
  // 9. THÔNG BÁO YÊU CẦU KHẨN CẤP LÊN REALTIME DATABASE (Dành cho Tìm Kiếm)
  // ===========================================================================
  Future<void> sendRequestToRealtimeDB({
    required String maNanNhan,
    required String maYeuCau,
    required double viDo,
    required double kinhDo,
    required List<String> listCuuHoVienIds,
  }) async {
    try {
      DatabaseReference yeuCauRef = _realtimeDb.ref('YeuCauKhanCap/$maYeuCau');
      Map<String, dynamic> data = {
        'maNanNhan': maNanNhan,
        'viDo': viDo,
        'kinhDo': kinhDo,
        'danhSachCuuHoVien': listCuuHoVienIds,
      };
      await yeuCauRef.set(data);
    } catch (e) {
      print('❌ Lỗi FirebaseService.sendRequestToRealtimeDB: $e');
    }
  }

  Future<void> removeRequestFromRealtimeDB(String maYeuCau) async {
    try {
      await _realtimeDb.ref('YeuCauKhanCap/$maYeuCau').remove();
    } catch (e) {
      print('❌ Lỗi FirebaseService.removeRequestFromRealtimeDB: $e');
    }
  }
}
