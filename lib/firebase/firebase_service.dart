import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm đăng ký người dùng mới lên Firebase với mã tăng dần
  Future<bool> taoTaiKhoan(NguoiDungModel nguoiDung) async {
    try {
      // 1. Đếm tổng số lượng tài khoản hiện có trong collection 'NguoiDung'
      QuerySnapshot snapshot = await _firestore.collection('NguoiDung').get();
      int totalUsers = snapshot.docs.length;

      // 2. Tạo mã người dùng mới tăng dần dựa trên số lượng (VD: ND001, ND002, ND003,...)
      // Hoặc nếu bạn chỉ muốn dạng số thuần túy thì đổi thành: '${totalUsers + 1}'
      int nextIdNumber = totalUsers + 1;
      String maNguoiDungMoi = 'nguoidung${nextIdNumber.toString()}'; 
      // padLeft(3, '0') giúp định dạng thành ND001, ND002,... cho chuyên nghiệp

      // 3. Tạo một document mới tự động phát sinh ID (hoặc dùng chính maNguoiDungMoi làm document ID)
      DocumentReference docRef = _firestore.collection('NguoiDung').doc(maNguoiDungMoi);
      
      // 4. Lấy dữ liệu dạng Map và gán mã vào trường maNguoiDung
      Map<String, dynamic> data = nguoiDung.toMap();
      data['maNguoiDung'] = maNguoiDungMoi;

      // 5. Đẩy lên Firestore
      await docRef.set(data);
      
      return true; // Thành công
    } catch (e) {
      print('Lỗi khi tạo mã và đẩy dữ liệu lên Firebase: $e');
      return false; // Thất bại
    }
  }

  // Hàm đăng nhập người dùng bằng số điện thoại hoặc email và mật khẩu
  Future<NguoiDungModel?> dangNhap(String taiKhoan, String matKhau) async {
    try {
      // 1. Kiểm tra xem người dùng nhập số điện thoại hay email
      // Đầu tiên thử tìm theo Số điện thoại
      QuerySnapshot phoneQuery = await _firestore
          .collection('NguoiDung')
          .where('soDienThoai', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(phoneQuery.docs.first.data() as Map<String, dynamic>);
      }

      // 2. Nếu không tìm thấy số điện thoại, thử tìm theo Email
      QuerySnapshot emailQuery = await _firestore
          .collection('NguoiDung')
          .where('email', isEqualTo: taiKhoan)
          .where('matKhau', isEqualTo: matKhau)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(emailQuery.docs.first.data() as Map<String, dynamic>);
      }

      // 3. Không khớp dữ liệu nào
      return null;
    } catch (e) {
      print('Lỗi khi đăng nhập: $e');
      return null;
    }
  }

  // Hàm lấy thông tin người dùng theo mã người dùng
  Future<NguoiDungModel?> layThongTinNguoiDung(String maNguoiDung) async {
    try {
      // 1. Thử lấy document trực tiếp theo ID mã người dùng
      DocumentSnapshot doc = await _firestore.collection('NguoiDung').doc(maNguoiDung).get();
      if (doc.exists && doc.data() != null) {
        return NguoiDungModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      // 2. Nếu không tìm thấy, thử tìm theo trường 'maNguoiDung'
      QuerySnapshot query = await _firestore
          .collection('NguoiDung')
          .where('maNguoiDung', isEqualTo: maNguoiDung)
          .get();

      if (query.docs.isNotEmpty) {
        return NguoiDungModel.fromMap(query.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      return null;
    }
  }
}