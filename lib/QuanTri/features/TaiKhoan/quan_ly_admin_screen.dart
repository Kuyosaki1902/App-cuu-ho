import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class QuanLyAdminScreen extends StatefulWidget {
  const QuanLyAdminScreen({super.key});

  @override
  State<QuanLyAdminScreen> createState() => _QuanLyAdminScreenState();
}

class _QuanLyAdminScreenState extends State<QuanLyAdminScreen> {
  final rows = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final admins = FirebaseFirestore.instance.collection('Admin');
  bool loading = false, more = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool reset = false}) async {
    if (loading || (!more && !reset)) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      var query = admins.orderBy(FieldPath.documentId).limit(20);
      if (!reset && rows.isNotEmpty)
        query = query.startAfterDocument(rows.last);
      final page = await query.get();
      if (!mounted) return;
      setState(() {
        if (reset) rows.clear();
        rows.addAll(page.docs);
        more = page.docs.length == 20;
      });
    } catch (_) {
      if (mounted)
        setState(() => error = 'Không tải được danh sách quản trị viên.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AdminForm(doc: doc)),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          doc == null ? 'Đã tạo tài khoản admin.' : 'Đã lưu thông tin.',
        ),
      ),
    );
    await load(reset: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý tài khoản admin')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: loading ? null : () => edit(),
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Tạo admin'),
    ),
    body: RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          if (error == null && n.metrics.extentAfter < 200) load();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: rows.length + 1,
          itemBuilder: (_, i) {
            if (i == rows.length) {
              if (loading)
                return const Center(child: CircularProgressIndicator());
              if (error != null)
                return TextButton(
                  onPressed: load,
                  child: Text('$error Thử lại'),
                );
              if (rows.isEmpty)
                return const Center(child: Text('Chưa có quản trị viên.'));
              return more
                  ? TextButton(onPressed: load, child: const Text('Tải thêm'))
                  : const SizedBox.shrink();
            }
            final doc = rows[i], data = doc.data();
            final name = '${data['hoTen'] ?? ''}'.trim();
            final email = '${data['email'] ?? ''}';
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.admin_panel_settings_outlined),
                ),
                title: Text(name.isEmpty ? email : name),
                subtitle: Text(
                  [
                    if (name.isNotEmpty && email.isNotEmpty) email,
                    data['trangThai'] == 'hoat_dong'
                        ? 'Đang hoạt động'
                        : 'Không hoạt động',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: loading ? null : () => edit(doc),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _AdminForm extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;
  const _AdminForm({this.doc});

  @override
  State<_AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<_AdminForm> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};
  bool busy = false, hidden = true;
  String? error;
  bool get creating => widget.doc == null;

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    form.currentState!.save();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (creating) {
        await FirebaseFunctions.instanceFor(
          region: 'asia-southeast1',
        ).httpsCallable('taoTaiKhoanAdmin').call(values);
      } else {
        await widget.doc!.reference.update({
          for (final key in ['hoTen', 'soDienThoai']) key: values[key],
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e is FirebaseFunctionsException
              ? e.message
              : 'Không lưu được thay đổi. Hãy thử lại.';
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Widget field(String key, String label, int max, {TextInputType? keyboard}) {
    final password = key == 'password';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: '${widget.doc?.data()[key] ?? ''}',
        readOnly: !creating && key == 'email',
        enabled: !busy,
        keyboardType: keyboard,
        obscureText: password && hidden,
        autocorrect: !password,
        maxLength: max,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: const OutlineInputBorder(),
          suffixIcon: password
              ? IconButton(
                  tooltip: hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => hidden = !hidden),
                )
              : null,
        ),
        validator: (input) {
          final v = input?.trim() ?? '';
          if (key == 'hoTen' && v.isEmpty) return 'Nhập họ tên.';
          if (creating &&
              key == 'email' &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v))
            return 'Email chưa hợp lệ.';
          if (password && (input?.length ?? 0) < 8)
            return 'Mật khẩu cần ít nhất 8 ký tự.';
          if (key == 'soDienThoai' &&
              v.isNotEmpty &&
              !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(v))
            return 'Nhập 8–15 chữ số, có thể bắt đầu bằng +.';
          return null;
        },
        onSaved: (v) => values[key] = password ? v! : (v ?? '').trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(creating ? 'Tạo tài khoản admin' : 'Chỉnh sửa thông tin'),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          field('hoTen', 'Họ và tên', 80),
          field(
            'email',
            'Email đăng nhập',
            254,
            keyboard: TextInputType.emailAddress,
          ),
          if (creating) field('password', 'Mật khẩu đăng nhập', 128),
          field(
            'soDienThoai',
            'Số điện thoại',
            16,
            keyboard: TextInputType.phone,
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              busy
                  ? 'Đang lưu…'
                  : creating
                  ? 'Tạo tài khoản'
                  : 'Lưu thay đổi',
            ),
          ),
        ],
      ),
    ),
  );
}
