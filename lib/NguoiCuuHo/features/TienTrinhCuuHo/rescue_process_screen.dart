import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/step4_completed_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/rescue_process_controller.dart';
import 'widgets/process_stepper_header.dart';
import 'widgets/map_access_card.dart';
import 'widgets/team_members_card.dart';
import 'widgets/victim_detail_card.dart';

import 'widgets/step1_moving_view.dart';
import 'widgets/step2_arrived_view.dart';
import 'widgets/step3_rescuing_view.dart';

class TienTrinhCuuHo extends StatelessWidget {
  const TienTrinhCuuHo({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RescueProcessController(),
      child: Consumer<RescueProcessController>(
        builder: (context, controller, child) {
          final isStep4 = controller.currentStep == 3;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    // 🟢 1. Thanh Stepper 4 bước cố định ở đầu
                    const ProcessStepperHeader(),
                    const Divider(height: 1),
                    const SizedBox(height: 6),

                    // 🟢 2. XỬ LÝ CHUYỂN DẠNG GIAO DIỆN KHI SANG BƯỚC 4
                    if (isStep4) ...[
                      // 📄 BƯỚC 4: HIỂN THỊ PHIẾU BÀN GIAO TOÀN DIỆN
                      const Expanded(child: Step4CompletedFullView()),
                    ] else ...[
                      // 📍 BƯỚC 1 -> BƯỚC 3: GIỮ NGUYÊN BẢN ĐỒ, ĐỒNG ĐỘI & NẠN NHÂN
                      IndexedStack(
                        index: controller.currentStep,
                        children: const [
                          Step1MovingHeader(),
                          Step2ArrivedHeader(),
                          Step3RescuingHeader(),
                        ],
                      ),
                      const SizedBox(height: 6),

                      const Expanded(child: MapAccessCard()),
                      const SizedBox(height: 6),

                      const TeamMembersCard(),
                      const SizedBox(height: 6),

                      const VictimDetailCard(),
                      const SizedBox(height: 8),

                      _buildStepActionButton(context, controller),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🟢 HÀM RENDER CỤM NÚT BẤM CHO BƯỚC 1 -> 3
  Widget _buildStepActionButton(
    BuildContext context,
    RescueProcessController controller,
  ) {
    String primaryText;
    IconData primaryIcon;
    VoidCallback onPrimaryPressed;

    switch (controller.currentStep) {
      case 0:
        primaryText = 'ĐÃ ĐẾN NƠI';
        primaryIcon = Icons.location_on_outlined;
        onPrimaryPressed = () => controller.nextStep();
        break;
      case 1:
        primaryText = 'CỨU NẠN';
        primaryIcon = Icons.medical_services_outlined;
        onPrimaryPressed = () => controller.nextStep();
        break;
      case 2:
      default:
        primaryText = 'HOÀN THÀNH';
        primaryIcon = Icons.local_shipping_outlined;
        onPrimaryPressed = () => controller.nextStep();
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE52525).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE52525),
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onPrimaryPressed,
            icon: Icon(primaryIcon, color: Colors.white, size: 18),
            label: Text(
              primaryText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => _showCancelDialog(context),
            icon: const Icon(
              Icons.highlight_off,
              color: Color(0xFF64748B),
              size: 16,
            ),
            label: const Text(
              'Hủy ca / Không tiếp tục',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy ca',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy ca trực cứu hộ này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text(
              'Xác nhận hủy',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
