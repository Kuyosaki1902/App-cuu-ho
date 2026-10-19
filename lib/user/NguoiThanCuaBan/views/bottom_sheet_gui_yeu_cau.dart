// lib/views/nguoi_than/bottom_sheet_gui_yeu_cau.dart

import 'package:flutter/material.dart';

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
  // Hardcode danh sách mối quan hệ
  String _myRelation = 'Con trai';
  String _targetRelation = 'Bố (Ba)';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bạn là',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _myRelation,
                      items: const [
                        DropdownMenuItem(
                          value: 'Con trai',
                          child: Text('Con trai'),
                        ),
                        DropdownMenuItem(
                          value: 'Con gái',
                          child: Text('Con gái'),
                        ),
                        DropdownMenuItem(
                          value: 'Anh/Em',
                          child: Text('Anh/Em'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _myRelation = val!),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.swap_horiz),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.targetName} là',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _targetRelation,
                      items: const [
                        DropdownMenuItem(
                          value: 'Bố (Ba)',
                          child: Text('Bố (Ba)'),
                        ),
                        DropdownMenuItem(value: 'Mẹ', child: Text('Mẹ')),
                        DropdownMenuItem(
                          value: 'Bạn bè',
                          child: Text('Bạn bè'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _targetRelation = val!),
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
            ),
            onPressed: () {
              widget.onConfirm(_myRelation, _targetRelation);
              Navigator.pop(context);
            },
            child: const Text(
              'Gửi yêu cầu thiết lập',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
