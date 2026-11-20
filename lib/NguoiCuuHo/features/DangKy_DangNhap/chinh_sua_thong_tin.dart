import 'dart:convert';
import 'dart:typed_data';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/controllers/anh_dai_dien_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Models/nguoidungmodel.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart'; // Đổi đường dẫn đúng dự án của bạn

class ChinhSuaThongTin extends StatefulWidget {
  final NguoiDungModel manguoiDung;
  const ChinhSuaThongTin({super.key, required this.manguoiDung});

  @override
  State<ChinhSuaThongTin> createState() => _ChinhSuaThongTinState();
}

class _ChinhSuaThongTinState extends State<ChinhSuaThongTin> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  // --- Ảnh đại diện ---
  final AnhDaiDienService _anhService = AnhDaiDienService();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _anhHienTai; // ảnh đang lưu trên server
  Uint8List? _anhMoi; // ảnh vừa chọn, chưa lưu
  bool _xoaAnh = false; // người dùng chọn xóa ảnh đại diện
  bool _dangTaiAnh = true;

  // Color palette
  final Color primaryColor = const Color(0xFF005342);
  final Color bgCardColor = Colors.white;
  final Color bgInputColor = const Color(0xFFF4F6FB);

  // Controllers
  late TextEditingController _hoTenController;
  late TextEditingController _sdtController;
  late TextEditingController _emailController;
  late TextEditingController _diaChiController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller với dữ liệu hiện tại từ Firestore
    _hoTenController = TextEditingController(text: widget.manguoiDung.hoTen);
    _sdtController = TextEditingController(
      text: widget.manguoiDung.soDienThoai,
    );
    _emailController = TextEditingController(text: widget.manguoiDung.email);
    _diaChiController = TextEditingController(text: widget.manguoiDung.diaChi);
    _taiAnhHienTai();
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _sdtController.dispose();
    _emailController.dispose();
    _diaChiController.dispose();
    super.dispose();
  }

  // --- HÀM KIỂM TRA XEM CÓ THAY ĐỔI DỮ LIỆU KHÔNG ---
  bool get _coThayDoiThongTin =>
      _hoTenController.text.trim() != widget.manguoiDung.hoTen ||
      _sdtController.text.trim() != widget.manguoiDung.soDienThoai ||
      _emailController.text.trim() != widget.manguoiDung.email ||
      _diaChiController.text.trim() != widget.manguoiDung.diaChi;

  bool get _coThayDoiAnh => _xoaAnh || _anhMoi != null;

  bool _kiemTraCoThayDoi() => _coThayDoiThongTin || _coThayDoiAnh;

  // ================= ẢNH ĐẠI DIỆN =================

  void _thongBao(String noiDung, {Color? mau}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(noiDung), backgroundColor: mau));
  }

  /// Giải mã chuỗi base64 (có hoặc không có tiền tố data:image/...;base64,).
  Uint8List? _giaiMaAnh(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final sach = s.contains(',') ? s.split(',').last : s;
      return base64Decode(sach.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _taiAnhHienTai() async {
    final id = widget.manguoiDung.maNguoiDung;
    if (id == null || id.isEmpty) {
      _dangTaiAnh = false; // đang ở initState, không cần setState
      return;
    }
    try {
      final s = await _anhService.layAnhDaiDien(id);
      if (!mounted) return;
      setState(() {
        _anhHienTai = _giaiMaAnh(s);
        _dangTaiAnh = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải ảnh đại diện: $e');
      if (mounted) setState(() => _dangTaiAnh = false);
    }
  }

  Future<void> _chonNguonAnh() async {
    final coAnh = !_xoaAnh && (_anhMoi != null || _anhHienTai != null);
    final chon = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: primaryColor),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: primaryColor),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (coAnh)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(ctx, 'xoa'),
              ),
            if (_coThayDoiAnh)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.black54),
                title: const Text('Bỏ thay đổi ảnh'),
                onTap: () => Navigator.pop(ctx, 'hoantac'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    switch (chon) {
      case 'camera':
        await _chonAnh(ImageSource.camera);
        break;
      case 'gallery':
        await _chonAnh(ImageSource.gallery);
        break;
      case 'xoa':
        setState(() {
          _anhMoi = null;
          _xoaAnh =
              _anhHienTai !=
              null; // chỉ cần đánh dấu xóa nếu đã có ảnh trên server
        });
        break;
      case 'hoantac':
        setState(() {
          _anhMoi = null;
          _xoaAnh = false;
        });
        break;
    }
  }

  Future<void> _chonAnh(ImageSource nguon) async {
    try {
      // Thu nhỏ ngay khi chọn để ảnh chỉ vài chục KB, an toàn với giới hạn 1 MiB của Firestore.
      final file = await _picker.pickImage(
        source: nguon,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return; // người dùng đóng, không chọn
      final bytes = await file.readAsBytes();
      if (bytes.length > 600 * 1024) {
        _thongBao('Ảnh quá lớn, vui lòng chọn ảnh khác.', mau: Colors.red);
        return;
      }
      if (!mounted) return;
      setState(() {
        _anhMoi = bytes;
        _xoaAnh = false;
      });
    } on PlatformException {
      _thongBao(
        nguon == ImageSource.camera
            ? 'Không mở được camera. Hãy cấp quyền camera trong Cài đặt.'
            : 'Không mở được thư viện ảnh. Hãy cấp quyền truy cập ảnh trong Cài đặt.',
        mau: Colors.red,
      );
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
      _thongBao('Không thể chọn ảnh, vui lòng thử lại.', mau: Colors.red);
    }
  }

  Widget _buildAvatar() {
    final Uint8List? anh = _xoaAnh ? null : (_anhMoi ?? _anhHienTai);
    final ten = widget.manguoiDung.hoTen.trim();
    final chuCai = ten.isNotEmpty ? ten[0].toUpperCase() : 'ND';

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _chonNguonAnh,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: primaryColor,
                backgroundImage: anh != null ? MemoryImage(anh) : null,
                onBackgroundImageError: anh != null ? (_, __) {} : null,
                child: anh != null
                    ? null
                    : (_dangTaiAnh
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              chuCai,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _chonNguonAnh,
          child: Text(
            anh == null ? 'Thêm ảnh đại diện' : 'Đổi ảnh đại diện',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        if (_coThayDoiAnh)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _xoaAnh
                  ? 'Ảnh đại diện sẽ bị xóa khi bạn bấm Lưu thay đổi'
                  : 'Ảnh mới sẽ được lưu khi bạn bấm Lưu thay đổi',
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  // --- HÀM 1: CẢNH BÁO KHI RỜI ĐI NẾU CÓ THAY ĐỔI ---
  Future<bool> _hienThiCanhBaoRoiDi() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Cảnh báo', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn đang thay đổi thông tin. Có chắc muốn rời không? Những thay đổi sẽ không được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Ở lại
            child: const Text(
              'Ở lại',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Đồng ý rời đi
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
            ),
            child: const Text(
              'Rời đi',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  // --- HÀM 2: HIỆN BẢNG XÁC NHẬN LƯU VÀ PUSH FIREBASE ---
  void _xuLyLuuThayDoi() {
    // 1. Kiểm tra rỗng (ngoại trừ email)
    if (_hoTenController.text.trim().isEmpty ||
        _sdtController.text.trim().isEmpty ||
        _diaChiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ Họ tên, SĐT và Địa chỉ!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Kiểm tra xem có gì thay đổi không
    if (!_kiemTraCoThayDoi()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có thông tin nào được thay đổi.')),
      );
      return;
    }

    // 3. Lấy ra danh sách các mục đã sửa để hiện lên Dialog
    List<Widget> danhSachThayDoi = [];
    if (_hoTenController.text.trim() != widget.manguoiDung.hoTen) {
      danhSachThayDoi.add(
        _buildChangeItem(
          'Họ tên:',
          widget.manguoiDung.hoTen,
          _hoTenController.text.trim(),
        ),
      );
    }
    if (_sdtController.text.trim() != widget.manguoiDung.soDienThoai) {
      danhSachThayDoi.add(
        _buildChangeItem(
          'SĐT:',
          widget.manguoiDung.soDienThoai,
          _sdtController.text.trim(),
        ),
      );
    }
    if (_emailController.text.trim() != widget.manguoiDung.email) {
      danhSachThayDoi.add(
        _buildChangeItem(
          'Email:',
          widget.manguoiDung.email.isEmpty
              ? '(Trống)'
              : widget.manguoiDung.email,
          _emailController.text.trim(),
        ),
      );
    }
    if (_diaChiController.text.trim() != widget.manguoiDung.diaChi) {
      danhSachThayDoi.add(
        _buildChangeItem(
          'Địa chỉ:',
          widget.manguoiDung.diaChi,
          _diaChiController.text.trim(),
        ),
      );
    }
    if (_coThayDoiAnh) {
      danhSachThayDoi.add(
        _buildChangeItem(
          'Ảnh đại diện:',
          _anhHienTai == null ? '(Chưa có)' : 'Ảnh hiện tại',
          _xoaAnh ? '(Xóa ảnh)' : 'Ảnh mới đã chọn',
        ),
      );
    }

    // 4. Hiện Dialog xác nhận
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận thay đổi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Các thông tin sau sẽ được cập nhật:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...danhSachThayDoi,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context), // Tắt bảng cảnh báo, cho nhập tiếp
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tắt Dialog
              _pushToFirebase(); // Tiến hành lưu
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text(
              'Đổi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String title, String oldVal, String newVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$title\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: oldVal,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
            const TextSpan(
              text: '  ➡️  ',
              style: TextStyle(color: Colors.blue),
            ),
            TextSpan(
              text: newVal,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM 3: ĐẨY DỮ LIỆU LÊN FIREBASE ---
  Future<void> _pushToFirebase() async {
    setState(() => _isLoading = true);

    final id = widget.manguoiDung.maNguoiDung!;
    var okThongTin = true;
    var okAnh = true;

    // 1) Thông tin cá nhân (chỉ gửi khi có chữ thay đổi)
    if (_coThayDoiThongTin) {
      final Map<String, dynamic> dataUpdate = {
        'hoTen': _hoTenController.text.trim(),
        'soDienThoai': _sdtController.text.trim(),
        'email': _emailController.text.trim(), // Email rỗng vẫn được lưu
        'diaChi': _diaChiController.text.trim(),
      };
      okThongTin = await _firebaseService.capNhatThongTinCaNhan(id, dataUpdate);
    }

    // 2) Ảnh đại diện
    if (_coThayDoiAnh) {
      try {
        if (_xoaAnh) {
          await _anhService.xoaAnhDaiDien(id);
          _anhHienTai = null;
        } else if (_anhMoi != null) {
          await _anhService.luuAnhDaiDien(id, _anhMoi!);
          _anhHienTai = _anhMoi;
        }
        _anhMoi = null;
        _xoaAnh = false;
      } catch (e) {
        debugPrint('Lỗi lưu ảnh đại diện: $e');
        okAnh = false;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (okThongTin && okAnh) {
      _thongBao('Cập nhật thông tin thành công!', mau: Colors.green);
      Navigator.pop(context); // Quay về màn hình trước đó
    } else if (okThongTin && !okAnh) {
      _thongBao(
        'Đã lưu thông tin nhưng chưa lưu được ảnh đại diện. Vui lòng thử lại.',
        mau: Colors.orange,
      );
    } else {
      _thongBao('Có lỗi xảy ra, vui lòng thử lại!', mau: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng PopScope để chặn sự kiện Back hệ thống
    return PopScope(
      canPop: !_kiemTraCoThayDoi(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Nếu có thay đổi, hỏi trước khi thoát
        bool confirm = await _hienThiCanhBaoRoiDi();
        if (confirm && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black87,
            ),
            onPressed: () async {
              if (_kiemTraCoThayDoi()) {
                bool confirm = await _hienThiCanhBaoRoiDi();
                if (confirm && context.mounted) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Sửa Thông Tin',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- 1. HEADER AVATAR ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: bgCardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: 12),
                          Text(
                            widget.manguoiDung.hoTen,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Đã xác minh',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- 2. THÔNG TIN CƠ BẢN ---
                    _buildSectionCard(
                      title: 'Thông Tin Cơ Bản',
                      children: [
                        _buildInputLabel('HỌ VÀ TÊN'),
                        _buildInputField(
                          controller: _hoTenController,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildInputLabel('SỐ ĐIỆN THOẠI LIÊN LẠC'),
                        _buildInputField(
                          controller: _sdtController,
                          icon: Icons.phone_android_outlined,
                          isPhone: true,
                        ),
                        const SizedBox(height: 14),
                        _buildInputLabel('EMAIL (TÙY CHỌN)'),
                        _buildInputField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 3. ĐỊA CHỈ TRÊN FIRESTORE ---
                    _buildSectionCard(
                      title: 'Địa Chỉ Thường Trú',
                      children: [
                        _buildInputLabel(
                          'ĐỊA CHỈ (Được cập nhật lên khu diaChi)',
                        ),
                        _buildInputField(
                          controller: _diaChiController,
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF006A55),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- 4. NÚT LƯU VÀ HỦY ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _xuLyLuuThayDoi, // Gọi hàm xử lý lưu
                        icon: const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Lưu Thay Đổi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          // Nút Hủy Bỏ: Kích hoạt logic y hệt nút Back
                          if (_kiemTraCoThayDoi()) {
                            bool confirm = await _hienThiCanhBaoRoiDi();
                            if (confirm && context.mounted)
                              Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Hủy Bỏ',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // Khung bọc tiêu đề
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF006A55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Label màu xám nhỏ phía trên ô nhập
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Ô nhập nền xám
  Widget _buildInputField({
    required TextEditingController controller,
    IconData? icon,
    Color? iconColor,
    int maxLines = 1,
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: bgInputColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
