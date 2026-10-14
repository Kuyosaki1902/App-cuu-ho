import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/controllers/chv_coCCHN_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SectionEkyc extends StatelessWidget {
  const SectionEkyc({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CuuHoVienCoCCHNController>();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge,
                  color: Color(0xFF00897B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1. Thông tin cá nhân',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Họ và tên đầy đủ',
                  controller: controller.fullNameController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormGroup(
                  label: 'Số thẻ CCCD gắn chip',
                  controller: controller.cccdCardNoController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày sinh',
                  controller: controller.dobController,
                  readOnly: true,
                  onTap: () =>
                      controller.selectDate(context, controller.dobController),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giới tính',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.setGender('Nam'),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: controller.gender == 'Nam'
                                      ? const Color(0xFF00BFA5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Nam',
                                  style: TextStyle(
                                    color: controller.gender == 'Nam'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.setGender('Nữ'),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: controller.gender == 'Nữ'
                                      ? const Color(0xFF00BFA5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Nữ',
                                  style: TextStyle(
                                    color: controller.gender == 'Nữ'
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildFormGroup(
                  label: 'Ngày cấp CCCD',
                  controller: controller.cccdIssueDateController,
                  readOnly: true,
                  onTap: () => controller.selectDate(
                    context,
                    controller.cccdIssueDateController,
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFormGroup(
            label: 'Cơ quan cấp',
            controller: controller.cccdIssuerController,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
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
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 4),
        _buildInputField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
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
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
