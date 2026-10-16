import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/LuuAnh/luu_anh_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/ho_so_cuu_ho_khong_cchn_model.dart';

class CuuHoVienKhongCCHNController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final cccdCardNoController = TextEditingController();
  final dobController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssueDateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssuerController = TextEditingController();
  final addressController = TextEditingController();

  final organizationController = TextEditingController();
  final summaryController = TextEditingController();
  final noteController = TextEditingController();

  String gender = 'Nam';
  bool isAgreed = false;

  bool isSubmitting = false;
  final LuuAnhService _luuAnhService = LuuAnhService();

  String selectedExperience = '1 - 3 năm';
  List<String> experienceOptions = [
    'Dưới 1 năm',
    '1 - 3 năm',
    '3 - 5 năm',
    'Trên 5 năm',
  ];

  List<String> availableSkills = [
    'Ép tim CPR',
    'Băng bó vết thương',
    'Cố định gãy xương',
    'Sơ cứu đuối nước',
    'Xử lý bỏng ban đầu',
  ];
  List<String> selectedSkills = ['Ép tim CPR'];

  // Quản lý tối đa 3 ảnh thực tế
  List<File> selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  // 🟢 Bổ sung tham số existingFullName vào constructor để tự điền Họ và tên
  CuuHoVienKhongCCHNController({String? existingFullName}) {
    fullNameController.text =
        existingFullName ??
        'Nguyễn Văn A'; // Tên mặc định hoặc lấy từ Auth/Profile
    _initDefaultData();

    // Lắng nghe sự thay đổi ô nhập liệu để cập nhật trạng thái Bật/Tắt nút bấm
    cccdCardNoController.addListener(notifyListeners);
    cccdIssuerController.addListener(notifyListeners);
    organizationController.addListener(notifyListeners);
  }

  void _initDefaultData() {
    cccdIssuerController.text =
        'Cục Cảnh sát quản lý hành chính về trật tự xã hội';
  }

  /// Kiểm tra Form đã nhập ĐỦ THÔNG TIN BẮT BUỘC chưa
  bool get isFormValid {
    bool hasFullName = fullNameController.text.trim().isNotEmpty;
    bool hasCccd = cccdCardNoController.text.trim().isNotEmpty;
    bool hasIssuer = cccdIssuerController.text.trim().isNotEmpty;
    bool hasOrg = organizationController.text.trim().isNotEmpty;
    bool hasPhotos = selectedPhotos.isNotEmpty;

    return isAgreed &&
        hasFullName &&
        hasCccd &&
        hasIssuer &&
        hasOrg &&
        hasPhotos;
  }

  int _parseExperienceYears(String text) {
    if (text.contains('Dưới 1 năm')) return 0;
    if (text.contains('1 - 3 năm')) return 2;
    if (text.contains('3 - 5 năm')) return 4;
    if (text.contains('Trên 5 năm')) return 5;
    return 0;
  }

  Future<void> pickPhoto(ImageSource source) async {
    if (selectedPhotos.length >= 3) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedPhotos.add(File(pickedFile.path));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < selectedPhotos.length) {
      selectedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  void setGender(String val) {
    gender = val;
    notifyListeners();
  }

  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setExperience(String val) {
    selectedExperience = val;
    notifyListeners();
  }

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      selectedSkills.add(skill);
    }
    notifyListeners();
  }

  /// 🚀 Hàm xử lý lưu danh sách ảnh vào bảng LuuAnh & đẩy hồ sơ lên HoSoCuuHoKhongCCHN
  Future<bool> submitHoSoToFirebase(String currentUserId) async {
    if (!isFormValid) return false;

    isSubmitting = true;
    notifyListeners();

    try {
      // 1. Lưu ảnh vào collection LuuAnh
      if (selectedPhotos.isNotEmpty) {
        for (int i = 0; i < selectedPhotos.length; i++) {
          File photoFile = selectedPhotos[i];

          String? base64String = await _luuAnhService.convertFileToBase64(
            photoFile,
          );

          if (base64String != null) {
            await _luuAnhService.saveLuuAnh(
              maNguoiDung: currentUserId,
              base64Image: base64String,
              maPhanLoaiAnh: 'ANH_THUC_TE_KHONG_CCHN',
              maMoTa: 'Ảnh minh chứng hoạt động cứu hộ thực tế ${i + 1}',
            );
          }
        }
      }

      // 2. Tạo Model ánh xạ cấu trúc bảng HoSoCuuHoKhongCCHN
      final hoSo = HoSoCuuHoKhongCCHNModel(
        maNguoiDung: currentUserId,
        soCanCuoc: cccdCardNoController.text.trim(),
        ngayCapCanCuoc: dobController.text.trim(),
        ngayHetHanCanCuoc: cccdIssueDateController.text.trim(),
        coQuanCapCanCuoc: cccdIssuerController.text.trim(),
        doiNhom: organizationController.text.trim(),
        soNamHoatDongCuuHo: _parseExperienceYears(selectedExperience),
        soLanThamGiaCuuHo: 0,
        diemDanhGia: 0.0,
        tongLuotDanhGia: 0,
        ghiChu: noteController.text.trim(),
        thoiGianOnline: DateTime.now().toIso8601String(),
        soLuongCaDuocPhat: 0,
        soluongCaDaNhan: 0,
        soLuongDaKhongNhan: 0,
        soLuongCaHoanThanh: 0,
        maTrangThaiHoSo: 'cuuho_trangthai_tiepnhan',
      );

      // 3. Đẩy dữ liệu lên Firestore
      await FirebaseFirestore.instance
          .collection('HoSoCuuHoKhongCCHN')
          .doc(currentUserId)
          .set(hoSo.toMap());

      return true;
    } catch (e) {
      debugPrint('🔴 Lỗi gửi hồ sơ không CCHN: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate = DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
      notifyListeners();
    }
  }

  void showAddressDialog(BuildContext context) {}

  @override
  void dispose() {
    fullNameController.dispose();
    cccdCardNoController.dispose();
    dobController.dispose();
    cccdIssueDateController.dispose();
    cccdIssuerController.dispose();
    addressController.dispose();
    organizationController.dispose();
    summaryController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
