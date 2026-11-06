import 'dart:io';

class MoTaTamThoi {
  static List<String> trieuChung = [];
  static String moTaChiTiet = "";
  static File? fileAnh;
  static File? fileGhiAm;

  static void clear() {
    trieuChung.clear();
    moTaChiTiet = "";
    fileAnh = null;
    fileGhiAm = null;
  }
}