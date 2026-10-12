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
}