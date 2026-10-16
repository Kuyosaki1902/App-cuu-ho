import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'DangNhap.dart'; // Đổi đường dẫn nếu cần

class QuenMatKhau extends StatefulWidget {
  const QuenMatKhau({super.key});

  @override
  State<QuenMatKhau> createState() => _QuenMatKhauState();
}

class _QuenMatKhauState extends State<QuenMatKhau> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Trạng thái màn hình: 0 = Tìm kiếm, 1 = Đổi mật khẩu
  int _step = 0; 
  bool _isLoading = false;

  // Controllers cho bước Tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  
  // Controllers cho bước Đổi mật khẩu
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Lưu thông tin user tìm được
  NguoiDungModel? _foundUser;

  // --- HÀM 1: TÌM KIẾM TÀI KHOẢN ---
  Future<void> _handleSearch() async {
    String searchValue = _searchController.text.trim();
    
    if (searchValue.isEmpty) {
      _showSnackBar('Vui lòng nhập Số điện thoại hoặc Email.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    NguoiDungModel? user = await _firebaseService.timTaiKhoanQuenMatKhau(searchValue);

    setState(() => _isLoading = false);

    if (user != null) {
      setState(() {
        _foundUser = user;
        _step = 1; // Chuyển sang bước đổi mật khẩu
      });
    } else {
      _showSnackBar('Không tìm thấy tài khoản nào khớp với thông tin này.', Colors.red);
    }
  }

  // --- HÀM 2: CẬP NHẬT MẬT KHẨU MỚI ---
  Future<void> _handleUpdatePassword() async {
    String pass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (pass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ mật khẩu mới.', Colors.red);
      return;
    }

    if (pass != confirmPass) {
      _showSnackBar('Mật khẩu xác nhận không khớp.', Colors.red);
      return;
    }

    if (_foundUser == null || _foundUser!.maNguoiDung == null) {
      _showSnackBar('Lỗi hệ thống. Không xác định được người dùng.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    bool isSuccess = await _firebaseService.capNhatMatKhau(_foundUser!.maNguoiDung!, pass);

    setState(() => _isLoading = false);

    if (isSuccess) {
      _showSnackBar('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.', Colors.green);
      // Xóa sạch lịch sử và quay về trang Đăng nhập
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DangNhap()),
          (route) => false,
        );
      }
    } else {
      _showSnackBar('Có lỗi xảy ra khi cập nhật mật khẩu.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Hàm ẩn 1 phần số điện thoại/email để bảo mật
  String _maskData(String data) {
    if (data.contains('@')) {
      List<String> parts = data.split('@');
      if (parts[0].length > 3) {
        return '${parts[0].substring(0, 3)}***@${parts[1]}';
      }
      return data;
    } else {
      if (data.length > 6) {
        return '${data.substring(0, 3)}****${data.substring(data.length - 3)}';
      }
      return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_step == 1) {
              // Nếu đang ở bước đổi pass, cho phép quay lại bước tìm kiếm
              setState(() {
                _step = 0;
                _newPasswordController.clear();
                _confirmPasswordController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSystemBanner(),
              const SizedBox(height: 16),
              
              // Chuyển đổi giữa 2 giao diện dựa vào trạng thái _step
              _step == 0 ? _buildSearchCard() : _buildResetPasswordCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI: BANNER (Giống màn hình Đăng nhập) ---
  Widget _buildSystemBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: Color(0xFFB71C1C), size: 12),
              SizedBox(width: 8),
              Text(
                'HỆ THỐNG ĐIỀU PHỐI CẤP CỨU QUỐC GIA 115',
                style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Nhập thông tin đã đăng ký để tìm lại tài khoản của bạn.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // --- UI: BƯỚC 1 - TÌM KIẾM ---
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.search_rounded, size: 50, color: Color(0xFF1565C0)),
          const SizedBox(height: 12),
          const Text('TÌM TÀI KHOẢN', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          const Text('Số điện thoại hoặc Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nhập số điện thoại hoặc email đã đăng ký',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.account_circle_outlined),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0), // Xanh
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('TÌM KIẾM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: BƯỚC 2 - ĐỔI MẬT KHẨU ---
  Widget _buildResetPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 50, color: Color(0xFF2E7D32)), // Xanh lá
          const SizedBox(height: 12),
          const Text('ĐẶT LẠI MẬT KHẨU', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Hiển thị thông tin user tìm được
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFA5D6A7))),
            child: Column(
              children: [
                const Text('Tài khoản khả dụng:', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                const SizedBox(height: 4),
                Text(_foundUser?.hoTen ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  _maskData(_foundUser!.soDienThoai.isNotEmpty ? _foundUser!.soDienThoai : _foundUser!.email),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Input Mật khẩu mới
          const Text('Mật khẩu mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Input Xác nhận mật khẩu mới
          const Text('Xác nhận mật khẩu mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu mới',
              prefixIcon: const Icon(Icons.history),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Xanh lá
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('CẬP NHẬT MẬT KHẨU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}