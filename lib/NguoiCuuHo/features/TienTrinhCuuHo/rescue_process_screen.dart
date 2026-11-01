import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'controllers/rescue_process_controller.dart';
import 'widgets/process_stepper_header.dart';
import 'widgets/map_access_card.dart';
import 'widgets/team_members_card.dart';
import 'widgets/victim_detail_card.dart';

import 'widgets/step1_moving_view.dart';
import 'widgets/step2_arrived_view.dart';
import 'widgets/step3_rescuing_view.dart';
import 'widgets/step4_completed_view.dart'; // Import đúng tệp Step 4 của bạn

class TienTrinhCuuHo extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;
  const TienTrinhCuuHo({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RescueProcessController(currentUserId, maYeuCauCuuHo),
      child: Consumer<RescueProcessController>(
        builder: (context, controller, child) {
          // 🟢 Chỉ định nghĩa là Step 4 khi currentStep đạt giá trị 3
          final bool isStep4 = controller.currentStep == 3;

          // Tự động chuyển sang bước 2 khi khoảng cách $\le 2m$ ở bước 1
          if (controller.currentStep == 0 &&
              controller.doctorLocation.latitude != 0.0 &&
              controller.victimLocation.latitude != 0.0) {
            double distanceInMeters = Geolocator.distanceBetween(
              controller.doctorLocation.latitude,
              controller.doctorLocation.longitude,
              controller.victimLocation.latitude,
              controller.victimLocation.longitude,
            );

            if (distanceInMeters <= 2.0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.currentStep == 0) {
                  controller.nextStep();
                }
              });
            }
          }

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
                    // Thanh Stepper hiển thị tiến trình 4 bước ở đầu
                    const ProcessStepperHeader(),
                    const Divider(height: 1),
                    const SizedBox(height: 6),

                    // 🟢 PHÂN RẼ GIAO DIỆN CHUẨN XÁC THEO TỪNG BƯỚC
                    if (isStep4) ...[
                      // 📄 BƯỚC 4: HIỂN THỊ PHIẾU BÀN GIAO VÀ NÚT SẴN SÀNG CA MỚI
                      Expanded(
                        child: Step4CompletedFullView(
                          currentUserId: currentUserId,
                          maYeuCauCuuHo: maYeuCauCuuHo,
                        ),
                      ),
                    ] else ...[
                      // 📍 BƯỚC 1, 2, 3: HIỂN THỊ BẢN ĐỒ, THÔNG TIN VÀ NÚT HÀNH ĐỘNG TƯƠNG ỨNG
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

  Widget _buildStepActionButton(
    BuildContext context,
    RescueProcessController controller,
  ) {
    String primaryText;
    IconData primaryIcon;
    VoidCallback?
    onPrimaryPressed; // Cho phép nhận giá trị null để vô hiệu hóa nút
    bool showCancelButton = false;

    switch (controller.currentStep) {
      case 0: // 📍 BƯỚC 1: DI CHUYỂN
        primaryText = 'ĐÃ ĐẾN NƠI (PHẠM VI <= 2M)';
        primaryIcon = Icons.location_on_outlined;

        // 🟢 Tính toán khoảng cách thực tế giữa cứu hộ viên và nạn nhân
        double distanceInMeters =
            999.0; // Mặc định giá trị lớn nếu chưa có tọa độ
        if (controller.doctorLocation.latitude != 0.0 &&
            controller.victimLocation.latitude != 0.0) {
          distanceInMeters = Geolocator.distanceBetween(
            controller.doctorLocation.latitude,
            controller.doctorLocation.longitude,
            controller.victimLocation.latitude,
            controller.victimLocation.longitude,
          );
        }

        // 🟢 CHẶN: Chỉ cho phép bấm (hoặc tự động chuyển) khi khoảng cách <= 2 mét
        if (distanceInMeters <= 2.0) {
          onPrimaryPressed = () => controller.nextStep();
        } else {
          onPrimaryPressed = null; // Vô hiệu hóa nút khi ngoài tầm 2 mét
        }

        showCancelButton = false;
        break;

      case 1: // 📍 BƯỚC 2: ĐÃ ĐẾN NƠI
        primaryText = 'CỨU NẠN';
        primaryIcon = Icons.medical_services_outlined;
        onPrimaryPressed = () => controller.nextStep();
        showCancelButton = true; // Hiển thị nút hủy ca ở bước 2
        break;

      case 2: // 📍 BƯỚC 3: ĐANG SƠ CỨU
      default:
        primaryText = 'HOÀN THÀNH';
        primaryIcon = Icons.local_shipping_outlined;
        onPrimaryPressed = () async {
          await controller.completeRescueMission(currentUserId, maYeuCauCuuHo);
          await controller.saveRescueRecordToFirestore(
            currentUserId,
            maYeuCauCuuHo,
          );
          controller.nextStep();
        };
        showCancelButton = false;
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
                color: const Color(
                  0xFFE52525,
                ).withOpacity(onPrimaryPressed != null ? 0.25 : 0.0),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              // 🟢 Đổi màu xám mờ nếu nút bị vô hiệu hóa do ngoài tầm 2m
              backgroundColor: onPrimaryPressed != null
                  ? const Color(0xFFE52525)
                  : Colors.grey.shade300,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onPrimaryPressed, // Nếu null, nút sẽ tự động bị disable
            icon: Icon(
              primaryIcon,
              color: onPrimaryPressed != null
                  ? Colors.white
                  : Colors.grey.shade600,
              size: 18,
            ),
            label: Text(
              primaryText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: onPrimaryPressed != null
                    ? Colors.white
                    : Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        // Chỉ hiển thị nút hủy khi ở Bước 2
        if (showCancelButton) ...[
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
              onPressed: () => _showCancelDialog(context, controller),
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
      ],
    );
  }

  void _showCancelDialog(
    BuildContext context,
    RescueProcessController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy ca',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy ca trực cứu hộ này không? Trạng thái ca sẽ chuyển thành đã hủy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // 1. Cập nhật trạng thái hủy ca lên Firestore
              await controller.cancelAssignment(currentUserId, maYeuCauCuuHo);

              // 2. Đặt lại nhanCaCuuHo = false để cứu hộ viên rảnh tay nhận ca mới
              await controller.releaseRescueDuty(currentUserId);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext); // Đóng hộp thoại xác nhận
              }

              if (context.mounted) {
                // 🟢 3. XÓA SẠCH STACK VÀ ĐƯA VỀ THẲNG MÀN HÌNH TRANG CHỦ
                // (Thay MainScreen bằng tên Widget màn hình chính của bạn)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Trangchunguoicuuho()),
                  (route) =>
                      false, // Xóa toàn bộ lịch sử màn hình chờ/tiến trình cũ
                );
              }
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
