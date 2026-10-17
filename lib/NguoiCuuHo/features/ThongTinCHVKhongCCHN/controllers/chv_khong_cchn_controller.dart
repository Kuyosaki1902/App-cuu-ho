import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/KyNangCuuHo/ky_nang_service.dart';
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
  final rescueTimesController = TextEditingController(text: '0');

  // Ô ghi thêm kỹ năng tùy chọn
  final customSkillsController = TextEditingController();

  final summaryController = TextEditingController();
  final noteController = TextEditingController();

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

  // Danh mục Kỹ năng sẵn có
  List<Map<String, String>> availableSkills = [
    {'maKyNang': 'kn_cpr', 'tenKyNang': 'Ép tim CPR'},
    {'maKyNang': 'kn_bang_bo', 'tenKyNang': 'Băng bó vết thương'},
    {'maKyNang': 'kn_co_dinh', 'tenKyNang': 'Cố định gãy xương'},
    {'maKyNang': 'kn_duoi_nuoc', 'tenKyNang': 'Sơ cứu đuối nước'},
    {'maKyNang': 'kn_bong', 'tenKyNang': 'Xử lý bỏng ban đầu'},
  ];

  List<String> selectedSkillCodes = [];
  List<File> selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  CuuHoVienKhongCCHNController({String? existingFullName}) {
    fullNameController.text = existingFullName ?? 'Nguyễn Văn A';
    _initDefaultData();

    cccdCardNoController.addListener(notifyListeners);
    cccdIssuerController.addListener(notifyListeners);
    organizationController.addListener(notifyListeners);
    _loadSkillsFromFirestore();
  }

  void _initDefaultData() {
    cccdIssuerController.text =
        'Cục Cảnh sát quản lý hành chính về trật tự xã hội';
  }

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

  /// Chọn / Bỏ chọn chip kỹ năng
  void toggleSkillCode(String code) {
    if (selectedSkillCodes.contains(code)) {
      selectedSkillCodes.remove(code);
    } else {
      selectedSkillCodes.add(code);
    }
    notifyListeners();
  }

  Future<void> _loadSkillsFromFirestore() async {
    final kyNangService = KyNangService();
    await kyNangService.seedDefaultSkills(); // Đảm bảo bảng có dữ liệu mẫu

    List<Map<String, String>> skills = await kyNangService.fetchAllSkills();
    if (skills.isNotEmpty) {
      availableSkills = skills;
      notifyListeners();
    }
  }

  // Quản lý ảnh
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

  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setExperience(String val) {
    selectedExperience = val;
    notifyListeners();
  }

  /// 🚀 Lưu thông tin hồ sơ + Lưu kỹ năng theo CÁCH 2 lên Firestore
  /// 🚀 Lưu thông tin hồ sơ + Lưu dữ liệu sang bảng ChiTietKyNang riêng
  Future<bool> submitHoSoToFirebase(String currentUserId) async {
    if (!isFormValid) return false;

    isSubmitting = true;
    notifyListeners();

    try {
      // 1. Lưu ảnh Base64 vào bảng LuuAnh
      for (int i = 0; i < selectedPhotos.length; i++) {
        String? base64String = await _luuAnhService.convertFileToBase64(
          selectedPhotos[i],
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

      // 🟢 2. LƯU RIÊNG VÀO BẢNG ChiTietKyNang
      final kyNangService = KyNangService();
      await kyNangService.saveChiTietKyNang(
        maNguoiDung: currentUserId,
        danhSachMaKyNang: selectedSkillCodes,
        customSkills: customSkillsController.text.trim(),
      );

      int times = int.tryParse(rescueTimesController.text.trim()) ?? 0;

      // 3. Lưu hồ sơ chính vào bảng HoSoCuuHoKhongCCHN
      final hoSo = HoSoCuuHoKhongCCHNModel(
        maNguoiDung: currentUserId,
        soCanCuoc: cccdCardNoController.text.trim(),
        ngayCapCanCuoc: dobController.text.trim(),
        ngayHetHanCanCuoc: cccdIssueDateController.text.trim(),
        coQuanCapCanCuoc: cccdIssuerController.text.trim(),
        doiNhom: organizationController.text.trim(),
        soNamHoatDongCuuHo: _parseExperienceYears(selectedExperience),
        soLanThamGiaCuuHo: times,
        diemDanhGia: 0.0,
        tongLuotDanhGia: 0,
        ghiChu: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        thoiGianOnline: DateTime.now().toIso8601String(),
        soLuongCaDuocPhat: 0,
        soluongCaDaNhan: 0,
        soLuongDaKhongNhan: 0,
        soLuongCaHoanThanh: 0,
        maTrangThaiHoSo: 'cuuho_trangthai_tiepnhan',
      );

      await FirebaseFirestore.instance
          .collection('HoSoCuuHoKhongCCHN')
          .doc(currentUserId)
          .set(hoSo.toMap());

      return true;
    } catch (e) {
      debugPrint('🔴 Lỗi lưu hồ sơ: $e');
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

  @override
  void dispose() {
    fullNameController.dispose();
    cccdCardNoController.dispose();
    dobController.dispose();
    cccdIssueDateController.dispose();
    cccdIssuerController.dispose();
    addressController.dispose();
    organizationController.dispose();
    rescueTimesController.dispose();
    customSkillsController.dispose();
    summaryController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
