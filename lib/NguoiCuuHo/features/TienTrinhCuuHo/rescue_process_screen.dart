import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'controllers/rescue_process_controller.dart';
import 'widgets/map_access_card.dart';
import 'widgets/process_stepper_header.dart';
import 'widgets/rescue_navigation.dart';
import 'widgets/rescue_sheets.dart';
import 'widgets/rescue_theme.dart';
import 'widgets/step1_moving_view.dart';
import 'widgets/step2_arrived_view.dart';
import 'widgets/step3_rescuing_view.dart';
import 'widgets/step4_completed_view.dart';
import 'widgets/team_members_card.dart';
import 'widgets/victim_detail_card.dart';

class TienTrinhCuuHo extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;

  /// Ngày (yyyy-MM-dd) của bản ghi phân công; trang chủ truyền vào.
  final String? dayKey;

  const TienTrinhCuuHo({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
    this.dayKey,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          RescueProcessController(currentUserId, maYeuCauCuuHo, dayKey: dayKey),
      child: _RescueView(
        currentUserId: currentUserId,
        maYeuCauCuuHo: maYeuCauCuuHo,
      ),
    );
  }
}

class _RescueView extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;
  const _RescueView({required this.currentUserId, required this.maYeuCauCuuHo});

  /// Chặn nút Back: nếu thoát giữa ca, trạng thái "đang trực" sẽ bị kẹt.
  Future<bool> _onWillPop(BuildContext context, int step) async {
    if (step == RescueProcessController.stepCompleted) {
      goToRescuerHome(context, currentUserId);
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bạn đang trong ca cứu hộ. Hãy hoàn thành ca hoặc dùng nút Hủy ca.',
        ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // select: chỉ rebuild khi đổi bước, không rebuild theo từng lần GPS.
    final step = context.select<RescueProcessController, int>(
      (c) => c.currentStep,
    );
    final completed = step == RescueProcessController.stepCompleted;

    return WillPopScope(
      onWillPop: () => _onWillPop(context, step),
      child: completed
          ? Scaffold(
              backgroundColor: RC.surface,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    children: [
                      const ProcessStepperHeader(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Step4CompletedFullView(
                          currentUserId: currentUserId,
                          maYeuCauCuuHo: maYeuCauCuuHo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Scaffold(
              backgroundColor: RC.surface,
              body: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(child: MapAccessCard()),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const ProcessStepperHeader(),
                                  const _VictimCancelledBanner(),
                                  const _LocationBanner(),
                                  const _MapQuickActions(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const _InfoSheet(),
                      ],
                    ),
                  ),
                  _ActionBar(
                    currentUserId: currentUserId,
                    maYeuCauCuuHo: maYeuCauCuuHo,
                  ),
                ],
              ),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Người báo tin hủy yêu cầu (sau khi đã nhận ca)
// ════════════════════════════════════════════════════════════════════
class _VictimCancelledBanner extends StatelessWidget {
  const _VictimCancelledBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    if (!c.victimCancelled) return const SizedBox.shrink();
    final canEnd = c.currentStep <= RescueProcessController.stepArrived;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: RC.redSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RC.redLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.report_gmailerrorred, color: RC.red, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người báo tin đã hủy yêu cầu',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: RC.redDark,
                    ),
                  ),
                  Text(
                    canEnd
                        ? 'Xác nhận kết thúc ca nếu bạn chưa tiếp cận nạn nhân.'
                        : 'Nếu bạn đã can thiệp, hãy hoàn tất báo cáo xử trí.',
                    style: const TextStyle(fontSize: 12, color: RC.body),
                  ),
                ],
              ),
            ),
            if (canEnd)
              TextButton(
                onPressed: c.isBusy
                    ? null
                    : () async {
                        await c.cancelCase(
                          reason: 'Người báo tin đã hủy yêu cầu',
                        );
                        if (context.mounted) {
                          goToRescuerHome(context, c.currentDoctorId);
                        }
                      },
                child: const Text('Kết thúc ca'),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Cảnh báo GPS
// ════════════════════════════════════════════════════════════════════
class _LocationBanner extends StatelessWidget {
  const _LocationBanner();

  @override
  Widget build(BuildContext context) {
    final status = context.select<RescueProcessController, LocationStatus>(
      (c) => c.locationStatus,
    );
    if (status == LocationStatus.ok || status == LocationStatus.initializing) {
      return const SizedBox.shrink();
    }

    final c = context.read<RescueProcessController>();
    late final String message;
    late final String action;
    late final VoidCallback onAction;
    switch (status) {
      case LocationStatus.serviceDisabled:
        message = 'GPS đang tắt.';
        action = 'Bật GPS';
        onAction = () => Geolocator.openLocationSettings();
        break;
      case LocationStatus.permissionDenied:
        message = 'Ứng dụng chưa được cấp quyền vị trí.';
        action = 'Cấp quyền';
        onAction = c.retryLocation;
        break;
      case LocationStatus.permissionDeniedForever:
        message = 'Quyền vị trí đã bị chặn.';
        action = 'Mở cài đặt';
        onAction = () => Geolocator.openAppSettings();
        break;
      default:
        message = 'Không lấy được vị trí GPS.';
        action = 'Thử lại';
        onAction = c.retryLocation;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: RC.amberSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RC.amberLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_off, color: RC.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RC.amber,
                    ),
                  ),
                  const Text(
                    'Bạn vẫn có thể xác nhận đã đến nơi thủ công.',
                    style: TextStyle(fontSize: 12, color: RC.body),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Nút nhanh trên bản đồ
// ════════════════════════════════════════════════════════════════════
class _MapQuickActions extends StatelessWidget {
  const _MapQuickActions();

  Widget _btn(IconData icon, String tip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: tip,
        child: Material(
          color: Colors.white,
          elevation: 3,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: RC.ink, size: 21),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.read<RescueProcessController>();
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.zoom_out_map, 'Xem toàn tuyến', () {
              if (c.currentStep == RescueProcessController.stepMoving) {
                c.fitMapBounds();
              } else {
                c.focusVictim();
              }
            }),
            _btn(
              Icons.navigation,
              'Dẫn đường bằng Google Maps',
              c.openExternalNavigation,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Bottom sheet kéo được
// ════════════════════════════════════════════════════════════════════
class _InfoSheet extends StatelessWidget {
  const _InfoSheet();

  Widget _statusCard(int step) {
    switch (step) {
      case RescueProcessController.stepMoving:
        return const Step1MovingHeader();
      case RescueProcessController.stepArrived:
        return const Step2ArrivedHeader();
      default:
        return const Step3RescuingHeader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = context.select<RescueProcessController, int>(
      (c) => c.currentStep,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.22,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.44],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: RC.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: RC.shadow,
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              const RcGrabHandle(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: _statusCard(step),
                ),
              ),
              const SizedBox(height: 12),
              const VictimDetailCard(),
              const SizedBox(height: 12),
              const TeamMembersCard(),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Thanh hành động cố định
// ════════════════════════════════════════════════════════════════════
class _ActionBar extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;
  const _ActionBar({required this.currentUserId, required this.maYeuCauCuuHo});

  Future<void> _onArrive(
    BuildContext context,
    RescueProcessController c,
  ) async {
    if (c.isNearVictim) {
      await c.confirmArrival();
      return;
    }
    final d = c.distanceToVictimMeters;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đã đến nơi?'),
        content: Text(
          d == null
              ? 'Chưa xác định được vị trí GPS của bạn. Chỉ xác nhận khi bạn đã thực sự có mặt tại hiện trường.'
              : 'Bạn đang cách nạn nhân khoảng ${RescueProcessController.formatMeters(d)}. '
                    'Chỉ xác nhận khi bạn đã thực sự có mặt tại hiện trường.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Chưa đến'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xác nhận đã đến',
              style: TextStyle(color: RC.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await c.confirmArrival();
  }

  Future<void> _onComplete(
    BuildContext context,
    RescueProcessController c,
  ) async {
    final report = await showRescueReportSheet(
      context,
      victimName: c.victimName,
    );
    if (report != null) await c.completeMission(report);
  }

  Future<void> _onCancel(
    BuildContext context,
    RescueProcessController c,
  ) async {
    final result = await showCancelCaseSheet(context);
    if (result == null) return;
    await c.cancelCase(reason: result.reason, note: result.note);
    if (context.mounted) goToRescuerHome(context, currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final step = c.currentStep;

    late final String label;
    late final IconData icon;
    late final VoidCallback onPressed;
    String? hint;
    var hintColor = RC.muted;
    var outlined = false;

    switch (step) {
      case RescueProcessController.stepMoving:
        final d = c.distanceToVictimMeters;
        final near = c.isNearVictim;
        label = near ? 'Đã đến nơi' : 'Xác nhận đã đến nơi';
        icon = Icons.place;
        outlined = !near;
        hint = d == null
            ? 'Chưa có vị trí GPS. Bạn có thể xác nhận thủ công.'
            : near
            ? 'Bạn đang cách nạn nhân ${RescueProcessController.formatMeters(d)}.'
            : 'Còn cách nạn nhân ${RescueProcessController.formatMeters(d)}. Chỉ xác nhận khi đã có mặt.';
        hintColor = near ? RC.green : RC.muted;
        onPressed = () => _onArrive(context, c);
        break;
      case RescueProcessController.stepArrived:
        label = 'Bắt đầu cứu nạn';
        icon = Icons.medical_services_outlined;
        onPressed = () => c.startRescue();
        break;
      default:
        label = 'Hoàn thành ca';
        icon = Icons.task_alt;
        onPressed = () => _onComplete(context, c);
    }

    final canCancel = step <= RescueProcessController.stepArrived;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: RC.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: hintColor,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: c.isBusy ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: outlined ? Colors.white : RC.red,
                    foregroundColor: outlined ? RC.red : Colors.white,
                    disabledBackgroundColor: RC.red.withOpacity(0.55),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    side: BorderSide(color: RC.red, width: outlined ? 1.5 : 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: c.isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (canCancel)
                TextButton(
                  onPressed: c.isBusy ? null : () => _onCancel(context, c),
                  style: TextButton.styleFrom(
                    foregroundColor: RC.muted,
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Không thể tiếp tục ca này'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
