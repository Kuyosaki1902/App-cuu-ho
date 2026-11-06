import 'package:cloud_firestore/cloud_firestore.dart';

class ThongBaoSosModel {
  String? idCuocGoi;
  String? maNguoiDung;
  String? maNguoiThan;
  String? noiDungDoc;
  String? trangThai;

  ThongBaoSosModel({
    this.idCuocGoi,
    this.maNguoiDung,
    this.maNguoiThan,
    this.noiDungDoc,
    this.trangThai,
  });

  factory ThongBaoSosModel.fromJson(Map<String, dynamic> json) {
    return ThongBaoSosModel(
      idCuocGoi: json['idCuocGoi']?.toString(),
      maNguoiDung: json['maNguoiDung']?.toString(),
      maNguoiThan: json['maNguoiThan']?.toString(),
      noiDungDoc: json['noiDungDoc']?.toString(),
      trangThai: json['trangThai']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCuocGoi': idCuocGoi,
      'maNguoiDung': maNguoiDung,
      'maNguoiThan': maNguoiThan,
      'noiDungDoc': noiDungDoc,
      'trangThai': trangThai,
    };
  }
}