import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // ================= CẤU HÌNH EMAILJS =================
  // ĐIỀN THÔNG TIN CỦA BẠN VÀO ĐÂY
  final String _serviceId = 'service_mjq8s5n'; 
  final String _templateId = 'template_xgoatgh'; 
  final String _publicKey = 'ui8hvA1YiR6O-spA1'; 
  final String _privateKey = 'iGWSAbxAHAOt3koQgtpHz';
  // ====================================================

  // Hàm đăng ký người dùng mới lên Firebase với mã tăng dần
  Future<bool> taoTaiKhoan(NguoiDungModel nguoiDung) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('NguoiDung').get();
      int totalUsers = snapshot.docs.length;

      int nextIdNumber = totalUsers + 1;
      String maNguoiDungMoi = 'nguoidung${nextIdNumber.toString()}'; 

      DocumentReference docRef = _firestore.collection('NguoiDung').doc(maNguoiDungMoi);
      
      Map<String, dynamic> data = nguoiDung.toMap();
      data['maNguoiDung'] = maNguoiDungMoi;

      await docRef.set(data);
      
      return true; 
    } catch (e) {
      print('Lỗi khi tạo mã và đẩy dữ liệu lên Firebase: $e');
      return false; 
    }
  }

  // Hàm đăng nhập người dùng bằng số điện thoại hoặc email và mật khẩu
  Future<NguoiDungModel?> dangNhap(String taiKhoan, String matKhau) async {
    try {
      QuerySnapshot phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(phoneQuery.docs.first.data() as Map<String, dynamic>);
      }

      QuerySnapshot emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(emailQuery.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Lỗi khi đăng nhập: $e');
      return null;
    }
  }

  // SỬA LẠI: Hàm lắng nghe thông tin người dùng THEO THỜI GIAN THỰC (Real-time Stream)
  Stream<NguoiDungModel?> layThongTinNguoiDungRealTime(String maNguoiDung) {
    try {
      // Sử dụng .snapshots() để tạo luồng dữ liệu thời gian thực
      return _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .snapshots()
          .map((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          return NguoiDungModel.fromMap(querySnapshot.docs.first.data());
        }
        return null;
      });
    } catch (e) {
      print('Lỗi khi lắng nghe thông tin người dùng: $e');
      // Trả về luồng dữ liệu rỗng nếu lỗi
      return Stream.value(null); 
    }
  }

  // THÊM MỚI: Hàm tìm tài khoản dựa trên SĐT hoặc Email
  Future<NguoiDungModel?> timTaiKhoanQuenMatKhau(String taiKhoan) async {
    try {
      QuerySnapshot phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(phoneQuery.docs.first.data() as Map<String, dynamic>);
      }

      QuerySnapshot emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(emailQuery.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Lỗi khi tìm tài khoản quên mật khẩu: $e');
      return null;
    }
  }

  // THÊM MỚI: Hàm cập nhật mật khẩu mới lên Firestore
  Future<bool> capNhatMatKhau(String maNguoiDung, String matKhauMoi) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await _firestore.collection('NguoiDung').doc(docId).update({
          'matKhau': matKhauMoi,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi khi cập nhật mật khẩu: $e');
      return false;
    }
  }

  // THÊM MỚI: Hàm cập nhật thông tin cá nhân lên Firestore
  Future<bool> capNhatThongTinCaNhan(String maNguoiDung, Map<String, dynamic> dataUpdate) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await _firestore.collection('NguoiDung').doc(docId).update(dataUpdate);
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi khi cập nhật thông tin: $e');
      return false;
    }
  }


  // THÊM MỚI 1: Hàm gọi API của EmailJS để gửi thư
  // Hàm gọi API của EmailJS để gửi thư
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
          'accessToken': _privateKey, // BẮT BUỘC THÊM DÒNG NÀY ĐỂ TRUYỀN PRIVATE KEY
          'template_params': {
            'to_email': email,
            'otp_code': otpCode,
          },
        }),
      );
      
      if (response.statusCode != 200) {
        print('👉 LỖI EMAILJS TỪ CHỐI GỬI: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('👉 LỖI MẠNG / HTTP KHI GỬI EMAIL: $e');
      return false;
    }
  }

  // THÊM MỚI 2: Tạo mã OTP, lưu lên Firestore và gửi Email
  Future<String?> taoVaGuiOTP(String email) async {
    try {
      // Sinh mã 6 số ngẫu nhiên
      String otpCode = (100000 + Random().nextInt(900000)).toString();
      DateTime expireTime = DateTime.now().add(const Duration(minutes: 5));

      // Lưu hoặc cập nhật mã OTP vào Firestore
      await _firestore.collection('XacThucOTP').doc(email).set({
        'email': email,
        'otp': otpCode,
        'expireTime': expireTime,
        'createdAt': DateTime.now(),
      });

      // Gửi Email
      bool sent = await guiEmailOTP(email, otpCode);
      return sent ? otpCode : null;
    } catch (e) {
      print('Lỗi tạo và gửi OTP: $e');
      return null;
    }
  }

  // THÊM MỚI 3: Kiểm tra mã OTP do người dùng nhập
  Future<bool> xacNhanMaOTP(String email, String otpNhap) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('XacThucOTP').doc(email).get();

      if (!doc.exists || doc.data() == null) return false;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String otpLuu = data['otp'] ?? '';
      Timestamp expireTimestamp = data['expireTime'];
      DateTime expireTime = expireTimestamp.toDate();

      // Kiểm tra xem khớp mã và chưa hết hạn 5 phút
      if (otpNhap == otpLuu && DateTime.now().isBefore(expireTime)) {
        // Xóa mã OTP sau khi đã xác minh thành công
        await _firestore.collection('XacThucOTP').doc(email).delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi xác thực OTP: $e');
      return false;
    }
  }
}