import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CuuHoVienKhongCCHNController extends ChangeNotifier {
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
  final addressController = TextEditingController(
    text: 'Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
  );
  final streetController = TextEditingController(text: 'Phường Bến Nghé');
  String gender = 'Nam';

  // Address Selection
  String selectedCity = 'TP. Hồ Chí Minh';
  String selectedDistrict = 'Quận 1';

  final List<String> cityList = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
  ];

  final Map<String, List<String>> districtMap = {
    'TP. Hồ Chí Minh': [
      'Quận 1',
      'Quận 3',
      'Quận 7',
      'Quận Tân Bình',
      'TP. Thủ Đức',
    ],
    'Hà Nội': [
      'Quận Hoàn Kiếm',
      'Quận Ba Đình',
      'Quận Cầu Giấy',
      'Quận Đống Đa',
    ],
    'Đà Nẵng': ['Quận Hải Châu', 'Quận Thanh Khê', 'Quận Sơn Trà'],
    'Cần Thơ': ['Quận Ninh Kiều', 'Quận Bình Thủy'],
    'Hải Phòng': ['Quận Hồng Bàng', 'Quận Lê Chân'],
  };

  // Section 2 Controllers
  final organizationController = TextEditingController();
  final summaryController = TextEditingController();
  final noteController = TextEditingController();

  String selectedExperience = 'Khoảng 3  5 năm';
  final List<String> experienceOptions = [
    'Dưới 1 năm',
    'Khoảng 1  3 năm',
    'Khoảng 3  5 năm',
    'Trên 5 năm',
  ];

  final List<String> availableSkills = [
    'CPR & AED',
    'Băng bó & Nẹp xương',
    'Nghiệm pháp Heimlich',
    'Sơ cứu bỏng',
  ];
  final Set<String> selectedSkills = {
    'CPR & AED',
    'Băng bó & Nẹp xương',
    'Nghiệm pháp Heimlich',
    'Sơ cứu bỏng',
  };

  bool isAgreed = false;

  @override
  void dispose() {
    cccdController.dispose();
    fullNameController.dispose();
    cccdCardNoController.dispose();
    dobController.dispose();
    cccdIssueDateController.dispose();
    cccdIssuerController.dispose();
    addressController.dispose();
    streetController.dispose();
    organizationController.dispose();
    summaryController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // --- LOGIC METHOD ---
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

  void updateFullAddress(String city, String district, String street) {
    selectedCity = city;
    selectedDistrict = district;
    streetController.text = street;
    addressController.text =
        '${street.trim()}, $selectedDistrict, $selectedCity';
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
      firstDate: DateTime(1940),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFC80815)),
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

  // Dialog Chọn Địa Chỉ
  void showAddressDialog(BuildContext context) {
    String tempCity = selectedCity;
    String tempDistrict = selectedDistrict;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> currentDistricts = districtMap[tempCity] ?? [];
            if (!currentDistricts.contains(tempDistrict)) {
              tempDistrict = currentDistricts.first;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Chọn địa bàn thường trú',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thành phố / Tỉnh',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempCity,
                          isExpanded: true,
                          items: cityList
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                tempCity = val;
                                tempDistrict = districtMap[val]!.first;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Quận / Huyện',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempDistrict,
                          isExpanded: true,
                          items: currentDistricts
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                tempDistrict = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Số nhà / Tên đường / Phường',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: streetController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Nhập phường, tên đường...',
                        filled: true,
                        fillColor: const Color(0xFFEEF2FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    updateFullAddress(
                      tempCity,
                      tempDistrict,
                      streetController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
