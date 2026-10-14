// lib/add_data_screen.dart

import 'package:cuhokhancap/data/data.dart';
import 'package:cuhokhancap/models/basemodel.dart';
import 'package:cuhokhancap/models/nguoithanmodel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpData extends StatefulWidget {
  const UpData({super.key});

  @override
  State<UpData> createState() => _UpDataState();
}

class _UpDataState extends State<UpData> {
  bool _isLoading = false;

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
          DocumentReference docRef;
          if (data is NguoiThanModel) {
            // Lấy id (mã người thân) làm Document ID
            final String docId = data.id ?? '';

            if (docId.isNotEmpty) {
              docRef = firestore
                  .collection('NguoiThan')
                  .doc(data.maNguoiDung)
                  .collection('DanhSachNguoiThan')
                  .doc(docId); // Document ID chính là Mã Người Thân
            } else {
              continue; // Bỏ qua nếu thiếu ID
            }
          } else {
            final String docId = data.id ?? defaultCollectionRef.doc().id;
            docRef = defaultCollectionRef.doc(docId);
          }
          final docSnap = await docRef.get();

          if (!docSnap.exists) {
            batch.set(docRef, data.toMap());
            addedCount++;
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
                'Tất cả dữ liệu đã tồn tại, không có gì mới để thêm.',
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
