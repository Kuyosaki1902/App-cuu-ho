// lib/add_data_screen.dart

import 'package:cuhokhancap/user/data/data.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';
import 'package:cuhokhancap/user/models/chitietkynangmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/nguoithanmodel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpData extends StatefulWidget {
  const UpData({super.key});

  @override
  State<UpData> createState() => _UpDataState();
}

class _UpDataState extends State<UpData> {
  bool _isLoading = false;

  /// Hàm nạp 1 bản ghi phân công mẫu theo mốc thời gian hôm nay
  Future<void> seedSamplePhanCongTheoNgay({
    required String maNguoiCuuHo,
    required String maYeuCau,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final String todayStr = DateTime.now().toString().substring(
        0,
        10,
      ); // Lấy "2026-10-25"

      // Tạo mã phân công mẫu
      String maPhanCong =
          'phancong_${maNguoiCuuHo}_test_${DateTime.now().millisecondsSinceEpoch}';

      final samplePhanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_chophanhoi',
      );

      // Path: NguoiDung/{maNguoiCuuHo}/DanhSachNgay/{2026-10-25}/DanhSachPhanCong/{maPhanCong}
      await firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(maNguoiCuuHo)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(maYeuCau)
          .set(samplePhanCong.toMap(), SetOptions(merge: true));

      debugPrint(
        '✅ Đã nạp thành công phân công mẫu hôm nay ($todayStr) cho $maNguoiCuuHo!',
      );
    } catch (e) {
      debugPrint('❌ Lỗi nạp dữ liệu phân công mẫu: $e');
    }
  }

  Future<void> _uploadBatchData() async {
    setState(() => _isLoading = true);

    try {
      seedSamplePhanCongTheoNgay(
        maNguoiCuuHo: 'nguoidung1', // Thay ID Cứu hộ viên của bạn
        maYeuCau: 'yeucau2',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Model vào Firestore')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _uploadBatchData,
                child: const Text('Thêm dữ liệu vào Firestore'),
              ),
      ),
    );
  }
}
