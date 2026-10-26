import 'package:cuhokhancap/NguoiCuuHo/Features/ManHinhChoTiepNhanCa/ManHinhCho.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVCoCCHN/CuuHoVien_CoCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/ThongTinCHVKhongCCHN/CuuHoVien_KhongCCHN.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangThaiXacThuc/trang_thai_xac_thuc_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const Trangchunguoicuuho(),
    );
  }
}
