import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_navigation.dart';
import 'rescue_theme.dart';

/// Bước 4: phiếu bàn giao. Mọi số liệu đến từ ca thực tế và báo cáo do
/// cứu hộ viên nhập (không còn giờ, cấp độ, sinh hiệu điền cứng).
class Step4CompletedFullView extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;

  const Step4CompletedFullView({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
  });

  static Color _statusColor(String s) {
    switch (s) {
      case 'Ổn định':
        return RC.green;
      case 'Cần theo dõi':
        return RC.amber;
      default:
        return RC.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final r = c.report;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: rcCardDecoration(radius: 20, shadow: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Đầu phiếu
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: RC.greenSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: RC.green, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ca cứu hộ đã hoàn thành',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: RC.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mã ca #$maYeuCauCuuHo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: RC.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          clock(c.completedAt),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: RC.body,
                            fontFeatures: RC.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: RC.line),

                  // Nạn nhân
                  _Section(
                    title: 'Nạn nhân',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.victimName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: RC.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.victimAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: RC.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: RC.line),

                  // Thời gian
                  _Section(
                    title: 'Thời gian',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Tổng thời gian ca',
                                value: c.formattedTotalTime,
                                big: true,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Thời gian can thiệp',
                                value: c.formattedRescueTime,
                                big: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Đến hiện trường',
                                value: clock(c.arrivedAt),
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Hoàn thành',
                                value: clock(c.completedAt),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: RC.line),

                  // Báo cáo xử trí
                  _Section(
                    title: 'Báo cáo xử trí',
                    child: r == null
                        ? const Text(
                            'Không có dữ liệu báo cáo cho ca này.',
                            style: TextStyle(fontSize: 13, color: RC.muted),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RcPill(
                                text: 'Tình trạng: ${r.tinhTrang}',
                                fg: _statusColor(r.tinhTrang),
                                bg: _statusColor(r.tinhTrang).withOpacity(0.10),
                              ),
                              if (r.thaoTac.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final t in r.thaoTac)
                                      RcPill(text: t, fg: RC.blue, bg: RC.blueSoft),
                                  ],
                                ),
                              ],
                              if (r.huyetAp.isNotEmpty ||
                                  r.spo2.isNotEmpty ||
                                  r.mach.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (r.huyetAp.isNotEmpty)
                                      Expanded(
                                        child: _Metric(
                                          label: 'Huyết áp',
                                          value: r.huyetAp,
                                        ),
                                      ),
                                    if (r.spo2.isNotEmpty)
                                      Expanded(
                                        child: _Metric(
                                          label: 'SpO₂ (%)',
                                          value: r.spo2,
                                        ),
                                      ),
                                    if (r.mach.isNotEmpty)
                                      Expanded(
                                        child: _Metric(
                                          label: 'Mạch',
                                          value: r.mach,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              if (r.chuyenTuyen.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _Metric(
                                  label: 'Chuyển tuyến / bàn giao cho',
                                  value: r.chuyenTuyen,
                                ),
                              ],
                              if (r.ghiChu.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _Metric(label: 'Ghi chú', value: r.ghiChu),
                              ],
                            ],
                          ),
                  ),
                  const Divider(height: 1, color: RC.line),

                  // Người lập
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: _Metric(
                      label: 'Người lập báo cáo',
                      value: '${c.doctorName} · ${c.doctorRoleLabel}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => goToRescuerHome(context, currentUserId),
              icon: const Icon(Icons.near_me, size: 20),
              label: const Text(
                'Sẵn sàng nhận ca mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RC.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: RC.muted),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  const _Metric({required this.label, required this.value, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: RC.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 24 : 15,
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: RC.ink,
            fontFeatures: RC.tabular,
          ),
        ),
      ],
    );
  }
}
