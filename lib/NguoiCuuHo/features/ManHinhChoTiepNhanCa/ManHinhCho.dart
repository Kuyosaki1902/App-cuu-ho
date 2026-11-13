import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/rescue_process_screen.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_navigation.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/emergency_alert_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/alert_style.dart';
import 'widgets/critical_alert_card.dart';
import 'widgets/doctor_header_card.dart';
import 'widgets/map_navigation_card.dart';
import 'widgets/victim_info_card.dart';

class Manhinhcho extends StatefulWidget {
  final String currentUserId;

  /// Mã ca cần chờ. Để rỗng thì lấy ca đang chờ tiếp nhận đầu tiên.
  final String maYeuCauCuuHo;

  const Manhinhcho({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
  });

  @override
  State<Manhinhcho> createState() => _ManhinhchoState();
}

class _ManhinhchoState extends State<Manhinhcho> {
  late final EmergencyAlertController _controller;
  bool _handled = false;

  static const _rejectReasons = [
    'Đang bận việc khác',
    'Quá xa, không kịp đến',
    'Sức khỏe hoặc an toàn của bản thân',
    'Phương tiện gặp sự cố',
    'Lý do khác',
  ];

  @override
  void initState() {
    super.initState();
    // Tạo controller trong State (không còn truyền BuildContext vào controller).
    _controller = EmergencyAlertController()
      ..start(widget.currentUserId, expectedMaYeuCau: widget.maYeuCauCuuHo);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Controller chỉ báo giai đoạn; việc điều hướng do màn hình làm.
  void _onChanged() {
    if (_handled) return;
    final p = _controller.phase;
    if (p == AlertPhase.waiting || p == AlertPhase.accepting) return;
    _handled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handlePhase(p);
    });
  }

  /// Hộp thoại báo ca đã đủ cứu hộ viên. Chỉ có một nút, bấm xong về trang chủ.
  Future<void> _showTeamFullDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.groups_rounded, size: 44, color: RC.amber),
          title: const Text(
            'Đã đủ cứu hộ viên',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RC.ink,
            ),
          ),
          content: Text(
            'Ca này đã có đủ ${AlertStatus.soCuuHoToiDa} cứu hộ viên tiếp nhận. '
            'Cảm ơn bạn đã sẵn sàng hỗ trợ.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4, color: RC.body),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RC.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePhase(AlertPhase p) async {
    if (p == AlertPhase.full) {
      await _showTeamFullDialog();
      if (!mounted) return;
      goToRescuerHome(context, widget.currentUserId);
      return;
    }

    if (p == AlertPhase.accepted) {
      // Thay thế màn hình chờ (bản cũ dùng push nên màn hình chờ vẫn nằm dưới).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TienTrinhCuuHo(
            currentUserId: _controller.currentDoctorId,
            maYeuCauCuuHo: _controller.currentMaYeuCau,
          ),
        ),
      );
      return;
    }

    String? message;
    switch (p) {
      case AlertPhase.expired:
        message = 'Đã hết thời gian phản hồi. Ca được chuyển cho người khác.';
        break;
      case AlertPhase.rejected:
        message = 'Bạn đã từ chối ca này.';
        break;
      case AlertPhase.cancelledByVictim:
        message = 'Người báo tin đã hủy yêu cầu.';
        break;
      case AlertPhase.reassigned:
        message = 'Ca này không còn chờ bạn phản hồi.';
        break;
      default:
        break;
    }
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      goToRescuerHome(context, widget.currentUserId);
    }
  }

  Future<void> _onAccept() async {
    final result = await _controller.accept();
    if (!mounted) return;
    if (result == AcceptResult.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối. Hãy kiểm tra mạng và thử lại.'),
        ),
      );
    }
    // success / notAvailable / full được xử lý qua phase (xem _handlePhase).
  }

  Future<void> _onReject() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RcGrabHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Vì sao bạn không nhận ca này?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: RC.ink,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Ca sẽ được chuyển cho cứu hộ viên khác.',
                style: TextStyle(fontSize: 13, color: RC.muted),
              ),
            ),
            for (final r in _rejectReasons)
              ListTile(
                title: Text(r),
                minVerticalPadding: 12,
                onTap: () => Navigator.pop(sheetContext, r),
              ),
            ListTile(
              title: const Text('Quay lại', style: TextStyle(color: RC.muted)),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
    if (reason != null) await _controller.reject(reason);
  }

  Widget _buildActionBar(BuildContext context) {
    final phase = context.select<EmergencyAlertController, AlertPhase>(
      (c) => c.phase,
    );
    final level = context.select<EmergencyAlertController, int>(
      (c) => c.mucDoKhanCap,
    );
    final style = AlertStyle.of(level);
    final busy = phase == AlertPhase.accepting;
    final enabled = phase == AlertPhase.waiting;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh thời gian còn lại luôn nhìn thấy, kể cả khi sheet thu nhỏ.
            ValueListenableBuilder<int>(
              valueListenable: _controller.remainingSeconds,
              builder: (_, left, __) => LinearProgressIndicator(
                value: left / EmergencyAlertController.totalSeconds,
                minHeight: 4,
                backgroundColor: style.soft,
                valueColor: AlwaysStoppedAnimation<Color>(
                  left <= 30 ? RC.red : style.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: enabled ? _onAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: style.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: style.color.withOpacity(0.55),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_run, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Cứu hộ ngay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            TextButton(
              onPressed: enabled ? _onReject : null,
              style: TextButton.styleFrom(
                foregroundColor: RC.muted,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Từ chối ca'),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: WillPopScope(
        // Thoát giữa chừng sẽ để ca ở trạng thái chờ mãi (không còn ai xử lý hết giờ).
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hãy nhận hoặc từ chối ca này.')),
          );
          return false;
        },
        child: Scaffold(
          backgroundColor: RC.surface,
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: MapNavigationCard()),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: DoctorHeaderCard(),
                        ),
                      ),
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.5,
                      minChildSize: 0.3,
                      maxChildSize: 0.92,
                      snap: true,
                      snapSizes: const [0.5],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: RC.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: RC.shadow,
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            children: const [
                              RcGrabHandle(),
                              CriticalAlertCard(),
                              SizedBox(height: 12),
                              VictimInfoCard(),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Builder(builder: _buildActionBar),
            ],
          ),
        ),
      ),
    );
  }
}
