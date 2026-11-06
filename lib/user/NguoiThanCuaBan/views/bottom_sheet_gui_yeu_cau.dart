// lib/user/NguoiThanCuaBan/views/bottom_sheet_gui_yeu_cau.dart

import 'package:flutter/material.dart';
import 'package:cuhokhancap/user/NguoiThanCuaBan/controllers/nguoi_than_controller.dart';

class BottomSheetGuiYeuCau extends StatefulWidget {
  final Color primaryColor;
  final String targetName;
  final String targetPhone;
  final Function(String myRelation, String targetRelation) onConfirm;

  const BottomSheetGuiYeuCau({
    super.key,
    required this.primaryColor,
    required this.targetName,
    required this.targetPhone,
    required this.onConfirm,
  });

  static void show(
    BuildContext context,
    Color primaryColor, {
    required String name,
    required String phone,
    required Function(String myRelation, String targetRelation) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetGuiYeuCau(
        primaryColor: primaryColor,
        targetName: name,
        targetPhone: phone,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BottomSheetGuiYeuCau> createState() => _BottomSheetGuiYeuCauState();
}

class _BottomSheetGuiYeuCauState extends State<BottomSheetGuiYeuCau> {
  late final BottomSheetGuiYeuCauController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = BottomSheetGuiYeuCauController();
    _sheetController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onControllerUpdate);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Thiết lập mối quan hệ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),

          // 1. DROPDOWN CHỌN MỐI QUAN HỆ BÊN TRÊN
          const Text(
            'Chọn mối quan hệ:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _sheetController.selectedPairLabel,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: _sheetController.pairOptions
                .map(
                  (pair) => DropdownMenuItem(
                    value: pair,
                    child: Text(
                      pair,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) _sheetController.updatePair(val);
            },
          ),

          const SizedBox(height: 20),

          // 2. HIỂN THỊ KHUNG TĨNH (KHÔNG DÙNG DROPDOWN NỮA)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bạn là
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bạn là',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildReadOnlyCard(_sheetController.myRelation),
                  ],
                ),
              ),

              // Nút Swap hoán đổi vị trí
              Padding(
                padding: const EdgeInsets.only(top: 18.0, left: 6, right: 6),
                child: Material(
                  color: widget.primaryColor.withOpacity(0.1),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: widget.primaryColor,
                    ),
                    tooltip: 'Đổi chiều mối quan hệ',
                    onPressed: _sheetController.swapRelations,
                  ),
                ),
              ),

              // Đối phương là
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.targetName} là',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildReadOnlyCard(_sheetController.targetRelation),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. NÚT GỬI YÊU CẦU
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              widget.onConfirm(
                _sheetController.myRelation,
                _sheetController.targetRelation,
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Gửi yêu cầu thiết lập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khung hiển thị Card tĩnh xịn xịn
  Widget _buildReadOnlyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
