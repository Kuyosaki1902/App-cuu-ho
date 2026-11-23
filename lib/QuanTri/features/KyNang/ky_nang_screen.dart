import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;

import '../../models/ban_ghi.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import 'ky_nang_service.dart';

class KyNangScreen extends StatelessWidget {
  const KyNangScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quản lý kỹ năng',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category_outlined), text: 'Danh mục'),
              Tab(
                icon: Icon(Icons.volunteer_activism_outlined),
                text: 'Người cứu hộ',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DanhMucKyNangTab(), _NguoiCuuHoKyNangTab()],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E7F0))),
            ),
            child: Row(
              children: [
                mucDieuHuong(
                  Icons.emergency_outlined,
                  'Yêu cầu',
                  () => Navigator.pushReplacementNamed(context, '/yeu-cau'),
                ),
                mucDieuHuong(
                  Icons.people_outline,
                  'Tài khoản',
                  () => Navigator.pushReplacementNamed(context, '/tai-khoan'),
                ),
                mucDieuHuong(
                  Icons.verified_user_outlined,
                  'Xác minh',
                  () => Navigator.pushReplacementNamed(context, '/xac-minh'),
                ),
                mucDieuHuong(
                  Icons.query_stats_rounded,
                  'Báo cáo',
                  () => Navigator.pushReplacementNamed(context, '/bao-cao'),
                ),
                mucDieuHuong(
                  Icons.medical_services_outlined,
                  'Kỹ năng',
                  null,
                  selected: true,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DanhMucKyNangTab extends StatefulWidget {
  const _DanhMucKyNangTab();

  @override
  State<_DanhMucKyNangTab> createState() => _DanhMucKyNangTabState();
}

class _DanhMucKyNangTabState extends State<_DanhMucKyNangTab> {
  final service = KyNangAdminService();
  final search = TextEditingController();
  late final Stream<List<KyNangDanhMuc>> stream = service.watchDanhMuc();
  String keyword = '';
  String? feedback;
  bool feedbackIsError = false;
  bool saving = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _setFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      feedback = message;
      feedbackIsError = isError;
    });
  }

  String _errorText(Object error) => error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '');

  Future<void> edit({KyNangDanhMuc? skill}) async {
    final result = await showModalBottomSheet<_KyNangSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x990B1B31),
      builder: (_) => _KyNangEditorSheet(skill: skill),
    );
    if (result == null || !mounted) return;

    setState(() => saving = true);
    try {
      if (result.action == _KyNangSheetAction.delete) {
        await service.xoaKyNang(result.id);
        _setFeedback('Đã xóa kỹ năng ${result.id}.');
      } else if (skill == null) {
        await service.taoKyNang(
          id: result.id,
          ten: result.ten,
          moTa: result.moTa,
        );
        _setFeedback('Đã thêm kỹ năng ${result.id}.');
      } else {
        await service.capNhatKyNang(
          id: skill.id,
          ten: result.ten,
          moTa: result.moTa,
        );
        _setFeedback('Đã cập nhật kỹ năng ${skill.id}.');
      }
    } catch (error) {
      _setFeedback(_errorText(error), isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<KyNangDanhMuc>>(
    stream: stream,
    builder: (context, snapshot) {
      final all = snapshot.data ?? const <KyNangDanhMuc>[];
      final filtered = all.where((skill) {
        final q = keyword.trim().toLowerCase();
        return q.isEmpty ||
            '${skill.ten} ${skill.id} ${skill.moTa}'.toLowerCase().contains(q);
      }).toList();

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await service.db
                      .collection('KyNangCuuHo')
                      .get(const GetOptions(source: Source.server));
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
                  children: [
                    if (feedback != null) ...[
                      _InlineFeedback(
                        message: feedback!,
                        isError: feedbackIsError,
                        onClose: () => setState(() => feedback = null),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: _StatTile(
                        label: 'Tổng kỹ năng',
                        value: snapshot.hasData ? '${all.length}' : '—',
                        icon: Icons.grid_view_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: search,
                      onChanged: (value) => setState(() => keyword = value),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, mã hoặc mô tả kỹ năng',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: keyword.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                onPressed: () {
                                  search.clear();
                                  setState(() => keyword = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách kỹ năng',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF193052),
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length} mục',
                          style: const TextStyle(
                            color: Color(0xFF71829B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData)
                      const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      const _EmptyPanel(
                        icon: Icons.cloud_off_outlined,
                        title: 'Không tải được danh mục',
                      )
                    else if (filtered.isEmpty)
                      _EmptyPanel(
                        icon: Icons.search_off_rounded,
                        title: keyword.isEmpty
                            ? 'Chưa có kỹ năng'
                            : 'Không tìm thấy kết quả',
                        message: keyword.isEmpty
                            ? 'Danh mục hiện chưa có kỹ năng.'
                            : 'Thử một từ khóa khác.',
                      )
                    else
                      for (final skill in filtered)
                        _SkillCatalogCard(
                          skill: skill,
                          onTap: () => edit(skill: skill),
                        ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: FloatingActionButton.extended(
                  onPressed: saving ? null : () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm kỹ năng'),
                ),
              ),
              if (saving)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _NguoiCuuHoKyNangTab extends StatefulWidget {
  const _NguoiCuuHoKyNangTab();

  @override
  State<_NguoiCuuHoKyNangTab> createState() => _NguoiCuuHoKyNangTabState();
}

class _NguoiCuuHoKyNangTabState extends State<_NguoiCuuHoKyNangTab> {
  final service = KyNangAdminService();
  final search = TextEditingController();
  late final Stream<List<KyNangDanhMuc>> catalogStream = service.watchDanhMuc();
  late final Stream<List<BanGhi>> rescuersStream = service
      .watchNguoiCuuHoKhongCCHN();
  String keyword = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<KyNangDanhMuc>>(
    stream: catalogStream,
    builder: (context, catalogSnapshot) {
      final catalog = catalogSnapshot.data ?? const <KyNangDanhMuc>[];
      final names = {for (final item in catalog) item.id: item.ten};
      return StreamBuilder<List<BanGhi>>(
        stream: rescuersStream,
        builder: (context, usersSnapshot) {
          final all = usersSnapshot.data ?? const <BanGhi>[];
          final filtered = all.where((person) {
            final q = keyword.trim().toLowerCase();
            return q.isEmpty ||
                '${person.text('hoTen', '')} ${person.id}'
                    .toLowerCase()
                    .contains(q);
          }).toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  TextField(
                    controller: search,
                    onChanged: (value) => setState(() => keyword = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm người cứu hộ theo tên hoặc UID',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: keyword.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                search.clear();
                                setState(() => keyword = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (catalogSnapshot.hasError || usersSnapshot.hasError)
                    const _EmptyPanel(
                      icon: Icons.cloud_off_outlined,
                      title: 'Không tải được dữ liệu',
                    )
                  else if ((catalogSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !catalogSnapshot.hasData) ||
                      (usersSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !usersSnapshot.hasData))
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtered.isEmpty)
                    _EmptyPanel(
                      icon: Icons.person_search_outlined,
                      title: keyword.isEmpty
                          ? 'Chưa có người cứu hộ'
                          : 'Không tìm thấy người cứu hộ',
                      message: keyword.isEmpty
                          ? 'Chưa có dữ liệu để hiển thị.'
                          : 'Thử một từ khóa khác.',
                    )
                  else
                    for (final person in filtered)
                      _RescuerSkillCard(
                        key: ValueKey(person.id),
                        person: person,
                        service: service,
                        catalog: names,
                      ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _RescuerSkillCard extends StatefulWidget {
  final BanGhi person;
  final KyNangAdminService service;
  final Map<String, String> catalog;
  const _RescuerSkillCard({
    super.key,
    required this.person,
    required this.service,
    required this.catalog,
  });

  @override
  State<_RescuerSkillCard> createState() => _RescuerSkillCardState();
}

class _RescuerSkillCardState extends State<_RescuerSkillCard> {
  late Future<List<KyNangDaKhaiBao>> future;

  @override
  void initState() {
    super.initState();
    future = widget.service.kyNangCuaNguoiDung(
      widget.person.id,
      widget.catalog,
    );
  }

  @override
  void didUpdateWidget(covariant _RescuerSkillCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id ||
        !mapEquals(oldWidget.catalog, widget.catalog)) {
      future = widget.service.kyNangCuaNguoiDung(
        widget.person.id,
        widget.catalog,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.person.text('hoTen', 'Chưa có họ tên');
    final role = widget.person.text('maVaiTro', '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accountBlue.withValues(alpha: .10),
                  foregroundColor: accountBlue,
                  child: Text(
                    name.trim().isEmpty
                        ? '?'
                        : name.trim().substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.person.id,
                        style: const TextStyle(
                          color: Color(0xFF71829B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                accountBadge(
                  role == 'vaitro_cuuhococc' ? 'Có CCHN' : 'Không CCHN',
                  role == 'vaitro_cuuhococc'
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF0F766E),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Kỹ năng',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 9),
            FutureBuilder<List<KyNangDaKhaiBao>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                if (snapshot.hasError) {
                  return const Text(
                    'Không thể tải kỹ năng.',
                    style: TextStyle(color: Color(0xFFB42318), fontSize: 12),
                  );
                }
                final skills = snapshot.data ?? const <KyNangDaKhaiBao>[];
                if (skills.isEmpty) {
                  return const Text(
                    'Chưa có kỹ năng được ghi nhận.',
                    style: TextStyle(color: Color(0xFF71829B), fontSize: 12),
                  );
                }
                return Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final skill in skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: skill.tuKhai
                              ? const Color(0xFFFFF7E8)
                              : const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: skill.tuKhai
                                ? const Color(0xFFF4D9A7)
                                : const Color(0xFFD5E5FF),
                          ),
                        ),
                        child: Text(
                          skill.ten,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: skill.tuKhai
                                ? const Color(0xFF9A6700)
                                : accountBlue,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE0E7F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accountBlue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF193052),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Color(0xFF71829B)),
        ),
      ],
    ),
  );
}

class _SkillCatalogCard extends StatelessWidget {
  final KyNangDanhMuc skill;
  final VoidCallback onTap;
  const _SkillCatalogCard({required this.skill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accountBlue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: accountBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.ten.isEmpty ? 'Chưa đặt tên' : skill.ten,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF193052),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.id,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF71829B),
                      ),
                    ),
                    if (skill.moTa.trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        skill.moTa,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8CA0B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  const _EmptyPanel({required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E7F0)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: const Color(0xFF8CA0B8)),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF193052),
          ),
        ),
        const SizedBox(height: 5),
        if (message != null)
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF71829B),
            ),
          ),
      ],
    ),
  );
}

class _InlineFeedback extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onClose;
  const _InlineFeedback({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : const Color(0xFF067647);
    final background = isError
        ? const Color(0xFFFFF1F0)
        : const Color(0xFFECFDF3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

enum _KyNangSheetAction { save, delete }

class _KyNangSheetResult {
  final _KyNangSheetAction action;
  final String id;
  final String ten;
  final String moTa;

  const _KyNangSheetResult({
    required this.action,
    required this.id,
    this.ten = '',
    this.moTa = '',
  });
}

class _KyNangEditorSheet extends StatefulWidget {
  final KyNangDanhMuc? skill;
  const _KyNangEditorSheet({this.skill});

  @override
  State<_KyNangEditorSheet> createState() => _KyNangEditorSheetState();
}

class _KyNangEditorSheetState extends State<_KyNangEditorSheet> {
  final form = GlobalKey<FormState>();
  late final TextEditingController ma = TextEditingController(
    text: widget.skill?.id ?? '',
  );
  late final TextEditingController ten = TextEditingController(
    text: widget.skill?.ten ?? '',
  );
  late final TextEditingController moTa = TextEditingController(
    text: widget.skill?.moTa ?? '',
  );
  bool confirmingDelete = false;

  @override
  void dispose() {
    ma.dispose();
    ten.dispose();
    moTa.dispose();
    super.dispose();
  }

  void _save() {
    if (!(form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _KyNangSheetResult(
        action: _KyNangSheetAction.save,
        id: ma.text.trim(),
        ten: ten.text.trim(),
        moTa: moTa.text.trim(),
      ),
    );
  }

  void _delete() {
    final skill = widget.skill;
    if (skill == null) return;
    Navigator.of(
      context,
    ).pop(_KyNangSheetResult(action: _KyNangSheetAction.delete, id: skill.id));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .92,
    minChildSize: .70,
    maxChildSize: .97,
    builder: (context, scrollController) => Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD7E0EA),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accountBlue.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: accountBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.skill == null
                            ? 'Thêm kỹ năng'
                            : 'Chỉnh sửa kỹ năng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF193052),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.skill == null
                            ? 'Tạo mã và thông tin kỹ năng'
                            : widget.skill!.id,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71829B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          Expanded(
            child: Form(
              key: form,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                children: [
                  TextFormField(
                    controller: ma,
                    readOnly: widget.skill != null,
                    autofocus: widget.skill == null,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: 'Mã kỹ năng',
                      hintText: 'kn_so_cuu_chay',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      filled: true,
                      fillColor: widget.skill == null
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) {
                      final code = (value ?? '').trim();
                      if (!RegExp(
                        r'^kn_[a-z0-9]+(?:_[a-z0-9]+)*$',
                      ).hasMatch(code)) {
                        return 'Dùng dạng kn_ten_ky_nang, viết thường và nối bằng dấu gạch dưới.';
                      }
                      if (code.length > 80) return 'Mã kỹ năng quá dài.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ten,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên kỹ năng',
                      hintText: 'Ví dụ: Sơ cứu chấn thương',
                      prefixIcon: const Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Tên kỹ năng cần ít nhất 2 ký tự.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: moTa,
                    maxLength: 500,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Mô tả ngắn về kỹ năng này',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  if (confirmingDelete) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F0),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB42318),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Xóa kỹ năng “${widget.skill!.ten}”? Thao tác này không thể hoàn tác.',
                              style: const TextStyle(
                                color: Color(0xFF912018),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
              ),
              child: confirmingDelete
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => confirmingDelete = false),
                            child: const Text('Giữ lại'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB42318),
                            ),
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xác nhận xóa'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (widget.skill != null)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => confirmingDelete = true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB42318),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa'),
                          ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Đóng'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Lưu'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
