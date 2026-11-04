import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManHinhCanhBao extends StatelessWidget {
  final DocumentReference docRef;
  final String maNguoiGoi;

  const ManHinhCanhBao({
    super.key,
    required this.docRef,
    required this.maNguoiGoi,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 10),
          const Text(
            '🚨 CẢNH BÁO KHẨN CẤP',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        '$maNguoiGoi đang gặp nguy hiểm và đã phát tín hiệu cầu cứu. Vui lòng kiểm tra và hỗ trợ ngay lập tức!',
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            // Cập nhật trạng thái thành 'daXem' trên Firestore để ngừng xổ thông báo
            await docRef.update({'trangThai': 'daXem'});
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text(
            'ĐÃ HIỂU',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
      ],
    );
  }
}