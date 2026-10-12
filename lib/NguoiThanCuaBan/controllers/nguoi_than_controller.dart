// lib/controllers/nguoi_than_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';

class NguoiThanController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream lấy danh sách người thân chính thức từ Firestore
  Stream<List<Map<String, dynamic>>> getRelativesStream(String currentUserID) {
    if (currentUserID.isEmpty) return Stream.value([]);

    return _firestore
        .collection('NguoiThan')
        .where('maNguoiDung', isEqualTo: currentUserID)
        .snapshots()
        .asyncMap((nguoiThanSnapshot) async {
          List<Map<String, dynamic>> relativeList = [];
          for (var doc in nguoiThanSnapshot.docs) {
            final nguoiThanData = doc.data();
            final String? maNguoiThan = nguoiThanData['maNguoiThan'];
            final String moiQuanHe =
                nguoiThanData['moiQuanHe'] ?? 'Chưa Xác Định';

            if (maNguoiThan != null && maNguoiThan.isNotEmpty) {
              final userDoc = await _firestore
                  .collection('NguoiDung')
                  .doc(maNguoiThan)
                  .get();
              if (userDoc.exists) {
                final userData = NguoiDungModel.fromMap(userDoc.data()!);
                int age = tinhTuoi(userData.ngaySinh);

                relativeList.add({
                  'relation': moiQuanHe,
                  'id': userData.maNguoiDung,
                  'name': userData.hoTen,
                  'age': age,
                  'phone': userData.soDienThoai,
                  'email': userData.email,
                  'avatarUrl': 'https://i.pravatar.cc/150',
                });
              }
            }
          }
          return relativeList;
        });
  }

  // Hàm tiện ích tính tuổi dựa trên ngày sinh
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
