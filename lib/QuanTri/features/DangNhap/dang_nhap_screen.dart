import 'dart:async';
import '../YeuCauHoTro/services/thong_bao_day_service.dart';
import '../YeuCauHoTro/chi_tiet_yeu_cau_screen.dart';

import '../PhanAnh/phan_anh_screen.dart';
import '../BaoCao/bao_cao_screen.dart';
import '../KyNang/ky_nang_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/dang_nhap_controller.dart';
import 'services/dang_nhap_service.dart';
import '../TaiKhoan/tai_khoan_screen.dart';
import '../YeuCauHoTro/yeu_cau_ho_tro_screen.dart';
import '../XacMinh/xac_minh_screen.dart';

import '../TaiKhoan/services/tai_khoan_service.dart';
import '../YeuCauHoTro/services/yeu_cau_ho_tro_service.dart';
import '../XacMinh/services/xac_minh_service.dart';

class DangNhapScreen extends StatefulWidget {
  final DangNhapController? controller;
  final NguonYeuCauHoTro? yeuCauRepository;
  final NguonTaiKhoan? taiKhoanRepository;
  final NguonXacMinh? xacMinhRepository;
  const DangNhapScreen({
    super.key,
    this.controller,
    this.yeuCauRepository,
    this.taiKhoanRepository,
    this.xacMinhRepository,
  });
  @override
  State<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends State<DangNhapScreen> {
  late final auth = widget.controller ?? DangNhapController(DangNhapService());
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool anMatKhau = true;

  @override
  void initState() {
    super.initState();
    auth.start();
  }

  @override
  void dispose() {
    auth.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> dangNhap() async {
    if (auth.busy || !(form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await auth.login(email.text, password.text);
    if (!mounted) return;
    if (auth.error == null) {
      TextInput.finishAutofillContext();
      password.clear();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) {
      if (auth.phase == TrangThaiDangNhap.loading) {
        return const Scaffold(
          backgroundColor: Color(0xFFF5F7FB),
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (auth.phase == TrangThaiDangNhap.allowed) {
        return _PhienThongBao(
          key: ValueKey(auth.session!.uid),
          auth: auth,
          buildNavigator: (navigator) => Navigator(
            key: navigator,
            initialRoute: '/yeu-cau',
            onGenerateInitialRoutes: (_, initialRoute) => [
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/yeu-cau'),
                builder: (_) => YeuCauHoTroScreen(
                  auth: auth,
                  repository: widget.yeuCauRepository,
                ),
              ),
            ],
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => switch (settings.name) {
                '/bao-cao' => const BaoCaoScreen(),
                '/danh-gia' => PhanAnhScreen(actor: auth.session!.uid),
                '/phan-anh' => PhanAnhScreen(actor: auth.session!.uid),
                '/ky-nang' => const KyNangScreen(),
                '/tai-khoan' => TaiKhoanScreen(
                  auth: auth,
                  repository: widget.taiKhoanRepository,
                ),
                '/xac-minh' => XacMinhScreen(
                  auth: auth,
                  repository: widget.xacMinhRepository,
                ),
                _ => YeuCauHoTroScreen(
                  auth: auth,
                  repository: widget.yeuCauRepository,
                ),
              },
            ),
          ),
        );
      }

      final denied = auth.phase == TrangThaiDangNhap.denied;
      final verificationError =
          auth.phase == TrangThaiDangNhap.verificationError;
      const red = Color(0xFFB71C1C);
      const blue = Color(0xFF1565C0);
      const ink = Color(0xFF193052);
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Cổng quản trị',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 22),
                  SizedBox(width: 4),
                  Text(
                    '115',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
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
                      child: AutofillGroup(
                        child: Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                      child: const Icon(
                                        Icons.emergency,
                                        color: red,
                                        size: 40,
                                      ),
                                    ),
                                    const CircleAvatar(
                                      radius: 11,
                                      backgroundColor: blue,
                                      child: Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'CỨU HỘ KHẨN CẤP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ĐĂNG NHẬP QUẢN TRỊ VIÊN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (verificationError) ...[
                                const Icon(
                                  Icons.wifi_off_outlined,
                                  color: red,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Chưa xác minh được quyền quản trị với máy chủ.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: ink, height: 1.5),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: auth.retryVerification,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'THỬ LẠI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: auth.logout,
                                  child: const Text(
                                    'Đăng nhập bằng tài khoản khác',
                                  ),
                                ),
                              ] else if (denied) ...[
                                const Text(
                                  'Tài khoản chưa được cấp quyền quản trị đang hoạt động.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: red, height: 1.5),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: auth.busy ? null : auth.logout,
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'ĐĂNG NHẬP BẰNG TÀI KHOẢN KHÁC',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Email quản trị',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: email,
                                  enabled: !auth.busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username],
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập email quản trị viên',
                                    hintStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.account_circle_outlined,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F6F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null ||
                                          !RegExp(
                                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                          ).hasMatch(value.trim())
                                      ? 'Nhập địa chỉ email hợp lệ.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Mật khẩu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: password,
                                  enabled: !auth.busy,
                                  obscureText: anMatKhau,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => dangNhap(),
                                  decoration: InputDecoration(
                                    hintText: '••••••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: anMatKhau
                                          ? 'Hiện mật khẩu'
                                          : 'Ẩn mật khẩu',
                                      onPressed: () => setState(
                                        () => anMatKhau = !anMatKhau,
                                      ),
                                      icon: Icon(
                                        anMatKhau
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F6F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Nhập mật khẩu.'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: auth.busy ? null : dangNhap,
                                    icon: auth.busy
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.login,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      auth.busy
                                          ? 'ĐANG ĐĂNG NHẬP…'
                                          : 'ĐĂNG NHẬP QUẢN TRỊ',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: red,
                                      disabledBackgroundColor: red.withValues(
                                        alpha: 0.55,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (auth.error != null) ...[
                                const SizedBox(height: 16),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      color: red,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PhienThongBao extends StatefulWidget {
  final DangNhapController auth;
  final Widget Function(GlobalKey<NavigatorState>) buildNavigator;
  const _PhienThongBao({
    super.key,
    required this.auth,
    required this.buildNavigator,
  });
  @override
  State<_PhienThongBao> createState() => _PhienThongBaoState();
}

class _PhienThongBaoState extends State<_PhienThongBao> {
  final navigator = GlobalKey<NavigatorState>();
  final push = ThongBaoDayService.instance;
  String? error;
  String? lastOpened;
  bool registering = false;
  @override
  void initState() {
    super.initState();
    push.opened.addListener(openPending);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(register());
      openPending();
    });
  }

  Future<void> register() async {
    if (registering) return;
    registering = true;
    try {
      final enabled = await push.register(widget.auth.session!.uid);
      if (mounted) {
        setState(
          () =>
              error = enabled ? null : 'Chưa bật quyền thông báo cho ứng dụng.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Chưa đăng ký được thông báo.');
    } finally {
      registering = false;
    }
  }

  void openDetail(String id) {
    if (!mounted || id.isEmpty || id.contains('/')) return;
    navigator.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => ChiTietYeuCauScreen(id: id)),
    );
  }

  void openPending() {
    if (!mounted) return;
    final data = push.opened.value;
    if (data == null) return;
    if (data['maAdmin'] != widget.auth.session?.uid) {
      push.clearPending();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || navigator.currentState == null) return;
      unawaited(_openPendingNotification(data));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _openPendingNotification(Map<String, String> data) async {
    final notificationId = data['maThongBao'] ?? '';
    if (notificationId.isNotEmpty && notificationId == lastOpened) {
      if (identical(push.opened.value, data)) push.clearPending();
      return;
    }
    lastOpened = notificationId.isEmpty ? null : notificationId;

    if (notificationId.isNotEmpty) {
      try {
        await push.markAsRead(
          notificationId: notificationId,
          adminUid: widget.auth.session!.uid,
        );
      } catch (error) {
        debugPrint(
          'Không đánh dấu được thông báo đã đọc: ${error.runtimeType}',
        );
      }
    }

    if (!mounted) return;
    openDetail(data['maYeuCau']!);
    if (identical(push.opened.value, data)) push.clearPending();
  }

  @override
  void dispose() {
    push.opened.removeListener(openPending);
    unawaited(push.unregister());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (error != null)
        MaterialBanner(
          content: Text(error!),
          actions: [
            TextButton(onPressed: register, child: const Text('Thử lại')),
          ],
        ),
      Expanded(
        child: NavigatorPopHandler<void>(
          onPopWithResult: (_) {
            final innerNavigator = navigator.currentState;
            if (innerNavigator != null) {
              unawaited(innerNavigator.maybePop<void>().then<void>((_) {}));
            }
          },
          child: widget.buildNavigator(navigator),
        ),
      ),
    ],
  );
}
