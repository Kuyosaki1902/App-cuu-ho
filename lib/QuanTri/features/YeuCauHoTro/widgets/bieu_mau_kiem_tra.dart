import 'package:flutter/material.dart';
import '../controllers/chi_tiet_yeu_cau_controller.dart';

class BieuMauKiemTra extends StatefulWidget {
  final ChiTietYeuCauController controller;
  final VoidCallback onSaved;
  final Set<String>? visibleIds;
  const BieuMauKiemTra({
    super.key,
    required this.controller,
    required this.onSaved,
    this.visibleIds,
  });
  @override
  State<BieuMauKiemTra> createState() => _BieuMauKiemTraState();
}

class _BieuMauKiemTraState extends State<BieuMauKiemTra> {
  String? selected, outcome;
  final note = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final c = widget.controller;
    final choices = c.assignments.where((a) => a.id == selected).toList();
    if (saving || choices.length != 1 || outcome == null) return;
    setState(() => saving = true);
    final error = await c.save(choices.single, outcome!, note.text);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (outcome == 'can_thay_nguoi'
                  ? 'Đã ghi nhận yêu cầu thay người. Phân công hiện tại được giữ cho đến khi điều phối.'
                  : 'Đã lưu kết quả kiểm tra.'),
        ),
      ),
    );
    if (error == null) {
      note.clear();
      setState(() {
        selected = null;
        outcome = null;
      });
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.controller.assignments
        .where((row) => widget.visibleIds?.contains(row.id) ?? true)
        .toList();
    final valid = rows.any((a) => a.id == selected);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ghi nhận kết quả kiểm tra',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: valid ? selected : null,
              decoration: const InputDecoration(
                labelText: 'Chọn phân công cần kiểm tra',
              ),
              isExpanded: true,
              items: [
                for (final a in rows)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      '${widget.controller.people[a.text('maNguoiCuuHo')]?.text('hoTen', a.text('maNguoiCuuHo')) ?? a.text('maNguoiCuuHo')} · ${a.id}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: saving ? null : (v) => setState(() => selected = v),
            ),
            AbsorbPointer(
              absorbing: saving,
              child: RadioGroup<String>(
                groupValue: outcome,
                onChanged: (value) => setState(() => outcome = value),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: outcome == 'tiep_tuc'
                            ? const Color(0xFF1565C0).withValues(alpha: .06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: outcome == 'tiep_tuc'
                              ? const Color(0xFF1565C0)
                              : const Color(0xFFE0E7F0),
                        ),
                      ),
                      child: const RadioListTile<String>(
                        value: 'tiep_tuc',
                        activeColor: Color(0xFF1565C0),
                        title: Text(
                          'Vẫn tiếp tục hỗ trợ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Người hỗ trợ xác nhận có thể tiếp tục ca cứu hộ.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: outcome == 'can_thay_nguoi'
                            ? const Color(0xFFB77900).withValues(alpha: .06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: outcome == 'can_thay_nguoi'
                              ? const Color(0xFFB77900)
                              : const Color(0xFFE0E7F0),
                        ),
                      ),
                      child: const RadioListTile<String>(
                        value: 'can_thay_nguoi',
                        activeColor: Color(0xFFB77900),
                        title: Text(
                          'Cần thay người hỗ trợ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Ghi rõ lý do để điều phối bổ sung người hỗ trợ.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: note,
              enabled: !saving,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Ghi chú Admin',
                hintText: 'Thay người cần lý do ít nhất 10 ký tự',
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF193052),
              ),
              onPressed: saving || !valid || outcome == null ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Đang lưu…' : 'Lưu kết quả & cập nhật ca'),
            ),
          ],
        ),
      ),
    );
  }
}
