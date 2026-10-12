import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Nguoicuuhococchn extends StatefulWidget {
  const Nguoicuuhococchn({super.key});

  @override
  State<Nguoicuuhococchn> createState() => _NguoicuuhococchnState();
}

class _NguoicuuhococchnState extends State<Nguoicuuhococchn> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các ô nhập
  final TextEditingController _cccdController = TextEditingController(
    text: '079092004581',
  );
  final TextEditingController _fullNameController = TextEditingController(
    text: 'BS. NGUYỄN VĂN A',
  );
  final TextEditingController _cccdCardNoController = TextEditingController(
    text: '079092004581',
  );
  final TextEditingController _dobController = TextEditingController(
    text:
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
  );
  final TextEditingController _cccdIssueDateController = TextEditingController(
    text:
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
  );
  final TextEditingController _cccdIssuerController = TextEditingController(
    text: 'Bộ Y Tế',
  );

  final TextEditingController _cchnNoController = TextEditingController(
    text: '010482/HCM-CCHN',
  );
  final TextEditingController _cchnIssuerController = TextEditingController(
    text: 'Sở Y tế TP. HCM',
  );
  final TextEditingController _cchnIssueDateController = TextEditingController(
    text:
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
  );

  final TextEditingController _hospitalController = TextEditingController(
    text: 'Bệnh viện Chợ Rẫy (Khoa Cấp cứu)',
  );
  final TextEditingController _positionController = TextEditingController(
    text: 'Bác sĩ Cấp cứu & Can thiệp khẩn cấp',
  );
  final TextEditingController _employeeIdController = TextEditingController(
    text: 'CR-ICU-8821',
  );

  // Trạng thái chọn
  String _gender = 'Nam';
  bool _isAgreed = false;
  String _selectedScope = 'Hồi sức cấp cứu / Ngoại khoa / Nội chung';

  final List<String> _scopeList = [
    'Hồi sức cấp cứu / Ngoại khoa / Nội chung',
    'Nội khoa',
    'Ngoại khoa',
    'Nhi khoa',
    'Sản phụ khoa',
  ];

  String _selectedCchnIssuer = 'Sở Y tế TP. HCM';
  final List<String> _cchnIssuerList = [
    'Bộ Y Tế',
    'Sở Y tế TP. HCM',
    'Sở Y tế Hà Nội',
    'Sở Y tế Đà Nẵng',
    'Sở Y tế Cần Thơ',
  ];

  String _selectedHospital = 'Bệnh viện Chợ Rẫy (Khoa Cấp cứu)';
  final List<String> _hospitalList = [
    'Bệnh viện Chợ Rẫy (Khoa Cấp cứu)',
    'Bệnh viện Nhân dân 115',
    'Bệnh viện Đại học Y Dược TP.HCM',
    'Bệnh viện Thống Nhất',
    'Bệnh viện Bạch Mai',
  ];
  // Hàm chọn ngày chung
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
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Xác Thực NCV (Có CCHN)',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFC80815),
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
            children: [
              // Section 1: Định danh điện tử (eKYC)
              _buildSection1(),
              const SizedBox(height: 16),
              // Section 2: Chứng chỉ hành nghề y tế (CCHN)
              _buildSection2(),
              const SizedBox(height: 16),
              // Section 3: Đơn vị công tác & Thẻ ngành
              _buildSection3(),
              const SizedBox(height: 16),
              // Terms & Info Box
              _buildTermsAndInfo(),
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
                            'Vui lòng đồng ý với cam kết trước khi gửi yêu cầu!',
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

  // --- SECTION 1 ---
  Widget _buildSection1() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge,
                  color: Color(0xFF00897B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1. Định danh điện tử (eKYC)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đã kết nối\nVNeID',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel(
            'Số Căn cước công dân (CCCD / VNeID) gắn chip',
            isRequired: true,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _cccdController,
                  suffixIcon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00897B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang trích xuất dữ liệu từ VNeID...'),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16, color: Colors.white),
                label: const Text(
                  'Trích xuất dữ liệu',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00897B),
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đã kết nối CSDL Dân cư Quốc gia / VNeID (Mức 2): Trích xuất thành công',
                    style: TextStyle(fontSize: 11, color: Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DỮ LIỆU CÔNG DÂN TRÍCH XUẤT TỰ ĐỘNG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.check_circle, size: 12, color: Color(0xFF00897B)),
                  SizedBox(width: 2),
                  Text(
                    'Đã xác thực',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Họ và tên đầy đủ',
                  controller: _fullNameController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormGroup(
                  label: 'Số thẻ CCCD gắn chip',
                  controller: _cccdCardNoController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Ngày sinh với DatePicker
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày sinh',
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _dobController),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Giới tính toggle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giới tính',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _gender = 'Nam'),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _gender == 'Nam'
                                      ? const Color(0xFF00BFA5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Nam',
                                  style: TextStyle(
                                    color: _gender == 'Nam'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _gender == 'Nữ'
                                      ? const Color(0xFF00BFA5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Nữ',
                                  style: TextStyle(
                                    color: _gender == 'Nữ'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Ngày cấp CCCD với DatePicker
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày cấp CCCD',
                  controller: _cccdIssueDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _cccdIssueDateController),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFormGroup(
            label: 'Cơ quan cấp',
            controller: _cccdIssuerController,
          ),
        ],
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2. Chứng chỉ hành nghề y tế (CCHN)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bắt buộc theo Luật Khám chữa bệnh',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Số hiệu chứng chỉ hành nghề', isRequired: true),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _cchnNoController,
                  suffixIcon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00897B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 16, color: Colors.white),
                label: const Text(
                  'Đối soát BYT',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00897B),
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đã đối soát cổng CSDL Quốc gia Y tế: Hợp lệ & Đang hiệu lực',
                    style: TextStyle(fontSize: 11, color: Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Phạm vi hoạt động chuyên môn', isRequired: true),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedScope,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: _scopeList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedScope = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Cơ quan cấp', isRequired: true),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.only(left: 8, right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCchnIssuer,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          items: _cchnIssuerList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedCchnIssuer = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày cấp',
                  isRequired: true,
                  controller: _cchnIssueDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _cchnIssueDateController),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Bản chụp gốc CCHN & Bằng tốt nghiệp Bác sĩ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CCHN_NguyenVanAn.pdf',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '2.8 MB • Tải lên 10:24 sáng nay',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3. Đơn vị công tác & Thẻ ngành',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bệnh viện tiếp nhận và phối hợp cấp cứu',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFieldLabel(
            'Bệnh viện / Cơ sở khám chữa bệnh hiện tại',
            isRequired: true,
          ),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedHospital,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: _hospitalList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedScope = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildFormGroup(
            label: 'Chức danh chuyên môn trực tiếp',
            controller: _positionController,
            prefixIcon: const Icon(
              Icons.medical_services_outlined,
              color: Colors.teal,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Mã thẻ nhân viên',
                  controller: _employeeIdController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Ảnh thẻ công tác'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'the_nganh.jpg',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.image, color: Colors.teal, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TERMS & INFO BOX ---
  Widget _buildTermsAndInfo() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isAgreed,
              activeColor: const Color(0xFFB71C1C),
              onChanged: (val) {
                setState(() {
                  _isAgreed = val ?? false;
                });
              },
            ),
            const Expanded(
              child: Text(
                'Tôi cam kết tính xác thực của thông tin cung cấp theo Luật Khám bệnh, chữa bệnh 2023 và tự chịu trách nhiệm chuyên môn khi tiếp nhận điều phối cấp cứu khẩn cấp từ Tổng đài 115.',
                style: TextStyle(fontSize: 11, height: 1.3),
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
  Widget _buildFormGroup({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        _buildInputField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 6, left: 6),
                child: prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
