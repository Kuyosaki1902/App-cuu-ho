import 'package:cuhokhancap/NguoiThanCuaBan/NguoiThanCuaBan.dart';
import 'package:cuhokhancap/UpData.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
import 'package:cuhokhancap/ChatVoiBacSi.dart';
import 'package:cuhokhancap/ChonNguoiCuuHo/ChonNguoiCuuHo.dart';
import 'package:cuhokhancap/LIchSuCuuHo.dart';
import 'package:cuhokhancap/NguoiCuuHo_MHC.dart';
import 'package:flutter/material.dart';

void main() async {
  // 1. Bắt buộc phải có dòng này khi khởi tạo dịch vụ trước runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Gọi lệnh khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: NguoiThanCuaBan(userId: 'nguoidung1'),
    );
  }
}
