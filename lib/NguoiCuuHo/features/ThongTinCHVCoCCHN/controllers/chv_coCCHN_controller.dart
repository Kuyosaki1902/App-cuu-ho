import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CuuHoVienCoCCHNController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Controllers cho các ô nhập
  final cccdController = TextEditingController(text: '079092004581');
  final fullNameController = TextEditingController(text: 'BS. NGUYỄN VĂN A');
  final cccdCardNoController = TextEditingController(text: '079092004581');
  final dobController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssueDateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final cccdIssuerController = TextEditingController(text: 'Bộ Y Tế');

  final cchnNoController = TextEditingController(text: '010482/HCM-CCHN');
  final cchnIssueDateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );

  final positionController = TextEditingController(
    text: 'Bác sĩ Cấp cứu & Can thiệp khẩn cấp',
  );
  final employeeIdController = TextEditingController(text: 'CR-ICU-8821');

  // Trạng thái chọn
  String gender = 'Nam';
  bool isAgreed = false;

  String selectedScope = 'Hồi sức cấp cứu / Ngoại khoa / Nội chung';
  final List<String> scopeList = [
    'Hồi sức cấp cứu / Ngoại khoa / Nội chung',
    'Nội khoa',
    'Ngoại khoa',
    'Nhi khoa',
    'Sản phụ khoa',
  ];

  String selectedCchnIssuer = 'Sở Y tế TP. HCM';
  final List<String> cchnIssuerList = [
    'Bộ Y Tế',
    'Sở Y tế TP. HCM',
    'Sở Y tế Hà Nội',
    'Sở Y tế Đà Nẵng',
    'Sở Y tế Cần Thơ',
  ];

  String selectedHospital = 'Bệnh viện Chợ Rẫy (Khoa Cấp cứu)';
  final List<String> hospitalList = [
    'Bệnh viện Chợ Rẫy (Khoa Cấp cứu)',
    'Bệnh viện Nhân dân 115',
    'Bệnh viện Đại học Y Dược TP.HCM',
    'Bệnh viện Thống Nhất',
    'Bệnh viện Bạch Mai',
  ];

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
    positionController.dispose();
    employeeIdController.dispose();
    super.dispose();
  }

  // --- CÁC HÀM XỬ LÝ LOGIC ---
  void setGender(String val) {
    gender = val;
    notifyListeners();
  }

  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setScope(String val) {
    selectedScope = val;
    notifyListeners();
  }

  void setCchnIssuer(String val) {
    selectedCchnIssuer = val;
    notifyListeners();
  }

  void setHospital(String val) {
    selectedHospital = val;
    notifyListeners();
  }

  // Hàm chọn ngày chung
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
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00897B)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
      notifyListeners();
    }
  }
}
