import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          return NguoiDungModel.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
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
}