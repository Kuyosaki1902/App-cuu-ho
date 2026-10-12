// File: lib/screens/DangKy.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'DangNhap.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart'; // Kiểm tra lại đường dẫn
import 'package:cuhokhancap/firebase/firebase_service.dart'; // Kiểm tra lại đường dẫn

// --- MODEL TỈNH/THÀNH ---
class Province {
  final int code;
  final String name;
  final List<District> districts;
  Province({required this.code, required this.name, required this.districts});
  factory Province.fromJson(Map<String, dynamic> json) {
    var list = json['districts'] as List? ?? [];
    List<District> districtList = list
        .map((i) => District.fromJson(i))
        .toList();
    return Province(
      code: json['code'],
      name: json['name'],
      districts: districtList,
    );
  }
}

class District {
  final int code;
  final String name;
  District({required this.code, required this.name});
  factory District.fromJson(Map<String, dynamic> json) {
    return District(code: json['code'], name: json['name']);
  }
}

// --- WIDGET CHÍNH ---
class DangKy extends StatefulWidget {
  const DangKy({super.key});

  @override
  State<DangKy> createState() => _DangKyState();
}

class _DangKyState extends State<DangKy> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoadingSubmit = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  final List<String> _genders = ['Nam', 'Nữ'];

  List<Province> _provinces = [];
  bool _isLoadingProvinces = true;

  Province? _selectedProvince;
  District? _selectedDistrict;

  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/?depth=2'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _provinces = data.map((item) => Province.fromJson(item)).toList();
            _isLoadingProvinces = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  String removeDiacritics(String str) {
    var withDia =
        'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    var withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
      str = str.replaceAll(
        withDia[i].toUpperCase(),
        withoutDia[i].toUpperCase(),
      );
    }
    return str;
  }

  void _showSearchableBottomSheet({
    required BuildContext context,
    required String title,
    required List<dynamic> items,
    required Function(dynamic) onSelected,
  }) {
    List<dynamic> filteredItems = List.from(items);
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Nhập để tìm kiếm...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredItems = items.where((item) {
                              final itemName = removeDiacritics(
                                item.name.toLowerCase(),
                              );
                              final query = removeDiacritics(
                                value.toLowerCase(),
                              );
                              return itemName.contains(query);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy kết quả',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return ListTile(
                                  title: Text(item.name),
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // --- HÀM XỬ LÝ ĐĂNG KÝ VÀ PUSH FIREBASE ĐÃ ĐƯỢC FIX LỖI XOAY VÒNG ---
  Future<void> _handleRegister() async {
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedGender == null ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập đủ thông tin ở các ô bắt buộc.', Colors.red);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu và Xác nhận mật khẩu không khớp!', Colors.red);
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar('Bạn cần đồng ý với Điều khoản sử dụng.', Colors.red);
      return;
    }

    // Bật hiệu ứng loading
    setState(() => _isLoadingSubmit = true);

    try {
      String maGioiTinh = _selectedGender == 'Nam' ? 'gioitinh1' : 'gioitinh2';
      String specificAddress = _addressController.text.trim();
      String finalAddress = specificAddress.isEmpty
          ? '${_selectedDistrict!.name}, ${_selectedProvince!.name}'
          : '$specificAddress, ${_selectedDistrict!.name}, ${_selectedProvince!.name}';

      NguoiDungModel newUser = NguoiDungModel(
        hoTen: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        diaChi: finalAddress,
        queQuan: '${_selectedProvince!.name}',
        soDienThoai: _phoneController.text.trim(),
        maGioiTinh: maGioiTinh,
        maVaiTro: 'vaitro1',
        ngaySinh: _selectedDate!,
        ngayTao: DateTime.now(),
        matKhau: _passwordController.text,
      );

      bool isSuccess = await _firebaseService.taoTaiKhoan(newUser);

      if (isSuccess) {
        _showSnackBar('Đăng ký tài khoản thành công!', Colors.green);
        // Chuyển thẳng về trang đăng nhập và xóa toàn bộ trang trước đó
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DangNhap()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar(
          'Có lỗi xảy ra khi tạo tài khoản. Vui lòng thử lại!',
          Colors.red,
        );
      }
    } catch (e) {
      // Bắt lỗi nếu Firebase bị crash ngầm
      _showSnackBar('Hệ thống đang bận hoặc lỗi mạng: $e', Colors.red);
    } finally {
      // LUÔN LUÔN TẮT hiệu ứng loading bất kể thành công hay thất bại
      if (mounted) {
        setState(() => _isLoadingSubmit = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng ký tài khoản',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeaderBanner(),
              const SizedBox(height: 16),
              _buildRegistrationForm(context),
              const SizedBox(height: 16),
              _buildTermsAndSubmit(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HỆ THỐNG CẤP CỨU 115',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Tạo tài khoản Cứu hộ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            label: 'Họ và tên đầy đủ',
            hintText: 'Nhập họ và tên',
            icon: Icons.person,
            controller: _fullNameController,
          ),
          const SizedBox(height: 16),

          // Đã fix lỗi tràn layout bằng isExpanded: true
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngày sinh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'dd/mm/yyyy',
                        prefixIcon: const Icon(
                          Icons.cake,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                          onPressed: () async {
                            // DÙNG context ĐƯỢC TRUYỀN TỪ HÀM build XUỐNG
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _dobController.text = DateFormat(
                                  'dd/MM/yyyy',
                                ).format(picked);
                              });
                            }
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giới tính',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded:
                          true, // Ngăn chặn lỗi tràn chữ trên màn hình nhỏ
                      value: _selectedGender,
                      items: _genders
                          .map(
                            (String gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                      ),
                      hint: const Text('Chọn', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField(
            label: 'Số điện thoại',
            hintText: 'Nhập số điện thoại',
            icon: Icons.phone,
            controller: _phoneController,
            isPhone: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Email (Tùy chọn)',
            hintText: 'Nhập email',
            icon: Icons.email,
            controller: _emailController,
          ),
          const SizedBox(height: 16),

          const Text(
            'Tỉnh/Thành & Quận/Huyện',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _provinceController,
                  readOnly: true,
                  onTap: () {
                    _showSearchableBottomSheet(
                      context: context,
                      title: 'Chọn Tỉnh',
                      items: _provinces,
                      onSelected: (selected) {
                        setState(() {
                          _selectedProvince = selected as Province;
                          _provinceController.text = _selectedProvince!.name;
                          _selectedDistrict = null;
                          _districtController.clear();
                        });
                      },
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Tỉnh/Thành',
                    hintStyle: const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _districtController,
                  readOnly: true,
                  onTap: () {
                    if (_selectedProvince == null) return;
                    _showSearchableBottomSheet(
                      context: context,
                      title: 'Chọn Huyện',
                      items: _selectedProvince!.districts,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDistrict = selected as District;
                          _districtController.text = _selectedDistrict!.name;
                        });
                      },
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Quận/Huyện',
                    hintStyle: const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField(
            label: 'Địa chỉ cụ thể (Tùy chọn)',
            hintText: 'Số nhà, tên đường...',
            icon: Icons.home,
            controller: _addressController,
          ),
          const SizedBox(height: 16),

          _buildPasswordField(
            label: 'Mật khẩu',
            controller: _passwordController,
            isObscure: _obscurePassword,
            toggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            label: 'Xác nhận mật khẩu',
            controller: _confirmPasswordController,
            isObscure: _obscureConfirmPassword,
            toggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.black54),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(fontSize: 14, color: Colors.black54),
            prefixIcon: const Icon(Icons.lock, color: Colors.grey, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: toggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndSubmit() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            ),
            const Expanded(
              child: Text(
                "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật.",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52, // Đã fix chiều cao nút bấm để UI cân đối hơn
          child: ElevatedButton(
            onPressed: _isLoadingSubmit ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoadingSubmit
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ĐĂNG KÝ TÀI KHOẢN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
