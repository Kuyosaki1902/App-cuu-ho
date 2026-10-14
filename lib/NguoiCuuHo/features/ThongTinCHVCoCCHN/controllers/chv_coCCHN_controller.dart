import 'dart:convert';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/HospitalApiService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CuuHoVienCoCCHNController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final cccdController = TextEditingController();
  final fullNameController = TextEditingController();
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

  final employeeIdController = TextEditingController(text: 'CR-ICU-8821');

  bool isAgreed = false;
  bool isLoadingApi = false;
  bool isLoadingDistrict = false;

  // Trạng thái chọn
  String? selectedScope;
  List<String> scopeList = [];

  String? selectedPosition;
  List<String> positionList = [];

  String? selectedCchnIssuer;
  List<String> cchnIssuerList = [];

  // 🟢 Biến quản lý Tỉnh/Thành phố & Quận/Huyện
  String? selectedRegion;
  List<String> regionList = [];
  Map<String, int> regionCodeMap = {}; // Lưu code tỉnh để lấy quận huyện

  String? selectedDistrict;
  List<String> districtList = [];

  String? selectedHospital;
  List<String> hospitalList = [];

  CuuHoVienCoCCHNController({String? existingFullName}) {
    fullNameController.text = existingFullName ?? 'BS. NGUYỄN VĂN A';

    // 🟢 1. Khởi tạo danh mục mặc định ban đầu để UI luôn có dữ liệu hiển thị
    _useDefaultMedicalData();

    // 🟢 2. Tải dữ liệu API Tỉnh/Thành từ Open API
    fetchAllApiData();
  }

  Future<void> fetchAllApiData() async {
    isLoadingApi = true;
    notifyListeners();

    try {
      await fetchProvincesAndIssuersFromOpenApi();
    } catch (e) {
      debugPrint('Lỗi gọi API: $e');
    } finally {
      isLoadingApi = false;
      notifyListeners();
    }
  }

  // 1. Lấy danh sách 63 Tỉnh/Thành phố & Cơ quan cấp CCHN từ Open API Việt Nam
  Future<void> fetchProvincesAndIssuersFromOpenApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/p/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<String> tempRegions = [];
        Map<String, int> tempCodeMap = {};

        for (var item in data) {
          String name = item['name'].toString();
          int code = item['code'];
          tempRegions.add(name);
          tempCodeMap[name] = code;
        }

        if (tempRegions.isNotEmpty) {
          regionList = tempRegions;
          regionCodeMap = tempCodeMap;

          // Chọn mặc định TP. Hồ Chí Minh hoặc tỉnh đầu tiên
          selectedRegion = regionList.firstWhere(
            (e) => e.contains('Hồ Chí Minh'),
            orElse: () => regionList.first,
          );

          // Tải danh sách Quận/Huyện và Bệnh viện tương ứng
          fetchDistrictsByRegion(selectedRegion!);
          loadHospitalsByRegion(selectedRegion!);
        }

        // Danh sách Cơ quan cấp CCHN
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

  // 🟢 1. Cập nhật hàm loadHospitalsByRegion nhận thêm tham số districtName
  Future<void> loadHospitalsByRegion(
    String regionName, {
    String? districtName,
  }) async {
    isLoadingApi = true;
    notifyListeners();

    List<Map<String, String>> result =
        await HospitalApiService.fetchHospitalsByProvince(
          regionName,
          districtName: districtName,
        );

    if (result.isNotEmpty) {
      hospitalList = result
          .map((e) => e['name']!)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      hospitalList.sort((a, b) => a.compareTo(b));
      selectedHospital = hospitalList.first;
    } else {
      // Nếu quận/huyện đó chưa có dữ liệu trên bản đồ, hiển thị tên bệnh viện mặc định theo khu vực
      String areaText = districtName != null
          ? '$districtName, $regionName'
          : regionName;
      hospitalList = [
        'Bệnh viện Đa khoa $areaText',
        'Trung tâm Y tế $areaText',
        'Bệnh viện Cấp cứu 115 $regionName',
      ];
      selectedHospital = hospitalList.first;
    }

    isLoadingApi = false;
    notifyListeners();
  }

  // 🟢 2. Cập nhật hàm fetchDistrictsByRegion
  Future<void> fetchDistrictsByRegion(String regionName) async {
    int? code = regionCodeMap[regionName];
    if (code == null) return;

    isLoadingDistrict = true;
    selectedDistrict = null;
    districtList = [];
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/p/$code?depth=2'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> districts = data['districts'] ?? [];

        districtList = districts.map((e) => e['name'].toString()).toList();
        if (districtList.isNotEmpty) {
          selectedDistrict = districtList.first;
          // 🟢 Tự động tải danh sách bệnh viện thuộc Quận/Huyện đầu tiên
          loadHospitalsByRegion(regionName, districtName: selectedDistrict);
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetch Quận Huyện: $e');
    } finally {
      isLoadingDistrict = false;
      notifyListeners();
    }
  }

  // 🟢 3. Cập nhật hàm setDistrict khi người dùng bấm chọn Quận/Huyện khác
  void setDistrict(String val) {
    if (selectedDistrict != val) {
      selectedDistrict = val;
      if (selectedRegion != null) {
        // Tải lại Bệnh viện chính xác theo Quận/Huyện vừa chọn
        loadHospitalsByRegion(selectedRegion!, districtName: val);
      }
    }
    notifyListeners();
  }

  // Dữ liệu danh mục chuẩn mặc định
  void _useDefaultMedicalData() {
    regionList = [
      'Thành phố Hồ Chí Minh',
      'Thành phố Hà Nội',
      'Thành phố Đà Nẵng',
      'Thành phố Cần Thơ',
      'Thành phố Hải Phòng',
    ];
    selectedRegion = regionList.first;

    districtList = ['Quận 1', 'Quận 3', 'Quận 5', 'Quận 10', 'Quận Tân Bình'];
    selectedDistrict = districtList.first;

    cchnIssuerList = [
      'Bộ Y Tế',
      'Sở Y tế Thành phố Hồ Chí Minh',
      'Sở Y tế Thành phố Hà Nội',
    ];
    selectedCchnIssuer = cchnIssuerList.first;

    hospitalList = [
      'Bệnh viện Chợ Rẫy',
      'Bệnh viện Nhân dân 115',
      'Bệnh viện Đại học Y Dược TP.HCM',
      'Bệnh viện Thống Nhất',
      'Bệnh viện Bạch Mai',
    ];
    selectedHospital = hospitalList.first;

    scopeList = [
      'Hồi sức cấp cứu / Ngoại khoa / Nội chung',
      'Nội khoa',
      'Ngoại khoa',
      'Nhi khoa',
      'Sản phụ khoa',
    ];
    selectedScope = scopeList.first;

    positionList = [
      'Bác sĩ Cấp cứu & Can thiệp khẩn cấp',
      'Bác sĩ Trưởng khoa',
      'Bác sĩ Điều trị',
      'Y sĩ Cấp cứu',
      'Điều dưỡng Cấp cứu',
    ];
    selectedPosition = positionList.first;

    notifyListeners();
  }

  // Setters
  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setScope(String val) {
    selectedScope = val;
    notifyListeners();
  }

  void setPosition(String val) {
    selectedPosition = val;
    notifyListeners();
  }

  void setCchnIssuer(String val) {
    selectedCchnIssuer = val;
    notifyListeners();
  }

  void setRegion(String val) {
    if (selectedRegion != val) {
      selectedRegion = val;
      fetchDistrictsByRegion(val); // Cập nhật Quận/Huyện theo Tỉnh mới
      loadHospitalsByRegion(val); // Cập nhật Bệnh viện theo Tỉnh mới
    }
    notifyListeners();
  }

  void setHospital(String val) {
    selectedHospital = val;
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
      lastDate: DateTime.now(),
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
    employeeIdController.dispose();
    super.dispose();
  }
}
