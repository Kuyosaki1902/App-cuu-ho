import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';
import 'form_widgets.dart';

class SectionEkycNoCchn extends StatelessWidget {
  const SectionEkycNoCchn({super.key});

  static const List<String> issuers = [
    'Cục Cảnh sát quản lý hành chính về trật tự xã hội',
    'Bộ Công an',
  ];

  Future<void> _pick(
    BuildContext context,
    CuuHoVienKhongCCHNController c,
    ImageSlot slot, {
    required String title,
    bool cameraOnly = false,
  }) async {
    final source = cameraOnly
        ? ImageSource.camera
        : await showPhotoSourceSheet(context, title: title);
    if (source != null) await c.pickSlot(slot, source);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.badge,
            title: '1. Xác minh danh tính',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Họ và tên đầy đủ',
                  controller: c.fullNameController,
                  readOnly: true,
                  suffix: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Số CCCD / Căn cước',
                  isRequired: true,
                  controller: c.cccdCardNoController,
                  hint: '12 chữ số',
                  keyboardType: TextInputType.number,
                  validator: c.validateCccd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Ngày cấp CCCD',
                  isRequired: true,
                  controller: c.cccdIssueDateController,
                  readOnly: true,
                  hint: 'dd/MM/yyyy',
                  onTap: () => c.selectDate(
                    context,
                    c.cccdIssueDateController,
                    lastDate: DateTime.now(),
                  ),
                  suffix: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  validator: (v) => c.validateRequired(v, 'Chọn ngày cấp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Ngày hết hạn CCCD',
                  isRequired: true,
                  controller: c.cccdExpiryDateController,
                  readOnly: true,
                  hint: 'dd/MM/yyyy',
                  onTap: () => c.selectDate(
                    context,
                    c.cccdExpiryDateController,
                    firstDate: DateTime.now(),
                  ),
                  suffix: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  validator: (v) => c.validateRequired(v, 'Chọn ngày hết hạn'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledField(
            label: 'Cơ quan cấp',
            isRequired: true,
            controller: c.cccdIssuerController,
            readOnly: true,
            onTap: () async {
              final v = await showSelectionDialog(
                context,
                title: 'Chọn cơ quan cấp',
                icon: Icons.account_balance,
                items: issuers,
                selected: c.cccdIssuerController.text,
              );
              if (v != null) c.cccdIssuerController.text = v;
            },
            suffix: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Ảnh giấy tờ để người duyệt đối chiếu', isRequired: true),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PhotoTile(
                label: 'CCCD\nmặt trước',
                file: c.singlePhotos[ImageSlot.cccdFront],
                onAdd: () => _pick(context, c, ImageSlot.cccdFront,
                    title: 'Ảnh CCCD mặt trước'),
                onRemove: () => c.removeSlot(ImageSlot.cccdFront),
              ),
              PhotoTile(
                label: 'CCCD\nmặt sau',
                file: c.singlePhotos[ImageSlot.cccdBack],
                onAdd: () => _pick(context, c, ImageSlot.cccdBack,
                    title: 'Ảnh CCCD mặt sau'),
                onRemove: () => c.removeSlot(ImageSlot.cccdBack),
              ),
              PhotoTile(
                label: 'Selfie\ncầm CCCD',
                file: c.singlePhotos[ImageSlot.selfie],
                // Selfie bắt buộc chụp trực tiếp, không chọn từ thư viện.
                onAdd: () => _pick(context, c, ImageSlot.selfie,
                    title: 'Selfie cầm CCCD', cameraOnly: true),
                onRemove: () => c.removeSlot(ImageSlot.selfie),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chụp rõ nét, đủ 4 góc giấy tờ. Selfie: giữ CCCD cạnh mặt, thấy rõ cả hai. '
            'Ảnh được lưu bảo mật, chỉ người duyệt được xem.',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
