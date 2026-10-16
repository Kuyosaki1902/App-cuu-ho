import 'dart:convert';
import 'dart:io';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/HoSoCuuHoService.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/models/ho_so_cuu_ho_co_cchn_model.dart';
import 'package:cuhokhancap/NguoiCuuHo/LuuAnh/luu_anh_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// Import Service & Model

class CuuHoVienCoCCHNController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  File? workCardImage; // 🟢 Lưu file ảnh thẻ công tác đã chọn
  final ImagePicker _picker = ImagePicker();
  final LuuAnhService _luuAnhService = LuuAnhService();

  final cccdController = TextEditingController();
  final fullNameController = TextEditingController();
  final cccdCardNoController = TextEditingController();
  final dobController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssueDateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssuerController = TextEditingController();

  final cchnNoController = TextEditingController();
  final cchnIssueDateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );

  final scopeController = TextEditingController();
  final positionController = TextEditingController();

  final employeeIdController = TextEditingController();
  final hospitalController = TextEditingController();

  bool isAgreed = false;
  bool isLoadingApi = false;
  bool isVerifying = false;
  bool isSubmitting = false; // Trạng thái đẩy dữ liệu Firebase
  bool? isCchnValid;

  /// Kiểm tra xem có đủ điều kiện để kích hoạt/thực hiện gửi yêu cầu không
  bool get canSubmit => isAgreed && isCchnValid == true;

  String? selectedCchnIssuer;
  List<String> cchnIssuerList = [];

  final HoSoCuuHoService _hoSoService = HoSoCuuHoService();

  CuuHoVienCoCCHNController({String? existingFullName}) {
    fullNameController.text = existingFullName ?? '';
    _useDefaultMedicalData();
    fetchAllApiData();
  }

  /// Hàm chọn ảnh từ Thư viện hoặc Camera
  Future<void> pickWorkCardImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85, // Nén nhẹ ảnh để tối ưu dung lượng
      );

      if (pickedFile != null) {
        workCardImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  /// Hàm xóa ảnh đã chọn
  void removeWorkCardImage() {
    workCardImage = null;
    notifyListeners();
  }

  /// 🚀 Gửi hồ sơ Cứu hộ viên + Lưu chuỗi Base64 vào bảng LuuAnh
  Future<bool> submitHoSoToFirebase(String currentUserId) async {
    isSubmitting = true;
    notifyListeners();

    try {
      // 🟢 1. Nếu có chọn ảnh thẻ công tác -> Chuyển sang Base64 & Lưu vào bảng LuuAnh
      if (workCardImage != null) {
        String? base64String = await _luuAnhService.convertFileToBase64(
          workCardImage!,
        );

        if (base64String != null) {
          await _luuAnhService.saveLuuAnh(
            maNguoiDung: currentUserId,
            base64Image: base64String,
            maPhanLoaiAnh: 'THE_CONG_TAC',
            maMoTa: 'Ảnh thẻ công tác bệnh viện (Base64)',
          );
        }
      }

      // 🟢 2. Lưu thông tin hồ sơ vào bảng HoSoCuuHoCoCCHN
      final hoSo = HoSoCuuHoCoCCHNModel(
        maNguoiDung: currentUserId,
        soCanCuoc: cccdCardNoController.text.trim(),
        ngayCapCanCuoc: dobController.text.trim(),
        ngayHetHanCanCuoc: cccdIssueDateController.text.trim(),
        coQuanCapCanCuoc: cccdIssuerController.text.trim(),
        maCCHN: cchnNoController.text.trim(),
        ngayCapCCHN: cchnIssueDateController.text.trim(),
        coQuanCapCCHN: selectedCchnIssuer ?? 'Bộ Y Tế',
        maTheChuyenNganh: employeeIdController.text.trim(),
        chucDanh: positionController.text.trim(),
        tenChuyenNganh: scopeController.text.trim(),
        donViCongTac: hospitalController.text.trim(),
        thoiGianOnline: DateTime.now().toIso8601String(),
        maTrangThaiHoSo: 'CHO_DUYET',
      );

      bool isSuccess = await _hoSoService.saveHoSoCuuHo(hoSo);
      return isSuccess;
    } catch (e) {
      debugPrint('🔴 Lỗi gửi hồ sơ: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllApiData() async {
    isLoadingApi = true;
    notifyListeners();

    try {
      await fetchIssuersFromOpenApi();
    } catch (e) {
      debugPrint('Lỗi gọi API: $e');
    } finally {
      isLoadingApi = false;
      notifyListeners();
    }
  }

  Future<void> verifyCchnFormat() async {
    String cchnNo = cchnNoController.text.trim();

    if (cchnNo.isEmpty) {
      isCchnValid = false;
      notifyListeners();
      return;
    }

    isVerifying = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    final RegExp cchnRegex = RegExp(r'^\d{5,6}\/([A-Z]{3}|BYT)-CCHN$');
    isCchnValid = cchnRegex.hasMatch(cchnNo);

    isVerifying = false;
    notifyListeners();
  }

  Future<void> fetchIssuersFromOpenApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/p/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        cchnIssuerList = ['Bộ Y Tế'];
        cchnIssuerList.addAll(
          data.map((item) => 'Sở Y tế ${item['name']}').toList(),
        );
        selectedCchnIssuer = cchnIssuerList.first;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi fetch Open API Tỉnh Thành: $e');
    }
  }

  void _useDefaultMedicalData() {
    cchnIssuerList = [
      'Bộ Y Tế',
      'Sở Y tế Thành phố Hồ Chí Minh',
      'Sở Y tế Thành phố Hà Nội',
    ];
    selectedCchnIssuer = cchnIssuerList.first;
    notifyListeners();
  }

  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setCchnIssuer(String val) {
    selectedCchnIssuer = val;
    notifyListeners();
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
    cccdController.dispose();
    fullNameController.dispose();
    cccdCardNoController.dispose();
    dobController.dispose();
    cccdIssueDateController.dispose();
    cccdIssuerController.dispose();
    cchnNoController.dispose();
    cchnIssueDateController.dispose();
    scopeController.dispose();
    positionController.dispose();
    employeeIdController.dispose();
    hospitalController.dispose();
    super.dispose();
  }
}
