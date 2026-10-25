import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _serviceId = 'service_mjq8s5n';
  final String _templateId = 'template_xgoatgh';
  final String _publicKey = 'ui8hvA1YiR6O-spA1';
  final String _privateKey = 'iGWSAbxAHAOt3koQgtpHz';

  // --- Các hàm cơ bản giữ nguyên ---
  Future<bool> taoTaiKhoan(NguoiDungModel nguoiDung) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('NguoiDung').get();
      int nextIdNumber = snapshot.docs.length + 1;
      String maNguoiDungMoi = 'nguoidung${nextIdNumber.toString()}';

      DocumentReference docRef = _firestore.collection('NguoiDung').doc(maNguoiDungMoi);
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
      QuerySnapshot phoneQuery = await _firestore.collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau).get();
      if (phoneQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(phoneQuery.docs.first.data() as Map<String, dynamic>);
      }

      QuerySnapshot emailQuery = await _firestore.collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau).get();
      if (emailQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(emailQuery.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<NguoiDungModel?> layThongTinNguoiDungRealTime(String maNguoiDung) {
    try {
      return _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).snapshots().map((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) return NguoiDungModel.fromMap(querySnapshot.docs.first.data());
        return null;
      });
    } catch (e) {
      return Stream.value(null);
    }
  }

  Future<NguoiDungModel?> timTaiKhoanQuenMatKhau(String taiKhoan) async {
    try {
      QuerySnapshot phoneQuery = await _firestore.collection('NguoiDung').where('soDienThoai', isEqualTo: taiKhoan).get();
      if (phoneQuery.docs.isNotEmpty) return NguoiDungModel.fromMap(phoneQuery.docs.first.data() as Map<String, dynamic>);

      QuerySnapshot emailQuery = await _firestore.collection('NguoiDung').where('email', isEqualTo: taiKhoan).get();
      if (emailQuery.docs.isNotEmpty) return NguoiDungModel.fromMap(emailQuery.docs.first.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> capNhatMatKhau(String maNguoiDung, String matKhauMoi) async {
    try {
      QuerySnapshot query = await _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('NguoiDung').doc(query.docs.first.id).update({'matKhau': matKhauMoi});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> capNhatThongTinCaNhan(String maNguoiDung, Map<String, dynamic> dataUpdate) async {
    try {
      QuerySnapshot query = await _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('NguoiDung').doc(query.docs.first.id).update(dataUpdate);
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
        'email': email, 'otp': otpCode, 'expireTime': expireTime, 'createdAt': DateTime.now(),
      });
      bool sent = await guiEmailOTP(email, otpCode);
      return sent ? otpCode : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> xacNhanMaOTP(String email, String otpNhap) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('XacThucOTP').doc(email).get();
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

  Future<void> capNhatViTriVaTrangThai(String maNguoiDung, double viDo, double kinhDo, String geohash, bool isOnline) async {
    try {
      QuerySnapshot query = await _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('NguoiDung').doc(query.docs.first.id).update({
          'viDo': viDo, 'kinhDo': kinhDo, 'geohash': geohash, 'isOnline': isOnline,
        });
      }
    } catch (e) {}
  }

  Future<void> capNhatTrangThaiOnline(String maNguoiDung, bool isOnline) async {
    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await rtdb.ref('NguoiDung/$maNguoiDung/isOnline').set(isOnline);
      QuerySnapshot query = await _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('NguoiDung').doc(query.docs.first.id).update({'isOnline': isOnline});
      }
    } catch (e) {}
  }

  Future<bool> capNhatVaiTro(String maNguoiDung, String maVaiTro) async {
    try {
      QuerySnapshot query = await _firestore.collection('NguoiDung').where('maNguoiDung', isEqualTo: maNguoiDung).get();
      if (query.docs.isNotEmpty) {
        await _firestore.collection('NguoiDung').doc(query.docs.first.id).update({'maVaiTro': maVaiTro});
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
        databaseURL: 'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
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
      databaseURL: 'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final connectedRef = rtdb.ref('.info/connected');
    final userRef = rtdb.ref('NguoiDung/$maNguoiDung');

    connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        // Chỉ đổi isOnline thành false khi rớt mạng, giữ nguyên maThietBi trên server
        userRef.child('isOnline').onDisconnect().set(false).then((_) {
          // Báo true và đính kèm maThietBi
          userRef.update({
            'isOnline': true,
            'maThietBi': maThietBi,
          });
        });
      }
    });
  }

  // 3. Hủy bỏ onDisconnect khi bị máy khác đá văng để không làm tắt nhầm trạng thái của máy mới
  Future<void> huyOnDisconnect(String maNguoiDung) async {
    try {
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://cuuhokhancap-d5178-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await rtdb.ref('NguoiDung/$maNguoiDung/isOnline').onDisconnect().cancel();
    } catch (e) {}
  }
}