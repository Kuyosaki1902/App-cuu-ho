// lib/add_data_screen.dart

import 'package:cuhokhancap/user/data/data.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';
import 'package:cuhokhancap/user/models/chitietkynangmodel.dart';
import 'package:cuhokhancap/user/models/chitietphancongcuuhomodel%20.dart';
import 'package:cuhokhancap/user/models/luuanhmodel.dart';
import 'package:cuhokhancap/user/models/nguoithanmodel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

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
      final String todayStr = DateTime.now().toString().substring(0, 10);

      String maPhanCong =
          'phancong_${maNguoiCuuHo}_${DateTime.now().millisecondsSinceEpoch}';

      final samplePhanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      // Path chuẩn: NguoiDung/{maNguoiCuuHo}/DanhSachNgay/{todayStr}/DanhSachPhanCong/{maPhanCong}
      await firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(maNguoiCuuHo)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(maPhanCong)
          .set(samplePhanCong.toMap(), SetOptions(merge: true));

      debugPrint(
        '✅ Đã nạp thành công phân công mẫu hôm nay ($todayStr) cho $maNguoiCuuHo!',
      );
    } catch (e) {
      debugPrint('❌ Lỗi nạp dữ liệu phân công mẫu: $e');
    }
  }

  // Hàm chọn ảnh, mã hóa Base64 và đẩy lên Firebase
  Future<void> _chonAnhVaUploadBatch() async {
    final ImagePicker picker = ImagePicker();

    try {
      // 1. Mở thư viện và cho phép người dùng chọn nhiều ảnh
      final List<XFile>? pickedImages = await picker.pickMultiImage();

      if (pickedImages == null || pickedImages.isEmpty) {
        // Người dùng hủy chọn ảnh
        return;
      }

      setState(() => _isLoading = true);

      List<LuuAnhModel> listAnhMoi = [];

      // 2. Lặp qua từng ảnh, chuyển sang byte và mã hóa Base64
      for (int i = 0; i < pickedImages.length; i++) {
        final XFile image = pickedImages[i];
        final bytes = await image.readAsBytes();
        final String base64Image = base64Encode(bytes);

        // Tạo mã ảnh ngẫu nhiên hoặc theo timestamp để không bị trùng lặp
        final String maAnhMoi =
            'anh_${DateTime.now().millisecondsSinceEpoch}_$i';

        // 3. Truyền dữ liệu vào LuuAnhModel
        listAnhMoi.add(
          LuuAnhModel(
            maAnh: maAnhMoi,
            maNguoiDung:
                'nguoidung3', // Thay bằng biến id người dùng hiện tại của bạn
            maPhanLoaiAnh: 'phanloaianh_hientruong',
            maYeuCau: 'yeucau1',
            anhURL: base64Image, // Thay bằng biến id yêu cầu thực tế
            // Giả định bạn đã thêm trường này vào LuuAnhModel để lưu dữ liệu ảnh
            // duLieuBase64: base64Image,
          ),
        );
      }

      // 4. Thêm danh sách ảnh vừa tạo vào biến listLuuAnh (biến nằm trong ListAll của bạn)
      setState(() {
        // listLuuAnh là danh sách bạn đã khai báo bên ngoài và có đưa vào ListAll
        listLuuAnh.addAll(listAnhMoi);
      });

      // 5. Chạy hàm upload hàng loạt (Nó sẽ duyệt qua ListAll và up các ảnh này cùng các danh sách khác)
      await _uploadBatchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xử lý ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadBatchData() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      int addedCount = 0;

      for (var item in ListAll) {
        if (item.isEmpty) continue;
        // Lấy tên class bỏ đuôi "Model" làm tên collection mặc định
        var collectionName = item.first.runtimeType.toString();
        if (collectionName.endsWith('Model')) {
          collectionName = collectionName.substring(
            0,
            collectionName.length - 5,
          );
        }
        final defaultCollectionRef = firestore.collection(collectionName);

        for (var data in item) {
          // -------------------------------------------------------------------
          // LOẠI 1: Xử lý Subcollection NguoiThan
          // -------------------------------------------------------------------
          if (data is NguoiThanModel) {
            final String docId = data.id ?? '';
            if (docId.isNotEmpty) {
              DocumentReference docRef = firestore
                  .collection('NguoiThan')
                  .doc(data.maNguoiDung)
                  .collection('DanhSachNguoiThan')
                  .doc(docId);

              final docSnap = await docRef.get();
              if (!docSnap.exists) {
                batch.set(docRef, data.toMap());
                addedCount++;
              }
            }
          }
          // -------------------------------------------------------------------
          // LOẠI 2: Xử lý Subcollection ChiTietKyNang
          // -------------------------------------------------------------------
          else if (data is ChiTietKyNangModel) {
            final String userId = data.maNguoiDung;
            if (userId.isNotEmpty) {
              // 1. Tạo document cha ChiTietKyNang/{userId}
              DocumentReference parentDocRef = firestore
                  .collection('ChiTietKyNang')
                  .doc(userId);

              batch.set(parentDocRef, data.toMap(), SetOptions(merge: true));

              // 2. Lặp ghi các subcollection trong DanhSachKiNang
              for (var kn in data.danhSachKiNang) {
                DocumentReference subDocRef = parentDocRef
                    .collection('DanhSachKiNang')
                    .doc(kn.maKyNangCuuHo);

                final subSnap = await subDocRef.get();
                if (!subSnap.exists) {
                  batch.set(subDocRef, kn.toMap());
                  addedCount++;
                }
              }
            }
          }
          // -------------------------------------------------------------------
          // LOẠI 3: Xử lý các Root Collection thông thường còn lại
          // -------------------------------------------------------------------
          else {
            final String docId = data.id ?? defaultCollectionRef.doc().id;
            DocumentReference docRef = defaultCollectionRef.doc(docId);

            final docSnap = await docRef.get();
            if (!docSnap.exists) {
              batch.set(docRef, data.toMap());
              addedCount++;
            }
          }
        }
      }

      if (addedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm mới thành công $addedCount dữ liệu!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tất cả dữ liệu Batch đã tồn tại, đã nạp đơn mẫu hôm nay.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
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
