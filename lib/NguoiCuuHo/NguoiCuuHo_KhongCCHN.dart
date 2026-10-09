import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NguoicuuhoKhongcchn extends StatefulWidget {
  const NguoicuuhoKhongcchn({super.key});

  @override
  State<NguoicuuhoKhongcchn> createState() => _NguoicuuhoKhongcchnState();
}

class _NguoicuuhoKhongcchnState extends State<NguoicuuhoKhongcchn> {
  final _formKey = GlobalKey<FormState>();

  // Section 1 Controllers
  final TextEditingController _vneidController = TextEditingController(
    text: '079095002148',
  );
  final TextEditingController _fullNameController = TextEditingController(
    text: 'TRẦN VĂN MINH',
  );
  final TextEditingController _dobController = TextEditingController(
    text: '15/08/1992',
  );
  final TextEditingController _addressController = TextEditingController(
    text: 'Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
  );
  String _gender = 'Nam';

  // Section 2 Controllers
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedExperience = 'Khoảng 3  5 năm';
  final List<String> _experienceOptions = [
    'Dưới 1 năm',
    'Khoảng 1  3 năm',
    'Khoảng 3  5 năm',
    'Trên 5 năm',
  ];

  // Selected skills
  final List<String> _availableSkills = [
    'CPR & AED',
    'Băng bó & Nẹp xương',
    'Nghiệm pháp Heimlich',
    'Sơ cứu bỏng',
  ];
  final Set<String> _selectedSkills = {
    'CPR & AED',
    'Băng bó & Nẹp xương',
    'Nghiệm pháp Heimlich',
    'Sơ cứu bỏng',
  };

  // --- Khai báo thêm biến trạng thái cho Section 1 ---
  String _selectedCity = 'TP. Hồ Chí Minh';
  String _selectedDistrict = 'Quận 1';
  final TextEditingController _streetController = TextEditingController(
    text: 'Phường Bến Nghé',
  );

