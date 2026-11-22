import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart'; // Import RTDB
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/Models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/Models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/Models/hosocuuhokhongcchnmodel.dart';
import 'package:cuhokhancap/user/Models/luuanhmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';
import 'package:cuhokhancap/user/Models/danhgiamodel.dart';
import 'package:cuhokhancap/user/Models/videohuongdanmodel.dart';

/// Dữ liệu hiển thị cho mục "Người thân khẩn cấp (SOS)"
class NguoiThanKhanCap {
  final String maNguoiThan;
  final String hoTen;
  final String soDienThoai;
  final String? moiQuanHe;
  final DateTime? ngayTao;

  NguoiThanKhanCap({
    required this.maNguoiThan,
    required this.hoTen,
    required this.soDienThoai,
    this.moiQuanHe,
    this.ngayTao,
  });
}

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
      // 1. Ưu tiên kiểm tra và cập nhật trực tiếp theo Document ID
      final docRef = _firestore.collection('NguoiDung').doc(maNguoiDung);
      final docSnap = await docRef.get().timeout(const Duration(seconds: 8));

      if (docSnap.exists) {
        await docRef
            .update({'matKhau': matKhauMoi})
            .timeout(const Duration(seconds: 8));
        return true;
      }

      // 2. Dự phòng: Tìm theo trường 'maNguoiDung' nếu docId khác maNguoiDung
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isNotEmpty) {
        await _firestore
            .collection('NguoiDung')
            .doc(query.docs.first.id)
            .update({'matKhau': matKhauMoi})
            .timeout(const Duration(seconds: 8));
        return true;
      }

      return false;
    } catch (e) {
      print('Lỗi capNhatMatKhau: $e');
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

  // ==================== KIỂM TRA TRẠNG THÁI HỒ SƠ & CHUYỂN VAI TRÒ ====================

  /// Kết quả kiểm tra hồ sơ cứu hộ
  /// Trả về Map: {'daDuyet': bool, 'coCCHN': bool}
  Future<Map<String, bool>> kiemTraTrangThaiHoSoCuuHo(
    String maNguoiDung,
  ) async {
    try {
      // 1. Kiểm tra trong bảng HoSoCuuHoCoCCHN
      QuerySnapshot snapCoCCHN = await _firestore
          .collection('HoSoCuuHoCoCCHN')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();

      if (snapCoCCHN.docs.isNotEmpty) {
        var data = snapCoCCHN.docs.first.data() as Map<String, dynamic>;
        if (data['maTrangThaiHoSo'] == 'cuuho_trangthai_hoso_daduyet') {
          return {'daDuyet': true, 'coCCHN': true};
        }
      }

      // 2. Kiểm tra trong bảng HoSoCuuHoKhongCCHN
      QuerySnapshot snapKhongCCHN = await _firestore
          .collection('HoSoCuuHoKhongCCHN')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();

      if (snapKhongCCHN.docs.isNotEmpty) {
        var data = snapKhongCCHN.docs.first.data() as Map<String, dynamic>;
        if (data['maTrangThaiHoSo'] == 'cuuho_trangthai_hoso_daduyet') {
          return {'daDuyet': true, 'coCCHN': false};
        }
      }
    } catch (e) {
      print('Lỗi kiemTraTrangThaiHoSoCuuHo: $e');
    }

    return {'daDuyet': false, 'coCCHN': false};
  }

  /// Xử lý chuyển đổi vai trò khi nhấn nút "Chuyển sang màn hình người cứu hộ"
  Future<bool> chuyenSangManHinhCuuHo(String maNguoiDung) async {
    try {
      Map<String, bool> hoSoState = await kiemTraTrangThaiHoSoCuuHo(
        maNguoiDung,
      );

      if (hoSoState['daDuyet'] == true) {
        String vaTroMoi = hoSoState['coCCHN'] == true
            ? 'vaitro_cuuhococc'
            : 'vaitro_cuuhochuacocc';

        return await capNhatVaiTro(maNguoiDung, vaTroMoi);
      }
    } catch (e) {
      print('Lỗi chuyenSangManHinhCuuHo: $e');
    }
    return false;
  }

  // ==================== TẠO YÊU CẦU CỨU HỘ SOS ====================
  Future<String?> taoYeuCauTimBacSiSOS({
    required String maNguoiYeuCau,
    required double viDo,
    required double kinhDo,
    List<String>? trieuChung,
    String? moTaChiTiet,
    File? fileAnh,
    File? fileGhiAm,
    String maLoaiYeuCau = 'loaiyeucau_sos',
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
        'mucDoKhanCap': 1,
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

  // Trạng thái người thân đã đồng ý kết nối
  static const String trangThaiNguoiThanDongY =
      'user_trangthai_nguoithan_dongy';

  /// Stream danh sách người thân (đã đồng ý) kèm họ tên + SĐT lấy từ collection NguoiDung
  Stream<List<NguoiThanKhanCap>> streamNguoiThanKhanCap(String maNguoiDung) {
    if (maNguoiDung.isEmpty) return Stream.value([]);

    return _firestore
        .collection('NguoiThan')
        .doc(maNguoiDung)
        .collection('DanhSachNguoiThan')
        .where('trangThai', isEqualTo: trangThaiNguoiThanDongY)
        .snapshots()
        .asyncMap((snap) async {
          // Với mỗi người thân, lấy thông tin từ NguoiDung (doc id = mã người thân)
          final ketQua = await Future.wait(
            snap.docs.map((doc) async {
              try {
                final userDoc = await _firestore
                    .collection('NguoiDung')
                    .doc(doc.id)
                    .get();
                if (!userDoc.exists || userDoc.data() == null) return null;

                final u = userDoc.data()!;
                final ngayTao = doc.data()['ngayTao'];

                return NguoiThanKhanCap(
                  maNguoiThan: doc.id,
                  hoTen: (u['hoTen'] ?? '') as String,
                  soDienThoai: (u['soDienThoai'] ?? '') as String,
                  moiQuanHe: doc.data()['moiQuanHe'] as String?,
                  ngayTao: ngayTao is Timestamp ? ngayTao.toDate() : null,
                );
              } catch (e) {
                print('Lỗi streamNguoiThanKhanCap (${doc.id}): $e');
                return null;
              }
            }),
          );

          final list = ketQua.whereType<NguoiThanKhanCap>().toList();
          // Sắp xếp ở client để không phải tạo composite index trên Firestore
          list.sort(
            (a, b) =>
                (a.ngayTao ?? DateTime(0)).compareTo(b.ngayTao ?? DateTime(0)),
          );
          return list;
        });
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
            whereIn: ['vaitro_cuuhococc', 'vaitro_cuuhochuacocc'],
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

  // Thay thế hàm streamPhanCongByYeuCau cũ trong firebase_service.dart
  Stream<List<ChiTietPhanCongCuuHoModel>> streamPhanCongByYeuCau(
    String maYeuCau,
  ) {
    // Lắng nghe tất cả các user trong bảng NguoiDung hoặc quét collectionGroup chuẩn xác hơn
    return _firestore
        .collectionGroup('DanhSachPhanCong')
        .where('maYeuCau', isEqualTo: maYeuCau)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(
                (doc) => ChiTietPhanCongCuuHoModel.fromMap(doc.data(), doc.id),
              )
              .toList();
        });
  }

  Future<void> updateTinhTrangYeuCau(
    String maYeuCau,
    String maTinhTrang,
  ) async {
    try {
      final Map<String, dynamic> updateData = {
        'maTinhTrangYeuCau': maTinhTrang,
      };

      if (maTinhTrang == 'user_tinhtrang_daphancong') {
        updateData['thoiGianPhanCong'] = FieldValue.serverTimestamp();
      } else if (maTinhTrang == 'user_tinhtrang_hoanthanh') {
        updateData['thoiGianHoanThanh'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .update(updateData);
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
  static const Map<String, String> _nhomKyNang = {
    'kynangcoban': 'Kỹ năng cơ bản',
    'kynangtuhoc': 'Kỹ năng tự học',
  };

  List<Map<String, String>>? _danhMucKyNangCache;
  Future<List<String>> getSkillIdsByUserId(String userId) async {
    final List<String> skillIds = [];
    try {
      final snap = await _firestore
          .collection('ChiTietKyNang')
          .doc(userId)
          .collection('DanhSachKyNang')
          .get();
      for (final doc in snap.docs) {
        final ma = (doc.data()['maKyNangCuuHo'] ?? '').toString().trim();
        skillIds.add(ma.isNotEmpty ? ma : doc.id);
      }
    } catch (e) {
      print('❌ Lỗi getSkillIdsByUserId($userId): $e');
    }
    return skillIds;
  }

  Future<List<Map<String, String>>> getDanhMucKyNang({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _danhMucKyNangCache != null) {
      return _danhMucKyNangCache!;
    }

    final Map<String, Map<String, String>> byId = {};

    Map<String, String> toItem(
      String docId,
      Map<String, dynamic> d,
      String nhom,
    ) {
      final ma = (d['maKyNangCuuHo'] ?? '').toString().trim();
      final id = ma.isNotEmpty ? ma : docId;
      return {
        'ma': id,
        'ten': (d['ten'] ?? id).toString(),
        'moTa': (d['moTa'] ?? '').toString(),
        'nhom': nhom,
        'tenNhom': _nhomKyNang[nhom] ?? 'Khác',
      };
    }

    try {
      // 1) danh mục phẳng
      final flat = await _firestore.collection('KyNangCuuHo').get();
      for (final doc in flat.docs) {
        final item = toItem(doc.id, doc.data(), '');
        byId[item['ma']!] = item;
      }

      // 2) danh mục theo nhóm
      for (final nhom in _nhomKyNang.keys) {
        final snap = await _firestore
            .collection('KyNangCuuHo')
            .doc(nhom)
            .collection('DanhSachKyNang')
            .get();
        for (final doc in snap.docs) {
          final item = toItem(doc.id, doc.data(), nhom);
          byId[item['ma']!] = item;
        }
      }
    } catch (e) {
      print('❌ Lỗi getDanhMucKyNang: $e');
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        final byGroup = a['tenNhom']!.compareTo(b['tenNhom']!);
        return byGroup != 0 ? byGroup : a['ten']!.compareTo(b['ten']!);
      });

    if (list.isNotEmpty)
      _danhMucKyNangCache = list; // không cache kết quả rỗng/lỗi
    return list;
  }

  Future<List<String>> getSkillNamesByIds(List<String> skillIds) async {
    final List<String> names = [];
    if (skillIds.isEmpty) return names;

    final catalog = await getDanhMucKyNang();
    for (final id in skillIds) {
      for (final k in catalog) {
        if (k['ma'] == id) {
          names.add((k['ten'] ?? '').toLowerCase());
          final moTa = (k['moTa'] ?? '').toLowerCase();
          if (moTa.isNotEmpty) names.add(moTa);
          break;
        }
      }
    }
    return names;
  }

  // ===========================================================================
  // 7. LẤY AVATAR NGƯỜI DÙNG (TỪ LuuAnhModel)
  // ===========================================================================

  Future<String?> getUserAvatarUrl(String maNguoiDung) async {
    try {
      final snap = await _firestore
          .collection('LuuAnh')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .where('maPhanLoaiAnh', isEqualTo: 'anh_dai_dien')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        return (data['base64Image'] ?? data['anhURL'])?.toString();
      }
    } catch (e) {
      print('Lỗi FirebaseService.getUserAvatarUrl: $e');
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
  // ===========================================================================
  // 10 & 11. ĐÁNH GIÁ THEO CẤU TRÚC MỚI:
  // DanhGia/{maNguoiCuuHo}/DanhSachYeuCau/{maYeuCau}
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> langNgheDanhSachCuuHo(String maYeuCau) {
    return _firestore.collection('YeuCauCuuHo').doc(maYeuCau).snapshots().map((
      docSnap,
    ) {
      if (!docSnap.exists || docSnap.data() == null) return [];
      final rawMap = Map<String, dynamic>.from(
        docSnap.data()!['danhSachPhanCongVien'] ?? {},
      );

      final List<Map<String, dynamic>> result = [];
      rawMap.forEach((maNguoiCuuHo, trangThai) {
        final status = trangThai.toString();
        if (status != 'cuuho_trangthai_phancong_tuchoi' &&
            status != 'cuuho_trangthai_phancong_dahuy' &&
            status != 'cuuho_trangthai_phancong_chotiepnhan') {
          result.add({
            'maNguoiCuuHo': maNguoiCuuHo,
            'maTrangThaiTiepNhan': status,
          });
        }
      });
      return result;
    });
  }

  Stream<List<DanhGiaModel>> langNgheDanhGia(String maYeuCau) {
    return _firestore
        .collectionGroup('DanhSachYeuCau')
        .where('maYeuCau', isEqualTo: maYeuCau)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DanhGiaModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<bool> xacNhanHoanThanhYeuCau(String maYeuCau) async {
    try {
      await _firestore.collection('YeuCauCuuHo').doc(maYeuCau).update({
        'maTinhTrangYeuCau': 'user_tinhtrang_hoanthanh',
        'thoiGianHoanThanh': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> xacNhanHoanThanhVaGuiDanhGia({
    required String maYeuCau,
    required List<DanhGiaModel> danhSachDanhGia,
  }) async {
    try {
      final batch = _firestore.batch();

      final yeuCauRef = _firestore.collection('YeuCauCuuHo').doc(maYeuCau);
      batch.update(yeuCauRef, {
        'maTinhTrangYeuCau': 'user_tinhtrang_hoanthanh',
        'thoiGianHoanThanh': FieldValue.serverTimestamp(),
      });

      for (final dg in danhSachDanhGia) {
        final parentRef = _firestore.collection('DanhGia').doc(dg.maNguoiCuuHo);
        batch.set(parentRef, {
          'maNguoiCuuHo': dg.maNguoiCuuHo,
          'capNhatLanCuoi': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final dgRef = parentRef.collection('DanhSachYeuCau').doc(maYeuCau);

        final dataToSave = DanhGiaModel(
          maDanhGia: maYeuCau,
          maYeuCau: maYeuCau,
          maNguoiDanhGia: dg.maNguoiDanhGia,
          maNguoiCuuHo: dg.maNguoiCuuHo,
          diemDanhGia: dg.diemDanhGia,
          nhanXet: dg.nhanXet,
          ngayTao: DateTime.now(),
        );

        batch.set(dgRef, dataToSave.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('❌ Lỗi xacNhanHoanThanhVaGuiDanhGia: $e');
      return false;
    }
  }

  Future<bool> guiDanhGia(DanhGiaModel danhGia) async {
    return await guiDanhGiaCuuHoVien(danhGia);
  }

  Future<List<YeuCauCuuHoModel>> getLichSuYeuCauByUser(
    String currentUserId,
  ) async {
    try {
      final snap = await _firestore
          .collection('YeuCauCuuHo')
          .where('maNguoiYeuCau', isEqualTo: currentUserId)
          .where(
            'maTinhTrangYeuCau',
            whereIn: [
              'user_tinhtrang_hoanthanh',
              'user_tinhtrang_dahuy',
              'user_tinhtrang_quahandieuphoi',
            ],
          )
          .get();

      final list = snap.docs
          .map((doc) => YeuCauCuuHoModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.thoiGianTao.compareTo(a.thoiGianTao));
      return list;
    } catch (e) {
      print('❌ Lỗi FirebaseService.getLichSuYeuCauByUser: $e');
      return [];
    }
  }

  Future<Map<String, DanhGiaModel>> getDanhGiaCuuHoVienTheoYeuCau(
    String maYeuCau, {
    List<String> rescuerIds = const [],
  }) async {
    Map<String, DanhGiaModel> result = {};
    try {
      if (rescuerIds.isNotEmpty) {
        final futures = rescuerIds.map((uid) {
          return _firestore
              .collection('DanhGia')
              .doc(uid)
              .collection('DanhSachYeuCau')
              .doc(maYeuCau)
              .get();
        });

        final docs = await Future.wait(futures);
        for (int i = 0; i < rescuerIds.length; i++) {
          final uid = rescuerIds[i];
          final doc = docs[i];
          if (doc.exists && doc.data() != null) {
            result[uid] = DanhGiaModel.fromMap(doc.data()!, doc.id);
          }
        }
      } else {
        final snap = await _firestore
            .collectionGroup('DanhSachYeuCau')
            .where('maYeuCau', isEqualTo: maYeuCau)
            .get();

        for (var doc in snap.docs) {
          final dg = DanhGiaModel.fromMap(doc.data(), doc.id);
          if (dg.maNguoiCuuHo.isNotEmpty) {
            result[dg.maNguoiCuuHo] = dg;
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi FirebaseService.getDanhGiaCuuHoVienTheoYeuCau: $e');
    }
    return result;
  }

  Future<bool> guiDanhGiaCuuHoVien(DanhGiaModel danhGia) async {
    try {
      final parentRef = _firestore
          .collection('DanhGia')
          .doc(danhGia.maNguoiCuuHo);
      final docRef = parentRef
          .collection('DanhSachYeuCau')
          .doc(danhGia.maYeuCau);

      final existing = await docRef.get();
      if (existing.exists) {
        return false;
      }

      await parentRef.set({
        'maNguoiCuuHo': danhGia.maNguoiCuuHo,
        'capNhatLanCuoi': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final dataToSave = DanhGiaModel(
        maDanhGia: danhGia.maYeuCau,
        maYeuCau: danhGia.maYeuCau,
        maNguoiDanhGia: danhGia.maNguoiDanhGia,
        maNguoiCuuHo: danhGia.maNguoiCuuHo,
        diemDanhGia: danhGia.diemDanhGia,
        nhanXet: danhGia.nhanXet,
        ngayTao: DateTime.now(),
      );

      await docRef.set(dataToSave.toMap());
      return true;
    } catch (e) {
      print('❌ Lỗi FirebaseService.guiDanhGiaCuuHoVien: $e');
      return false;
    }
  }

  // ===========================================================================
  // 12. VIDEO HƯỚNG DẪN SƠ CỨU
  // ===========================================================================
  /// Lấy toàn bộ video hướng dẫn từ collection 'VideoHuongDan'.
  /// KHÔNG nuốt lỗi: ném FirebaseException để controller báo đúng nguyên nhân
  /// (mất mạng, thiếu quyền...). Mạng yếu: chờ 8s rồi đọc bộ nhớ đệm.
  Future<KetQuaVideoHuongDan> getVideoHuongDan() async {
    final col = _firestore.collection('VideoHuongDan');

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await col.get().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      snap = await col.get(const GetOptions(source: Source.cache));
    }

    return KetQuaVideoHuongDan(
      videos: snap.docs
          .map((d) => VideoHuongDanModel.fromMap(d.data(), d.id))
          .toList(),
      soDoc: snap.docs.length,
      tuBoNhoDem: snap.metadata.isFromCache,
    );
  }

  // ===========================================================================
  // 13.Tin Nhắn Cứu Hộ
  // ===========================================================================
  // 🌟 1. Stream danh sách tin nhắn theo cấu trúc mới: /PhongChatCuuHo/{maYeuCau}/DanhSachTinNhan
  Stream<List<ChiTietTinNhanModel>> streamDanhSachTinNhan(String maYeuCau) {
    return FirebaseFirestore.instance
        .collection('PhongChatCuuHo')
        .doc(maYeuCau)
        .collection('DanhSachTinNhan')
        .orderBy('thoiGianGui', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChiTietTinNhanModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // 🌟 2. Gửi tin nhắn mới vào collection mới
  Future<void> guiTinNhanMoi(
    String maYeuCau,
    ChiTietTinNhanModel tinNhan,
  ) async {
    await FirebaseFirestore.instance
        .collection('PhongChatCuuHo')
        .doc(maYeuCau)
        .collection('DanhSachTinNhan')
        .add(tinNhan.toMap());
  }

  // 🌟 3. Lấy thông tin user (Tên + Avatar từ LuuAnh) để hiển thị trong khung chat
  Future<Map<String, String>> getUserInfoForChat(String userId) async {
    String name = 'Cứu hộ viên';
    String? avatar;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        name = userDoc.data()?['hoTen'] ?? 'Cứu hộ viên';
      }

      var imageQuery = await FirebaseFirestore.instance
          .collection('LuuAnh')
          .where('maNguoiDung', isEqualTo: userId)
          .where('maPhanLoaiAnh', isEqualTo: 'anh_dai_dien')
          .limit(1)
          .get();

      if (imageQuery.docs.isNotEmpty) {
        avatar = imageQuery.docs.first.data()['base64Image'] as String?;
      }
    } catch (e) {
      print('Lỗi lấy thông tin chat user: $e');
    }

    return {'name': name, 'avatar': avatar ?? ''};
  }

  // 🌟 4. Dịch tọa độ (viDo, kinhDo) thành tên địa chỉ thực tế
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'cuhokhancap_app'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      print('Lỗi geocoding: $e');
    }
    return 'Tọa độ: $lat, $lng';
  }
  // ===========================================================================
  // 14. BẢNG XẾP HẠNG THEO KỲ (XepHangKy/{kyId}/ThanhVien)
  // ===========================================================================

  /// Tính mã kỳ theo ngày truyền vào (mặc định là hôm nay):
  /// - Tuần: tuan_YYYY-Www (vd: tuan_2026-W47)
  /// - Tháng: thang_YYYY-MM (vd: thang_2026-11)
  String taoMaKyXepHang(DateTime date, {required bool isThang}) {
    if (isThang) {
      final mm = date.month.toString().padLeft(2, '0');
      return 'thang_${date.year}-$mm';
    }
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final firstJan = DateTime(thursday.year, 1, 1);
    final diffDays = thursday.difference(firstJan).inDays;
    final weekNumber = (diffDays / 7).floor() + 1;
    final ww = weekNumber.toString().padLeft(2, '0');
    return 'tuan_${thursday.year}-W$ww';
  }

  /// Stream danh sách thành viên trong kỳ XepHangKy/{kyId}/ThanhVien
  Future<List<Map<String, dynamic>>> layThanhVienXepHangKy(String kyId) async {
    try {
      final snap = await _firestore
          .collection('XepHangKy')
          .doc(kyId)
          .collection('ThanhVien')
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'docId': doc.id,
          'maNguoiDung': (data['maNguoiDung'] ?? doc.id).toString(),
          'tenHienThi': (data['tenHienThi'] ?? '').toString(),
          'loaiHoSo': (data['loaiHoSo'] ?? '').toString(),
          'soCaHoanThanh': (data['soCaHoanThanh'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (e) {
      print('❌ Lỗi layThanhVienXepHangKy: $e');
      return [];
    }
  }
}
