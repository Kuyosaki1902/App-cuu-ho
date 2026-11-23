import 'package:flutter/material.dart';

import 'controllers/dang_nhap_controller.dart';
import '../../widgets/giao_dien_tai_khoan.dart';

class ThongTinQuanTriScreen extends StatefulWidget {
  final DangNhapController auth;
  const ThongTinQuanTriScreen({super.key, required this.auth});
  @override
  State<ThongTinQuanTriScreen> createState() => _ThongTinQuanTriScreenState();
}

class _ThongTinQuanTriScreenState extends State<ThongTinQuanTriScreen> {
  bool signingOut = false;
  Future<void> logout() async {
    if (signingOut) return;
    setState(() => signingOut = true);
    await widget.auth.logout();
    if (!mounted) return;
    setState(() => signingOut = false);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: ListenableBuilder(
        listenable: widget.auth,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE0EDFF),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 42,
                    color: accountBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.auth.session?.name.isNotEmpty == true
                      ? widget.auth.session!.name
                      : 'Quản trị viên',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Email'),
                        const SizedBox(height: 6),
                        SelectableText(widget.auth.session?.email ?? ''),
                        const Divider(height: 30),
                        for (final entry in {
                          'Điện thoại': widget.auth.session?.phone,
                        }.entries)
                          if (entry.value?.isNotEmpty == true) ...[
                            Text(entry.key),
                            const SizedBox(height: 6),
                            SelectableText(entry.value!),
                            const Divider(height: 30),
                          ],
                        const Text('Mã tài khoản'),
                        const SizedBox(height: 6),
                        SelectableText(widget.auth.session?.uid ?? ''),
                        const Divider(height: 30),
                        accountBadge('Đang hoạt động', const Color(0xFF15803D)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBD3030),
                  ),
                  onPressed: signingOut ? null : logout,
                  icon: const Icon(Icons.logout),
                  label: Text(signingOut ? 'Đang đăng xuất…' : 'Đăng xuất'),
                ),
                if (widget.auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