  final List<String> _cityList = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
  ];

  final Map<String, List<String>> _districtMap = {
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

  // --- Dialog chọn địa chỉ ---
  void _showAddressDialog() {
    String tempCity = _selectedCity;
    String tempDistrict = _selectedDistrict;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> currentDistricts = _districtMap[tempCity] ?? [];
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
                    // Chọn Thành phố / Tỉnh
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
                          items: _cityList
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
                                tempDistrict = _districtMap[val]!.first;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chọn Quận / Huyện
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

                    // Nhập đường / phường
                    const Text(
                      'Số nhà / Tên đường / Phường',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _streetController,
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
                    setState(() {
                      _selectedCity = tempCity;
                      _selectedDistrict = tempDistrict;
                      _addressController.text =
                          '${_streetController.text.trim()}, $_selectedDistrict, $_selectedCity';
                    });
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

  // --- SECTION 1 DỰA TRÊN YÊU CẦU ---
  Widget _buildSection1() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIndex('1'),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Định danh Cổng dân (eKYC)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Row(
                children: const [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 16,
                    color: Color(0xFF00897B),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'CSDL Dân cư kết\nnối',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00897B),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Số CCCD / Định danh VNeID',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _vneidController,
                  suffixIcon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00897B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCE4EC),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                icon: const Icon(
                  Icons.sync,
                  size: 16,
                  color: Color(0xFFC80815),
                ),
                label: const Text(
                  'Trích xuất lại',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC80815),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.brightness_1,
                          size: 8,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DỮ LIỆU XÁC THỰC ĐỊNH DANH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Cập nhật: Hôm nay',
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 1. Ô Họ và tên cho phép nhập
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Họ và tên',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            TextFormField(
                              controller: _fullNameController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Ngày sinh & Giới tính (Cho chọn Nam/Nữ)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, _dobController),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày sinh',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dobController.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Giới tính',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _gender = 'Nam'),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gender == 'Nam'
                                            ? const Color(0xFF00897B)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Nam',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _gender == 'Nam'
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _gender = 'Nữ'),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gender == 'Nữ'
                                            ? const Color(0xFF00897B)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Nữ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _gender == 'Nữ'
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Địa chỉ hiện Dialog chọn Thành phố, Quận, Đường
                InkWell(
                  onTap: _showAddressDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Địa bàn thường trú / Khu vực sẵn sàng trực',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _addressController.text.isNotEmpty
                                    ? _addressController.text
                                    : 'Nhấn để chọn địa chỉ...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isAgreed = false;

  Future<void> _selectDate(
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
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Xác Thực CHV (Không CCHN)',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFB71C1C),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Định danh Cổng dân (eKYC)
              _buildSection1(),

              const SizedBox(height: 16),

              // Section 2: Kinh nghiệm & Đội cứu trợ
              _buildSection2(),

              const SizedBox(height: 16),

              // Section 3: Ảnh thực tế
              _buildSection3(),

              const SizedBox(height: 16),

              // Terms & Information Box
              _buildTermsAndInfoBox(),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (!_isAgreed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng tích chọn cam kết năng lực trước khi gửi!',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang gửi yêu cầu xác thực...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'GỬI YÊU CẦU XÁC THỰC CỨU HỘ VIÊN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- SECTION 2 ---
  Widget _buildSection2() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIndex('2'),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kinh nghiệm & Đội cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              _buildTag(
                '• Xét duyệt thực chiến \n• Không cần CCHN',
                const Color(0xFFE0F2F1),
                const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Đội nhóm
          const Text(
            'Đội nhóm / Tổ chức cứu nạn từng tham gia',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _buildInputField(
            controller: _organizationController,
            hintText: '............................',
            suffixIcon: const Icon(
              Icons.group_outlined,
              size: 18,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ghi rõ tên nhóm tự quản, câu lạc bộ tình nguyện hoặc tổ chức trực thuộc',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 10),

          // Số năm / Thâm niên
          const Text(
            'Số năm / Thâm niên hoạt động cứu hộ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedExperience,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _experienceOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedExperience = val);
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.history, size: 18, color: Colors.teal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Các kỹ năng sơ cấp cứu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Các kỹ năng sơ cấp cứu thành thạo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                'Tự do kê khai kỹ năng',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................\n............................',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFEEF2FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 8),

          // Skill Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSkills.remove(skill);
                    } else {
                      _selectedSkills.add(skill);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE0F2F1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: isSelected
                            ? const Color(0xFF00897B)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? const Color(0xFF00695C)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Tóm tắt các ca cứu hộ
          const Text(
            'Tóm tắt các ca cứu hộ thực tế từng tham gia',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _summaryController,
            maxLines: 4,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................\n............................',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFEEF2FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Giúp điều phối viên ưu tiên phân công đúng tình huống',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
              Text(
                '178/500 ký tự',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION 3 ---
  Widget _buildSection3() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIndex('3'),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ảnh thực tế',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              _buildTag(
                'Không bắt buộc bằng Y khoa',
                const Color(0xFFE0F2F1),
                const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Ảnh hoạt động thiện nguyện thực tế',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                'Đã chọn 2/4 ảnh',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Hình ảnh minh chứng tham gia sơ cứu, diễn tập hoặc hỗ trợ cộng đồng (Tối đa 4 ảnh, định dạng JPG/PNG)',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 8),

          // Photos Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPhotoThumbnail(
                  'Ảnh sơ cứu tai nạn',
                  'https://picsum.photos/200/200?random=1',
                ),
                const SizedBox(width: 8),
                _buildPhotoThumbnail(
                  'Tập huấn Red Cross',
                  'https://picsum.photos/200/200?random=2',
                ),
                const SizedBox(width: 8),
                _buildAddPhotoButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ghi chú thêm
          const Text(
            'Ghi chú thêm & Người xác minh (tùy chọn)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  '............................\n............................',
              hintStyle: const TextStyle(color: Colors.grey),
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
    );
  }

  // --- TERMS AND INFO BOX ---
  Widget _buildTermsAndInfoBox() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isAgreed,
              activeColor: const Color(0xFF00897B),
              onChanged: (val) {
                setState(() => _isAgreed = val ?? false);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: 'Tôi cam kết thực hiện hỗ trợ sơ cứu trong ',
                      ),
                      TextSpan(
                        text: 'giới hạn năng lực ban đầu',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ', giữ an toàn tuyệt đối cho người bị nạn và không thực hiện các thủ thuật y khoa chuyên sâu vượt quá thẩm quyền.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF00897B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thẩm định năng lực thực tế siêu tốc (2 - 4 giờ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Hồ sơ Cứu hộ viên không có CCHN y tế được Ban điều phối 115 xác minh kỹ năng sơ cứu và kích hoạt quyền cứu nạn khẩn cấp trong vòng ',
                          ),
                          TextSpan(
                            text: '2 - 4 giờ làm việc.',
                            style: TextStyle(
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER BUILDERS ---
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionIndex(String number) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFFC80815),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        filled: true,
        fillColor: const Color(0xFFEEF2FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 6, right: 6),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String label, String imageUrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          right: 6,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo_outlined, color: Colors.teal, size: 24),
          SizedBox(height: 4),
          Text(
            'Thêm ảnh',
            style: TextStyle(
              fontSize: 10,
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
