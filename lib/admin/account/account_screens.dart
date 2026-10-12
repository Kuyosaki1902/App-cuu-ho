import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'account.dart';
import 'account_repository.dart';

String friendlyError(Object e) {
  if (e is FirebaseFunctionsException)
    return e.message ?? 'Không thể thực hiện thao tác (${e.code}).';
  if (e is FirebaseException) {
    if (e.code == 'permission-denied')
      return 'Không có quyền truy cập. Kiểm tra tài khoản Admin và Security Rules.';
    if (e.code == 'unavailable')
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    return 'Lỗi Firebase: ${e.code}';
  }
  return e is StateError
      ? '${e.message}'
      : 'Không tải được dữ liệu. Hãy thử lại.';
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final repo = AccountRepository();
  final search = TextEditingController();
  List<Account> items = [];
  Map<String, String> roles = {};
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool loading = false, hasMore = true;
  String? error;
  String filter = 'all', role = '';
  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool reset = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (reset) {
        roles = await repo.roles();
      }
      final page = await repo.page(after: reset ? null : cursor);
      if (!mounted) return;
      setState(() {
        items = reset ? page.items : [...items, ...page.items];
        cursor = page.cursor;
        hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> open(Account account) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AccountDetailScreen(uid: account.uid, roles: roles, repo: repo),
      ),
    );
    if (mounted) load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final visible = items
        .where(
          (a) =>
              a.matches(search.text) &&
              (role.isEmpty || a.role == role) &&
              (filter == 'all' ||
                  (filter == 'support' && a.canSupport) ||
                  (filter == 'locked' && a.locked)),
        )
        .toList();
    final roleValues = {
      ...roles,
      for (final a in items) a.role: roles[a.role] ?? a.role,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loading ? null : () => load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tìm tên, số điện thoại, email hoặc UID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final f in {
                          'all': 'Tất cả',
                          'support': 'Có quyền hỗ trợ',
                          'locked': 'Bị khóa',
                        }.entries)
                          ChoiceChip(
                            label: Text(f.value),
                            selected: filter == f.key,
                            onSelected: (_) => setState(() => filter = f.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: roleValues.containsKey(role) ? role : '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tất cả vai trò'),
                        ),
                        ...roleValues.entries
                            .where((e) => e.key.isNotEmpty)
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            ),
                      ],
                      onChanged: (v) => setState(() => role = v ?? ''),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hiển thị ${visible.length} / ${items.length} tài khoản đã tải',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Text(
                      'Tìm kiếm và lọc trong dữ liệu đã tải. Bấm “Tải thêm” để mở rộng kết quả.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (loading) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => load(reset: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (visible.isEmpty && !loading)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text(
                              'Không có tài khoản phù hợp trong dữ liệu đã tải.',
                            ),
                          ),
                        ),
                      for (final a in visible)
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              child: Text(
                                a.name.isEmpty
                                    ? '?'
                                    : a.name.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(
                              a.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${a.phone} • ${roles[a.role] ?? a.role}'),
                                Text(
                                  'UID: ${a.uid}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${a.statusLabel}${a.suspended ? ' • Tạm ngừng hỗ trợ' : ''}${a.canSupport ? ' • Có quyền hỗ trợ' : ''}',
                                  style: TextStyle(
                                    color: a.locked ? Colors.red : Colors.teal,
                                  ),
                                ),
                                if (a.syncBlocked)
                                  const Text(
                                    'Đồng bộ Auth chưa hoàn tất',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => open(a),
                          ),
                        ),
                      if (hasMore)
                        OutlinedButton.icon(
                          onPressed: loading ? null : () => load(),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Tải thêm'),
                        ),
                      if (error != null)
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => load(reset: items.isEmpty),
                          child: const Text('Thử lại'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDetailScreen extends StatefulWidget {
  final String uid;
  final Map<String, String> roles;
  final AccountRepository repo;
  const AccountDetailScreen({
    super.key,
    required this.uid,
    required this.roles,
    required this.repo,
  });
  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  Account? account;
  String? error;
  bool loading = true, busy = false;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final a = await widget.repo.get(widget.uid);
      if (mounted) setState(() => account = a);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> perform(String action, String title) async {
    final a = account;
    if (a == null || busy || loading) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => ReasonDialog(title: title, name: a.name),
    );
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repo.action(a, action, reason);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tài khoản.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            duration: const Duration(seconds: 6),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await refresh();
      }
    }
  }

  Widget section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SelectableText(value.isEmpty ? 'Chưa có' : value),
      ],
    ),
  );
  Widget profile(String title, Map<String, dynamic> p) => section(title, [
    field('Trạng thái hồ sơ', textOf(p, 'maTrangThaiHoSo')),
    if (p.containsKey('donViCongTac'))
      field('Đơn vị công tác', textOf(p, 'donViCongTac')),
    if (p.containsKey('chucDanh')) field('Chức danh', textOf(p, 'chucDanh')),
    if (p.containsKey('doiNhom')) field('Đội nhóm', textOf(p, 'doiNhom')),
    field(
      'Điểm đánh giá',
      '${p['diemDanhGia'] ?? 0} (${p['tongLuotDanhGia'] ?? 0} lượt)',
    ),
  ]);
  @override
  Widget build(BuildContext context) {
    final a = account;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài khoản'),
        actions: [
          IconButton(
            onPressed: busy || loading ? null : refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      TextButton(
                        onPressed: refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : a == null
              ? const Text('Không có dữ liệu')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    section(a.name, [
                      field('Mã người dùng / Firebase Auth UID', a.uid),
                      field('Vai trò', widget.roles[a.role] ?? a.role),
                      field('Số điện thoại', a.phone),
                      field('Email', textOf(a.data, 'email')),
                      field('Ngày sinh', dateText(a.data['ngaySinh'])),
                      field('Địa chỉ', textOf(a.data, 'diaChi')),
                      field('Quê quán', textOf(a.data, 'queQuan')),
                      field('Ngày tạo', dateText(a.data['ngayTao'])),
                      field('Trạng thái tài khoản', a.statusLabel),
                      field(
                        'Quyền hỗ trợ',
                        a.canSupport
                            ? 'Được nhận ca mới'
                            : 'Không được nhận ca mới',
                      ),
                    ]),
                    if (a.professional != null)
                      profile('Hồ sơ cứu hộ có CCHN', a.professional!),
                    if (a.volunteer != null)
                      profile('Hồ sơ cứu hộ không CCHN', a.volunteer!),
                    if (a.professional == null && a.volunteer == null)
                      section('Hồ sơ cứu hộ', [
                        const Text('Tài khoản chưa có hồ sơ cứu hộ.'),
                      ]),
                    section('Thao tác quản trị', [
                      const Text(
                        'Mỗi thao tác cần lý do và được ghi nhật ký. Backend sẽ chặn nếu tài khoản đang có ca chưa bàn giao.',
                      ),
                      const SizedBox(height: 12),
                      if (a.sync['status'] == 'running')
                        const Text(
                          'Đang đồng bộ Firebase Auth. Tải lại sau. Nếu trạng thái bị treo, liên hệ quản trị kỹ thuật.',
                        ),
                      if (a.sync['status'] == 'failed')
                        FilledButton.icon(
                          onPressed: busy
                              ? null
                              : () => perform(
                                  a.sync['action'] as String,
                                  'Thử lại đồng bộ Auth',
                                ),
                          icon: const Icon(Icons.sync),
                          label: const Text('Thử lại đồng bộ Auth'),
                        ),
                      if (!a.syncBlocked)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (a.approved && !a.locked)
                              OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => perform(
                                        a.suspended ? 'khoi_phuc' : 'tam_ngung',
                                        a.suspended
                                            ? 'Khôi phục quyền hỗ trợ'
                                            : 'Tạm ngừng quyền hỗ trợ',
                                      ),
                                icon: const Icon(
                                  Icons.health_and_safety_outlined,
                                ),
                                label: Text(
                                  a.suspended
                                      ? 'Khôi phục hỗ trợ'
                                      : 'Tạm ngừng hỗ trợ',
                                ),
                              ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: a.locked
                                    ? Colors.teal
                                    : Colors.red.shade700,
                              ),
                              onPressed: busy || a.status == 'chua_di_tru'
                                  ? null
                                  : () => perform(
                                      a.locked ? 'mo_khoa' : 'khoa',
                                      a.locked
                                          ? 'Mở khóa tài khoản'
                                          : 'Khóa tài khoản',
                                    ),
                              icon: Icon(
                                a.locked ? Icons.lock_open : Icons.lock_outline,
                              ),
                              label: Text(
                                a.locked
                                    ? 'Mở khóa tài khoản'
                                    : 'Khóa tài khoản',
                              ),
                            ),
                          ],
                        ),
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ]),
                    section('Nhật ký quản trị gần nhất', [
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: widget.repo.logs(a.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError)
                            return Text(friendlyError(snapshot.error!));
                          if (!snapshot.hasData)
                            return const LinearProgressIndicator();
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty)
                            return const Text('Chưa có thao tác quản trị.');
                          return Column(
                            children: docs.map((d) {
                              final log = d.data();
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${log['hanhDong']} • ${log['trangThai']}',
                                ),
                                subtitle: Text(
                                  '${log['lyDo']}\nAdmin: ${log['maAdmin']}\n${dateText(log['thoiGian'])}',
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ]),
                  ],
                ),
        ),
      ),
    );
  }
}

class ReasonDialog extends StatefulWidget {
  final String title, name;
  const ReasonDialog({super.key, required this.title, required this.name});
  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final key = GlobalKey<FormState>();
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tài khoản: ${widget.name}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Lý do (bắt buộc)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v?.trim().length ?? 0) < 5 ? 'Nhập ít nhất 5 ký tự.' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (key.currentState!.validate())
            Navigator.pop(context, controller.text.trim());
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
