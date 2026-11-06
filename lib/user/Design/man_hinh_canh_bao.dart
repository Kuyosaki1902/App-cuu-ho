import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ManHinhCanhBao extends StatelessWidget {
  final DocumentReference docRef;
  final String maNguoiGoi;      // Mã ID để query Firestore
  final String hoTenNguoiGoi;   // Họ tên hiển thị lên giao diện

  const ManHinhCanhBao({
    super.key,
    required this.docRef,
    required this.maNguoiGoi,
    required this.hoTenNguoiGoi,
  });

  Future<void> _moGoogleMaps(double viDo, double kinhDo) async {
    // 1. Thử dùng scheme mở trực tiếp App Google Maps
    final Uri googleMapsAppUrl = Uri.parse('geo:$viDo,$kinhDo?q=$viDo,$kinhDo');
    // 2. Dự phòng URL trình duyệt Web
    final Uri googleMapsWebUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$viDo,$kinhDo');

    try {
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsWebUrl)) {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      debugPrint('Lỗi mở bản đồ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Column(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 60),
          SizedBox(height: 10),
          Text(
            '🚨 CẢNH BÁO KHẨN CẤP',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        '$hoTenNguoiGoi đang gặp nguy hiểm và đã phát tín hiệu cầu cứu. Vui lòng kiểm tra và hỗ trợ ngay lập tức!',
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            // Cập nhật trạng thái
            await docRef.update({'trangThai': 'daXem'});

            // Đọc tọa độ từ Firestore
            try {
              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('NguoiDung')
                  .doc(maNguoiGoi) // Dùng chính xác maNguoiGoi ID
                  .get();

              if (userDoc.exists) {
                Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
                double? viDo = (data?['viDo'] as num?)?.toDouble();
                double? kinhDo = (data?['kinhDo'] as num?)?.toDouble();

                if (viDo != null && kinhDo != null) {
                  await _moGoogleMaps(viDo, kinhDo);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không tìm thấy tọa độ GPS của người thân!')),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('Lỗi đọc dữ liệu người dùng: $e');
            }

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text(
            'ĐÃ HIỂU',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        )
      ],
    );
  }
}