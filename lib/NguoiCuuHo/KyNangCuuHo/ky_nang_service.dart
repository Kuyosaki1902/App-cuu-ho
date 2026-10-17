import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class KyNangService {
  final CollectionReference _kyNangRef = FirebaseFirestore.instance.collection(
    'KyNangCuuHo',
  );
  final CollectionReference _chiTietKyNangRef = FirebaseFirestore.instance
      .collection('ChiTietKyNang');

  /// 🟢 1. Tạo danh mục Kỹ năng mẫu vào bảng KyNangCuuHo
  Future<void> seedDefaultSkills() async {
    try {
      final List<Map<String, dynamic>> defaultSkills = [
        {
          'maKyNang': 'kn_cpr',
          'tenKyNang': 'Ép tim CPR',
          'moTa':
              'Kỹ thuật hồi sức tim phổi cơ bản cho người ngưng tim ngưng thở.',
        },
        {
          'maKyNang': 'kn_bang_bo',
          'tenKyNang': 'Băng bó vết thương',
          'moTa': 'Sơ cứu, cầm máu và băng bó các vết thương hở ngoài da.',
        },
        {
          'maKyNang': 'kn_co_dinh',
          'tenKyNang': 'Cố định gãy xương',
          'moTa':
              'Sử dụng nẹp và băng gạc cố định xương gãy trước khi vận chuyển.',
        },
        {
          'maKyNang': 'kn_duoi_nuoc',
          'tenKyNang': 'Sơ cứu đuối nước',
          'moTa':
              'Kỹ năng đưa nạn nhân ngạt nước lên bờ và thực hiện sơ cấp cứu.',
        },
        {
          'maKyNang': 'kn_bong',
          'tenKyNang': 'Xử lý bỏng ban đầu',
          'moTa': 'Làm mát và bảo vệ vùng da bị bỏng do nhiệt/hóa chất.',
        },
      ];

      for (var skill in defaultSkills) {
        String docId = skill['maKyNang'];
        var doc = await _kyNangRef.doc(docId).get();

        if (!doc.exists) {
          await _kyNangRef.doc(docId).set(skill);
        }
      }
      debugPrint('🟢 Tạo danh mục bảng KyNangCuuHo thành công!');
    } catch (e) {
      debugPrint('🔴 Lỗi khởi tạo KyNangCuuHo: $e');
    }
  }

  /// 🟢 2. Lấy danh sách kỹ năng từ bảng KyNangCuuHo
  Future<List<Map<String, String>>> fetchAllSkills() async {
    try {
      QuerySnapshot snapshot = await _kyNangRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'maKyNang': data['maKyNang']?.toString() ?? doc.id,
          'tenKyNang': data['tenKyNang']?.toString() ?? '',
          'moTa': data['moTa']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('🔴 Lỗi tải bảng KyNangCuuHo: $e');
      return [];
    }
  }

  /// 🟢 3. Lưu dữ liệu trực tiếp vào bảng ChiTietKyNang lấy maKyNang làm Document ID (Mã chính)
  Future<bool> saveChiTietKyNang({
    required String maNguoiDung,
    required List<String> danhSachMaKyNang,
    String? customSkills,
  }) async {
    try {
      // 🟢 Lưu từng kỹ năng chọn từ danh mục với Document ID = maKyNang
      for (String maKyNang in danhSachMaKyNang) {
        await _chiTietKyNangRef.doc(maKyNang).set({
          'maKyNang': maKyNang,
          'maNguoiDung': maNguoiDung,
          'tenKyNangTudo': '',
          'thoiGianTao': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      // 🟢 Nếu có nhập thêm kỹ năng tự do
      if (customSkills != null && customSkills.trim().isNotEmpty) {
        String customKey = 'kn_tu_goc_${DateTime.now().millisecondsSinceEpoch}';
        await _chiTietKyNangRef.doc(customKey).set({
          'maKyNang': customKey,
          'maNguoiDung': maNguoiDung,
          'tenKyNangTudo': customSkills.trim(),
          'thoiGianTao': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      debugPrint(
        '🟢 Đã lưu vào bảng ChiTietKyNang (mã chính = maKyNang) thành công!',
      );
      return true;
    } catch (e) {
      debugPrint('🔴 Lỗi lưu bảng ChiTietKyNang: $e');
      return false;
    }
  }
}
