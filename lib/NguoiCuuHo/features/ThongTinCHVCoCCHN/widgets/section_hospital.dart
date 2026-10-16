import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/chv_coCCHN_controller.dart';

class SectionHospital extends StatelessWidget {
  const SectionHospital({super.key});

  /// BottomSheet chọn nguồn ảnh
  void _showImagePickerModal(
    BuildContext context,
    CuuHoVienCoCCHNController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn ảnh thẻ công tác',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.teal),
                  title: const Text('Chọn từ thư viện ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickWorkCardImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.teal),
                  title: const Text('Chụp ảnh mới từ Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickWorkCardImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienCoCCHNController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3. Đơn vị công tác',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bệnh viện đang công tác thực tại',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFormGroup(
            label: 'Bệnh viện / Cơ sở khám chữa bệnh hiện tại',
            isRequired: true,
            controller: controller.hospitalController,
            hintText: 'Nhập tên bệnh viện / cơ sở y tế...',
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Mã thẻ nhân viên',
                  controller: controller.employeeIdController,
                  hintText: 'xx-xx-xxxx',
                ),
              ),
              const SizedBox(width: 8),
              // 🟢 Widget chọn Ảnh thẻ công tác
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Ảnh thẻ công tác'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showImagePickerModal(context, controller),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: controller.workCardImage != null
                              ? Border.all(color: Colors.teal)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.workCardImage != null
                                    ? controller.workCardImage!.path
                                          .split('/')
                                          .last
                                    : 'Chọn ảnh thẻ...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: controller.workCardImage != null
                                      ? Colors.teal.shade800
                                      : Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: controller.workCardImage != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (controller.workCardImage != null)
                              GestureDetector(
                                onTap: () => controller.removeWorkCardImage(),
                                child: const Icon(
                                  Icons.cancel,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              )
                            else
                              const Icon(
                                Icons.image,
                                color: Colors.teal,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildFormGroup({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xFFEEF2FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
