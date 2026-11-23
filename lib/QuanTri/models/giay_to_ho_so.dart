bool belongsToProfile(Map<String, dynamic> data, String collection) {
  final explicit = data['loaiHoSo'];
  if (explicit is String && explicit.isNotEmpty) return explicit == collection;
  final type = data['maPhanLoaiAnh'];
  if (collection == 'HoSoCuuHoCoCCHN') {
    return ['THE_CONG_TAC', 'phanloaianh_thecongtac'].contains(type);
  }
  if (collection == 'HoSoCuuHoKhongCCHN') {
    return [
      'ANH_THUC_TE_KHONG_CCHN',
      'phanloaianh_anhthuctekhongcchn',
    ].contains(type);
  }
  return false;
}

String profileDocumentLabel(Object? type) {
  const labels = {
    'THE_CONG_TAC': 'Thẻ công tác',
    'phanloaianh_thecongtac': 'Thẻ công tác',
    'ANH_THUC_TE_KHONG_CCHN': 'Ảnh minh chứng hoạt động cứu hộ',
    'phanloaianh_anhthuctekhongcchn': 'Ảnh minh chứng hoạt động cứu hộ',
    'phanloaianh_avatar': 'Ảnh đại diện',
    'phanloaianh_hientruong': 'Ảnh hiện trường',
    'cccd': 'Căn cước công dân (CCCD)',
    'cchn': 'Chứng chỉ hành nghề KCB',
    'cpr': 'Chứng chỉ đào tạo Sơ cấp cứu / CPR',
    'noi_cong_tac': 'Thông tin nơi công tác',
  };
  return labels[type] ??
      (type is String && type.isNotEmpty ? type : 'Tài liệu');
}
