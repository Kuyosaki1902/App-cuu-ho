// lib/add_data_screen.dart

import 'package:cuhokhancap/data/data.dart';
import 'package:flutter/material.dart';
import 'package:/cloud_firestore/cloud_firestore.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  bool _isLoading = false;

  Future<void> _uploadBatchData() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      int addedCount = 0; // Đếm số lượng record mới được thêm
      var collectionRef = firestore.collection('');
      for (var item in ListAll) {
        if (item.isEmpty) continue;
        collectionRef = firestore.collection(item.first.runtimeType.toString());
        for (var data in item) {
          final docId = data.maNguoiDung ?? collectionRef.doc().id;
          final docRef = collectionRef.doc(docId);
          final docSnap = await docRef.get();

          if (!docSnap.exists) {
            batch.set(docRef, data.toMap());
            addedCount++;
          }
        }
      }
      // Nếu có ít nhất 1 dữ liệu mới thì mới commit
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
                child: const Text('Thêm bảng Người Dùng, Giới Tính và Vai Trò'),
              ),
      ),
    );
  }
}
