import 'package:flutter/material.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

// ════════════════════════════════════════════════════════════════════
// Báo cáo xử trí (thay cho dữ liệu y tế điền cứng)
// ════════════════════════════════════════════════════════════════════

Future<RescueReport?> showRescueReportSheet(
  BuildContext context, {
  required String victimName,
}) {
  return showModalBottomSheet<RescueReport>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(victimName: victimName),
  );
}

class _ReportSheet extends StatefulWidget {
  final String victimName;
  const _ReportSheet({required this.victimName});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _tinhTrang = ['Ổn định', 'Cần theo dõi', 'Nguy kịch'];
  static const _thaoTac = [
    'Cầm máu / băng ép',
    'Làm sạch và băng vết thương',
    'Nẹp cố định',
    'Hồi sức tim phổi (CPR)',
    'Hỗ trợ hô hấp',
    'Ổn định tư thế, giảm đau',
    'Theo dõi sinh hiệu',
    'Không cần can thiệp',
  ];

  String? _selected;
  final Set<String> _procedures = {};
  final _bp = TextEditingController();
  final _spo2 = TextEditingController();
  final _pulse = TextEditingController();
  final _transfer = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    for (final c in [_bp, _spo2, _pulse, _transfer, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Color _colorOf(String s) {
    switch (s) {
      case 'Ổn định':
        return RC.green;
      case 'Cần theo dõi':
        return RC.amber;
      default:
        return RC.red;
    }
  }

  void _submit() {
    if (_selected == null) return;
    Navigator.pop(
      context,
      RescueReport(
        tinhTrang: _selected!,
        thaoTac: _procedures.toList(),
        huyetAp: _bp.text.trim(),
        spo2: _spo2.text.trim(),
        mach: _pulse.text.trim(),
        chuyenTuyen: _transfer.text.trim(),
        ghiChu: _note.text.trim(),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 18),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: RC.ink,
      ),
    ),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: RC.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RcGrabHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Báo cáo xử trí',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nạn nhân: ${widget.victimName}. Chỉ ghi những gì bạn đã '
                      'thực hiện hoặc đo được. Nội dung được lưu vào hồ sơ cứu hộ.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: RC.muted,
                      ),
                    ),
                    _label('Tình trạng nạn nhân khi kết thúc'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _tinhTrang)
                          ChoiceChip(
                            label: Text(s),
                            selected: _selected == s,
                            selectedColor: _colorOf(s).withOpacity(0.15),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selected == s ? _colorOf(s) : RC.body,
                            ),
                            side: BorderSide(
                              color: _selected == s ? _colorOf(s) : RC.line,
                            ),
                            onSelected: (_) => setState(() => _selected = s),
                          ),
                      ],
                    ),
                    _label('Thao tác đã thực hiện'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _thaoTac)
                          FilterChip(
                            label: Text(t),
                            selected: _procedures.contains(t),
                            selectedColor: RC.blueSoft,
                            checkmarkColor: RC.blue,
                            side: BorderSide(
                              color: _procedures.contains(t) ? RC.blue : RC.line,
                            ),
                            onSelected: (on) => setState(() {
                              on ? _procedures.add(t) : _procedures.remove(t);
                            }),
                          ),
                      ],
                    ),
                    _label('Sinh hiệu (nếu có đo)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bp,
                            keyboardType: TextInputType.text,
                            decoration: _dec('Huyết áp'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _spo2,
                            keyboardType: TextInputType.number,
                            decoration: _dec('SpO₂ (%)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pulse,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Mạch'),
                          ),
                        ),
                      ],
                    ),
                    _label('Chuyển tuyến / bàn giao cho'),
                    TextField(
                      controller: _transfer,
                      decoration: _dec('Tên bệnh viện hoặc đơn vị (nếu có)'),
                    ),
                    _label('Ghi chú'),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: _dec('Diễn biến, lưu ý khi bàn giao…'),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, 52),
                        foregroundColor: RC.body,
                        side: const BorderSide(color: RC.line),
                      ),
                      child: const Text('Quay lại'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selected == null ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RC.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: RC.line,
                          minimumSize: const Size(0, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Lưu và hoàn thành ca',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
}

// ════════════════════════════════════════════════════════════════════
// Hủy ca có lý do
// ════════════════════════════════════════════════════════════════════

class CancelResult {
  final String reason;
  final String note;
  const CancelResult(this.reason, this.note);
}

Future<CancelResult?> showCancelCaseSheet(BuildContext context) {
  return showModalBottomSheet<CancelResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CancelSheet(),
  );
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  static const _reasons = [
    'Phương tiện gặp sự cố',
    'Không thể tiếp cận hiện trường',
    'Vấn đề sức khỏe hoặc an toàn của bản thân',
    'Đã có đội khác xử lý',
    'Khác',
  ];

  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _valid =>
      _reason != null && (_reason != 'Khác' || _note.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RcGrabHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hủy ca cứu hộ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chọn lý do để điều phối viên có thể phân công người khác. '
                      'Bạn sẽ được trả về trạng thái sẵn sàng nhận ca.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: RC.muted),
                    ),
                    const SizedBox(height: 12),
                    for (final r in _reasons)
                      RadioListTile<String>(
                        value: r,
                        groupValue: _reason,
                        onChanged: (v) => setState(() => _reason = v),
                        title: Text(r, style: const TextStyle(fontSize: 14.5)),
                        activeColor: RC.red,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    if (_reason == 'Khác') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _note,
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Mô tả lý do',
                          filled: true,
                          fillColor: RC.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, 52),
                        foregroundColor: RC.body,
                        side: const BorderSide(color: RC.line),
                      ),
                      child: const Text('Quay lại'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _valid
                            ? () => Navigator.pop(
                                context,
                                CancelResult(_reason!, _note.text.trim()),
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RC.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: RC.line,
                          minimumSize: const Size(0, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận hủy ca',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
}
