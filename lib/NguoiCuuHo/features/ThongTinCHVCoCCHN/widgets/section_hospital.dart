import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chv_coCCHN_controller.dart';

class SectionHospital extends StatelessWidget {
  const SectionHospital({super.key});

  /// Hàm dùng chung hiển thị Dialog chọn dữ liệu có ô tìm kiếm
  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) {
    List<String> filteredItems = List.from(items);
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn $title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Ô tìm kiếm
                    TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm $title...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.blue,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setStateDialog(() {
                                    filteredItems = List.from(items);
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (query) {
                        setStateDialog(() {
                          filteredItems = items
                              .where(
                                (item) => item.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Danh sách lựa chọn
                    Flexible(
                      child: filteredItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Không tìm thấy kết quả phù hợp',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = currentValue == item;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE3F2FD)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.blue.shade900
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
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

          // 🟢 Hàng chọn Tỉnh / Thành phố & Quận / Huyện
          Row(
            children: [
              // Tỉnh / Thành phố
              Expanded(
                child: _buildSelectField(
                  label: 'Tỉnh / Thành phố',
                  isRequired: true,
                  value: controller.selectedRegion,
                  placeholder: 'Chọn tỉnh thành',
                  onTap: () => _showSelectionDialog(
                    context: context,
                    title: 'tỉnh thành',
                    icon: Icons.location_city_outlined,
                    items: controller.regionList,
                    currentValue: controller.selectedRegion,
                    onSelected: (val) => controller.setRegion(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Quận / Huyện
              Expanded(
                child: _buildSelectField(
                  label: 'Quận / Huyện',
                  isRequired: true,
                  value: controller.selectedDistrict,
                  placeholder: 'Chọn quận huyện',
                  onTap: () {
                    if (controller.districtList.isEmpty) return;
                    _showSelectionDialog(
                      context: context,
                      title: 'quận huyện',
                      icon: Icons.map_outlined,
                      items: controller.districtList,
                      currentValue: controller.selectedDistrict,
                      onSelected: (val) => controller.setDistrict(val),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🟢 Phần Bệnh viện (Mở Dialog lọc bệnh viện theo vị trí)
          _buildSelectField(
            label: 'Bệnh viện / Cơ sở khám chữa bệnh hiện tại',
            isRequired: true,
            value: controller.selectedHospital,
            placeholder: 'Nhập tên để tìm kiếm bệnh viện...',
            onTap: () => _showSelectionDialog(
              context: context,
              title: 'bệnh viện / cơ sở y tế',
              icon: Icons.local_hospital_outlined,
              items: controller.hospitalList,
              currentValue: controller.selectedHospital,
              onSelected: (val) => controller.setHospital(val),
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormGroup(
                  label: 'Mã thẻ nhân viên',
                  controller: controller.employeeIdController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Ảnh thẻ công tác'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'the_nganh.jpg',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.image, color: Colors.teal, size: 18),
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

  /// Widget chọn hiển thị dạng ô nhấn mở Dialog
  Widget _buildSelectField({
    required String label,
    required bool isRequired,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: value != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
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
