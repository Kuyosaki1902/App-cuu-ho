import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuhokhancap/user/DangKy.dart';
import 'package:cuhokhancap/user/TrangChuNguoiDung.dart'; 
import 'package:cuhokhancap/firebase/firebase_service.dart'; 
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/QuenMatKhau.dart';

class DangNhap extends StatefulWidget {
  const DangNhap({super.key});

  @override
  State<DangNhap> createState() => _DangNhapState();
}

class _DangNhapState extends State<DangNhap> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _taiKhoanController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false; 

  Future<void> _handleLogin() async {
    String taiKhoan = _taiKhoanController.text.trim();
    String matKhau = _matKhauController.text.trim();

    if (taiKhoan.isEmpty || matKhau.isEmpty) {
      _showSnackBar('Vui lòng nhập tài khoản và mật khẩu!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    NguoiDungModel? user = await _firebaseService.dangNhap(taiKhoan, matKhau);

    if (mounted) setState(() => _isLoading = false);

    if (user != null && user.maNguoiDung != null) {
      // 1. KIỂM TRA ĐANG HOẠT ĐỘNG Ở MÁY KHÁC KHÔNG
      bool dangOnline = await _firebaseService.kiemTraDangOnlineRealtime(user.maNguoiDung!);
      if (dangOnline && mounted) {
        bool? xacNhan = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cảnh báo đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            content: const Text('Hiện tài khoản đang được sử dụng ở nơi khác, bạn có muốn đăng nhập?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Hủy
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Đồng ý đá máy kia
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                child: const Text('Đăng nhập', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (xacNhan != true) return; // Nếu chọn Hủy thì thoát, không đăng nhập nữa
      }

      _showSnackBar('Đăng nhập thành công!', Colors.green);
      
      // 2. SINH MÃ THIẾT BỊ MỚI DÀNH CHO PHIÊN ĐĂNG NHẬP NÀY
      String maThietBiMoi = DateTime.now().millisecondsSinceEpoch.toString();

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('maNguoiDung_daLuu', user.maNguoiDung!);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrangChuNguoiDung(
              maNguoiDung: user.maNguoiDung!,
              maThietBi: maThietBiMoi, // Truyền mã thiết bị sang Trang chủ
            ),
          ),
        );
      }
    } else {
      _showSnackBar('Sai tài khoản hoặc mật khẩu. Vui lòng thử lại!', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- PHẦN BUILD GIAO DIỆN GIỮ NGUYÊN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Đăng nhập', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 24),
                SizedBox(width: 4),
                Text('115', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSystemBanner(),
              const SizedBox(height: 16),
              _buildLoginCard(),
              const SizedBox(height: 16),
              _buildRegisterCard(),
              const SizedBox(height: 16),
              _buildSecurityNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(8)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: Color(0xFFB71C1C), size: 12),
              SizedBox(width: 8),
              Text('HỆ THỐNG ĐIỀU PHỐI CẤP CỨU QUỐC GIA 115', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          SizedBox(height: 4),
          Text('Cổng kết nối nội bộ số hoá điều phối xe cứu thương, y bác sĩ & đội phản ứng nhanh.', style: TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle), child: const Icon(Icons.emergency, color: Color(0xFFB71C1C), size: 40)),
                const CircleAvatar(radius: 10, backgroundColor: Color(0xFF1565C0), child: Icon(Icons.check, color: Colors.white, size: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('CỨU HỘ KHẨN CẤP', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Nền tảng kết nối ứng cứu và hỗ trợ y tế khẩn cấp', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          const Text('Số điện thoại hoặc Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _taiKhoanController,
            decoration: InputDecoration(hintText: 'Nhập số điện thoại hoặc email của bạn', hintStyle: const TextStyle(fontSize: 14, color: Colors.grey), prefixIcon: const Icon(Icons.account_circle_outlined), filled: true, fillColor: const Color(0xFFF5F6F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              InkWell(
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const QuenMatKhau())); },
                child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _matKhauController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '••••••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); }),
              filled: true, fillColor: const Color(0xFFF5F6F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                height: 24, width: 24,
                child: Checkbox(value: _rememberMe, activeColor: const Color(0xFF1565C0), onChanged: (value) { setState(() { _rememberMe = value ?? false; }); }),
              ),
              const SizedBox(width: 8),
              const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.login, color: Colors.white),
              label: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFE0E5EC), shape: BoxShape.circle), child: const Icon(Icons.person_add_alt_1, color: Color(0xFF455A64))),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chưa có tài khoản?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('Đăng ký tài khoản mới dễ dàng', style: TextStyle(fontSize: 12, color: Colors.black54))])),
          ElevatedButton(
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const DangKy())); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Đăng ký ngay', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF8D6E63), size: 20),
          SizedBox(width: 12),
          Expanded(child: Text('Hệ thống được bảo vệ bởi tiêu chuẩn an toàn an ninh mạng quốc gia. Mọi hành vi truy cập trái phép hoặc phát tín hiệu cấp cứu giả mạo sẽ bị xử lý nghiêm theo quy định pháp luật.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4))),
        ],
      ),
    );
  }
}