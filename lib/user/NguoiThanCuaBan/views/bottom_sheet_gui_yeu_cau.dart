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
    final targetOptions = _sheetController.getTargetOptions();

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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thiết lập mối quan hệ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Phía "Bạn là"
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
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _sheetController.myRelation,
                      decoration: _buildInputDecoration(),
                      items: _sheetController.myRelationOptions
                          .map(
                            (rel) => DropdownMenuItem(
                              value: rel,
                              child: Text(
                                rel,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _sheetController.updateMyRelation(val);
                      },
                    ),
                  ],
                ),
              ),

              // 2. Nút Swap Mũi tên 2 chiều
              Padding(
                padding: const EdgeInsets.only(top: 18.0, left: 4, right: 4),
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

              // 3. Phía "Đối phương là"
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
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _sheetController.targetRelation,
                      decoration: _buildInputDecoration(),
                      items: targetOptions
                          .map(
                            (rel) => DropdownMenuItem(
                              value: rel,
                              child: Text(
                                rel,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          _sheetController.updateTargetRelation(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
