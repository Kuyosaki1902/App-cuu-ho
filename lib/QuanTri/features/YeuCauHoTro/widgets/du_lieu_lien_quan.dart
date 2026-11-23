import '../../../core/luong_truc_tiep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/xu_ly_loi.dart';
import '../../TaiKhoan/chi_tiet_tai_khoan_screen.dart';
import '../../TaiKhoan/services/tai_khoan_service.dart';
import '../../TaiKhoan/models/tai_khoan_model.dart';
import '../../../models/ban_ghi.dart';
import '../models/chi_tiet_yeu_cau_model.dart';
import '../services/chi_tiet_yeu_cau_service.dart';
import 'media_yeu_cau.dart';

class DuLieuLienQuan extends StatefulWidget {
  final NguonChiTietYeuCau repository;
  final String id, kind, title;
  final bool initiallyExpanded;
  const DuLieuLienQuan({
    super.key,
    required this.repository,
    required this.id,
    required this.kind,
    required this.title,
    this.initiallyExpanded = false,
  });
  @override
  State<DuLieuLienQuan> createState() => _DuLieuLienQuanState();
}

class _DuLieuLienQuanState extends State<DuLieuLienQuan> {
  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) fetch();
  }

  final luong = PhienTheoDoi();
  int gioiHan = 10;
  @override
  void dispose() {
    luong.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DuLieuLienQuan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.kind != widget.kind ||
        oldWidget.repository != widget.repository) {
      luong.cancel('rows');
      rows = [];
      gioiHan = 10;
      cursor = null;
      loading = false;
      more = true;
      loaded = false;
      error = null;
      if (widget.initiallyExpanded) fetch();
    }
  }

  List<BanGhi> rows = [];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool loading = false, more = true, loaded = false;
  String? error;
  Future<void> fetch() async {
    final source = widget.repository;
    if (source is ChiTietYeuCauTrucTiep) {
      if (loading || (!more && error == null && loaded)) return;
      if (loaded && error == null) gioiHan += 10;
      setState(() {
        loading = true;
        error = null;
      });
      luong.listen(
        'rows',
        (source as ChiTietYeuCauTrucTiep).watchRecords(
          widget.id,
          widget.kind,
          gioiHan,
        ),
        (page) {
          if (!mounted) return;
          setState(() {
            rows = page.items;
            more = page.hasMore;
            loaded = true;
            loading = false;
            error = null;
          });
        },
        (e) {
          if (mounted) {
            setState(() {
              loading = false;
              error = friendlyError(e);
            });
          }
        },
      );
      return;
    }

    if (loading || !more) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final page = await widget.repository.records(
        widget.id,
        widget.kind,
        after: cursor,
      );
      if (!mounted) return;
      setState(() {
        rows = [...rows, ...page.items];
        cursor = page.cursor;
        more = page.hasMore;
        loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  IconData get _sectionIcon => switch (widget.kind) {
    'descriptions' => Icons.notes_rounded,
    'requestImages' => Icons.perm_media_outlined,
    'images' => Icons.perm_media_outlined,
    'invitations' => Icons.groups_2_outlined,
    'reviews' => Icons.star_outline_rounded,
    'logs' => Icons.history_rounded,
    _ => Icons.folder_open_outlined,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE3EAF2)),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: widget.initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(_sectionIcon, color: const Color(0xFF1769AA), size: 19),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Color(0xFF172B4D),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: loaded && rows.isNotEmpty
          ? Text(
              '${rows.length} mục đã tải',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            )
          : null,
      onExpansionChanged: (expanded) {
        if (expanded && !loaded) fetch();
      },
      children: [
        for (final r in rows)
          Padding(
            key: ValueKey('${widget.kind}-${r.id}'),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: row(r),
          ),
        if (loaded && rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chưa có dữ liệu.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ),
        if (!loading && (more || error != null))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: fetch,
              child: Text(error == null ? 'Tải thêm' : 'Thử lại'),
            ),
          ),
      ],
    ),
  );
  Widget row(BanGhi r) {
    switch (widget.kind) {
      case 'descriptions':
        final rawNote = r.data['ghiChuText'];
        final content = incidentDescription(rawNote);
        final symptoms = rawNote is Map ? rawNote['trieuChung'] : null;
        final audioUrl = r.data['ghiAmUrl'];
        final videoOrMediaUrl = r.data['videoUrl'];
        final extraAttachments = <Widget>[];
        for (final key in [
          'fileURL',
          'fileUrl',
          'tepTinUrl',
          'taiLieuUrl',
          'duongDanTep',
          'attachmentUrl',
          'urlFile',
        ]) {
          final value = r.data[key];
          if (value is String && value.trim().isNotEmpty) {
            extraAttachments.add(
              MediaUrlPreview(
                key: ValueKey('${r.id}-$key'),
                url: value.trim(),
                title: r.data['tenTep']?.toString() ?? 'Tệp đính kèm',
                contentType: (r.data['contentType'] ?? r.data['mimeType'])
                    ?.toString(),
              ),
            );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (symptoms is List &&
                symptoms.whereType<String>().isNotEmpty) ...[
              const Text(
                'Triệu chứng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: symptoms
                    .whereType<String>()
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A4D0B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              'Mô tả tình trạng',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              content.isEmpty ? 'Chưa có mô tả bằng chữ.' : content,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              dateText(r.data['thoiGianTao']),
              style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
            if (audioUrl is String && audioUrl.trim().isNotEmpty)
              AudioAttachmentPlayer(
                url: audioUrl.trim(),
                title: 'Ghi âm tình trạng',
              ),
            if (videoOrMediaUrl is String && videoOrMediaUrl.trim().isNotEmpty)
              MediaUrlPreview(
                url: videoOrMediaUrl.trim(),
                title: 'Video hiện trường',
                contentType: (r.data['contentType'] ?? r.data['mimeType'])
                    ?.toString(),
              ),
            ...extraAttachments,
          ],
        );
      case 'requestImages':
      case 'images':
        return MediaAttachmentTile(record: r);
      case 'reviews':
        return DanhGiaYeuCauTile(review: r, repository: widget.repository);
      case 'invitations':
        return _InvitationHistoryRow(record: r, repository: widget.repository);
      case 'logs':
        final replacement = r.data['ketQua'] == 'can_thay_nguoi';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE7EDF4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: replacement
                      ? const Color(0xFFFFF0E8)
                      : const Color(0xFFEAF6EF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  replacement
                      ? Icons.swap_horiz_rounded
                      : Icons.fact_check_outlined,
                  color: replacement
                      ? const Color(0xFFB45309)
                      : const Color(0xFF18734D),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replacement
                          ? 'Yêu cầu thay người hỗ trợ'
                          : 'Xác nhận tiếp tục hỗ trợ',
                      style: const TextStyle(
                        color: Color(0xFF172B4D),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateText(r.data['thoiGian']),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    if (r.text('ghiChu', '').isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        r.text('ghiChu', ''),
                        style: const TextStyle(height: 1.4, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      'Admin: ${r.text('maAdmin')} · Người hỗ trợ: ${r.text('maNguoiCuuHo')}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InvitationHistoryRow extends StatefulWidget {
  final BanGhi record;
  final NguonChiTietYeuCau repository;

  const _InvitationHistoryRow({required this.record, required this.repository});

  @override
  State<_InvitationHistoryRow> createState() => _InvitationHistoryRowState();
}

class _InvitationHistoryRowState extends State<_InvitationHistoryRow> {
  late final String uid = widget.record.text('maNguoiCuuHo', '');
  late final Stream<BanGhi?> person = uid.isEmpty
      ? Stream<BanGhi?>.value(null)
      : widget.repository.watchPerson(uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<BanGhi?>(
    stream: person,
    builder: (context, snapshot) {
      final name = snapshot.data?.text('hoTen', '') ?? '';
      return ThePhanCong(
        uid: uid,
        name: name,
        status: widget.record.data['maTrangThaiTiepNhan'],
        details: Text(
          'Gửi ${dateText(widget.record.data['thoiGianGui'])}',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      );
    },
  );
}

int thuTuPhanCong(Object? raw) => switch (assignmentStatus(raw)) {
  'duoc_chon' => 0,
  'da_gui_thong_bao' => 1,
  'hoan_thanh' => 2,
  _ => 3,
};

class ThePhanCong extends StatelessWidget {
  final String uid, name;
  final Object? status;
  final Widget? details;

  const ThePhanCong({
    super.key,
    required this.uid,
    required this.name,
    required this.status,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (assignmentStatus(status)) {
      'duoc_chon' => (
        const Color(0xFF1756A3),
        Icons.health_and_safety_outlined,
      ),
      'da_gui_thong_bao' => (const Color(0xFF855500), Icons.schedule),
      'hoan_thanh' => (const Color(0xFF176745), Icons.task_alt),
      'tu_choi' => (const Color(0xFFA13535), Icons.block),
      _ => (const Color(0xFF586578), Icons.person_outline),
    };
    final valid = uid.trim().isNotEmpty && !uid.contains('/');
    final title = name.trim().isNotEmpty
        ? name
        : valid
        ? uid
        : 'Chưa có người nhận';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: .05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: .19)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: !valid
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChiTietTaiKhoanScreen(
                      uid: uid,
                      roles: const {},
                      repository: TaiKhoanService(),
                    ),
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: .10),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            assignmentLabel(status),
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    ),
                    if (valid)
                      const Icon(
                        Icons.chevron_right,
                        semanticLabel: 'Xem hồ sơ',
                      ),
                  ],
                ),
                if (details != null) ...[const SizedBox(height: 8), details!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
