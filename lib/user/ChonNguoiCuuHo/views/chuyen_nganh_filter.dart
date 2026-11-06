// views/chuyen_nganh_filter.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/ChonNguoiCuuHo/controllers/chon_nguoi_cuu_ho_controller.dart';

class ChuyenNganhFilterWidget extends StatelessWidget {
  final List<ChuyenNganhModel> dsChuyenNganh;
  final List<ItemNguoiCuuHo> allDoctors;
  final int selectedCategoryIndex;
  final Function(int) onCategorySelected;

  const ChuyenNganhFilterWidget({
    super.key,
    required this.dsChuyenNganh,
    required this.allDoctors,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: dsChuyenNganh.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategoryIndex == index;
          final category = dsChuyenNganh[index];

          int count = index == 0
              ? allDoctors.length
              : allDoctors
                    .where((d) => d.maChuyenNganh == category.maChuyenNganh)
                    .length;

          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0C5C4D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${category.tenChuyenNganh} ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
