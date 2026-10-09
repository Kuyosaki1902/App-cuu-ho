import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/DangKy.dart';

class DangNhap extends StatefulWidget {
  const DangNhap({super.key});

  @override
  State<DangNhap> createState() => _DangNhapState();
}

class _DangNhapState extends State<DangNhap> {
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Màu nền tổng thể
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Đăng nhập',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C), // Đỏ đậm
              borderRadius: BorderRadius.circular(20),
            ),
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
      body: SingleChildScrollView(
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
    );
  }


  //Label: HỆ THỐNG ĐIỀU PHỐI CẤP CỨU QUỐC GIA 115
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
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Cổng kết nối nội bộ số hoá điều phối xe cứu thương, y bác sĩ & đội phản ứng nhanh.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(

            

            color: Colors.black.withValues(alpha: 0.05),

            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Cấp cứu
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency, color: Color(0xFFB71C1C), size: 40),
                ),
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'CỨU HỘ KHẨN CẤP',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nền tảng kết nối ứng cứu và hỗ trợ y tế khẩn cấp',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Input: Số điện thoại / Email
          const Text('Số điện thoại hoặc Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Nhập số điện thoại hoặc email của bạn',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.account_circle_outlined),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Input: Mật khẩu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              InkWell(
                onTap: () {},
                child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '••••••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),

          // Ghi nhớ đăng nhập
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: const Color(0xFF1565C0),
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),

          // Nút Đăng nhập
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C), // Đỏ
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Color(0xFF455A64)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chưa có tài khoản?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Đăng ký tài khoản mới dễ dàng', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DangKy()));

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0), // Xanh dương
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Đăng ký ngay', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF8D6E63), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hệ thống được bảo vệ bởi tiêu chuẩn an toàn an ninh mạng quốc gia. Mọi hành vi truy cập trái phép hoặc phát tín hiệu cấp cứu giả mạo sẽ bị xử lý nghiêm theo quy định pháp luật.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}