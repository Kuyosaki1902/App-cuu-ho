import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'DangNhap.dart';

// --- MODEL DỮ LIỆU ---
class Province {
  final int code;
  final String name;
  final List<District> districts;

  Province({required this.code, required this.name, required this.districts});

  factory Province.fromJson(Map<String, dynamic> json) {
    var list = json['districts'] as List? ?? [];
    List<District> districtList = list.map((i) => District.fromJson(i)).toList();
    return Province(code: json['code'], name: json['name'], districts: districtList);
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  // Biến lưu trữ dữ liệu API
  List<Province> _provinces = [];
  bool _isLoadingProvinces = true;

  // Trạng thái được chọn
  Province? _selectedProvince;
  District? _selectedDistrict;

  // Controllers để hiển thị text trên UI
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  // Hàm gọi API lấy danh sách tỉnh thành, quận huyện
  Future<void> _fetchProvinces() async {
    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=2'));
      if (response.statusCode == 200) {
        // Cần utf8.decode để không bị lỗi font tiếng Việt
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _provinces = data.map((item) => Province.fromJson(item)).toList();
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProvinces = false;
      });
      debugPrint('Lỗi tải dữ liệu tỉnh thành: $e');
    }
  }

  // Hàm loại bỏ dấu tiếng Việt để tìm kiếm dễ dàng hơn
  String removeDiacritics(String str) {
    var withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
      str = str.replaceAll(withDia[i].toUpperCase(), withoutDia[i].toUpperCase());
    }
    return str;
  }

  // Bảng xổ xuống có chức năng tìm kiếm
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
      isScrollControlled: true, // Cho phép kéo bảng lên cao
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6, // Mở lên chiếm 60% màn hình
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // Thanh gạt nhỏ ở trên cùng
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    // Ô Tìm kiếm
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Nhập để tìm kiếm...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredItems = items.where((item) {
                              final itemName = removeDiacritics(item.name.toLowerCase());
                              final query = removeDiacritics(value.toLowerCase());
                              return itemName.contains(query);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Danh sách kết quả
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey)))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () {}),
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('115', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 16),
            _buildRegistrationForm(),
            const SizedBox(height: 16),
            _buildTermsAndSubmit(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('HỆ THỐNG CẤP CỨU 115', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tạo tài khoản Cứu hộ & Ứng cứu khẩn cấp', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('Kết nối nhanh chóng khi cần trợ giúp y tế hoặc tham gia tương trợ cộng đồng xung quanh bạn.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Text('Thông tin đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Bảo mật & An toàn', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(label: 'Họ và tên đầy đủ', hintText: 'Nhập họ và tên', prefixIcon: Icons.person_outline),
          const SizedBox(height: 16),
          const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Số điện thoại',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Text('+84', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF1565C0)),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(label: 'Địa chỉ Email (Tùy chọn)', hintText: 'example@domain.com', prefixIcon: Icons.mail_outline),
          const SizedBox(height: 16),

          // --- VÙNG CHỌN TỈNH THÀNH QUẬN HUYỆN ---
          const Text('Tỉnh / Thành phố và Quận / Huyện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Chọn Tỉnh Thành
              Expanded(
                child: _isLoadingProvinces
                    ? const Center(child: CircularProgressIndicator())
                    : TextField(
                        controller: _provinceController,
                        readOnly: true, // Không cho bàn phím mặc định bật lên
                        onTap: () {
                          _showSearchableBottomSheet(
                            context: context,
                            title: 'Chọn Tỉnh / Thành phố',
                            items: _provinces,
                            onSelected: (selected) {
                              setState(() {
                                _selectedProvince = selected as Province;
                                _provinceController.text = _selectedProvince!.name;
                                // Đổi tỉnh thành -> Xóa quận huyện đã chọn cũ
                                _selectedDistrict = null;
                                _districtController.clear();
                              });
                            },
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Tỉnh/Thành phố',
                          hintStyle: const TextStyle(fontSize: 13),
                          suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // Chọn Quận Huyện
              Expanded(
                child: TextField(
                  controller: _districtController,
                  readOnly: true,
                  onTap: () {
                    if (_selectedProvince == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn Tỉnh/Thành phố trước!')));
                      return;
                    }
                    _showSearchableBottomSheet(
                      context: context,
                      title: 'Chọn Quận / Huyện',
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
                    hintStyle: const TextStyle(fontSize: 13),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    filled: true,
                    fillColor: _selectedProvince == null ? Colors.grey[200] : const Color(0xFFF5F6F8), // Xám nếu chưa chọn tỉnh
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Hỗ trợ định vị vùng cứu hộ và kết nối nhanh trạm y tế gần nhất.', style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 16),
          // ----------------------------------------

          const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Emergency115!',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Xác nhận mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Emergency115!',
              prefixIcon: const Icon(Icons.history),
              suffixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF1565C0)),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required String hintText, required IconData prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black87),
            prefixIcon: Icon(prefixIcon),
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndSubmit() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: const Color(0xFF0D47A1),
                  onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    text: 'Tôi đồng ý với ',
                    style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
                    children: [
                      TextSpan(text: 'Điều khoản sử dụng', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' và '),
                      TextSpan(text: 'Chính sách bảo mật', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' của Hệ thống Cứu hộ 115.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DangNhap()));
            },

            

            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            label: const Text('ĐĂNG KÝ TÀI KHOẢN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),

            
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Đã có tài khoản? ', style: TextStyle(color: Colors.black54, fontSize: 14)),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DangNhap()));
              },
              child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}