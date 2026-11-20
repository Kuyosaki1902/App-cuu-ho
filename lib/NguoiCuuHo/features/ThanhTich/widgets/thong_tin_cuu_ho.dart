/// Các hàm nhỏ dùng chung về hiển thị / phân loại cứu hộ viên.
const String vaiTroCoCCHN = 'vaitro_cuuhococc';

/// 'cchn' hoặc 'khongcchn'
String loaiHoSoTuVaiTro(String maVaiTro) =>
    maVaiTro == vaiTroCoCCHN ? 'cchn' : 'khongcchn';

/// "Nguyễn Văn An" → "Nguyễn V. An" (không lộ họ tên đầy đủ trên bảng công khai)
String rutGonTen(String hoTen) {
  final tu = hoTen
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (tu.isEmpty) return 'Cứu hộ viên';
  if (tu.length <= 2) return tu.join(' ');
  final giua = tu
      .sublist(1, tu.length - 1)
      .map((e) => '${e[0].toUpperCase()}.')
      .join(' ');
  return '${tu.first} $giua ${tu.last}';
}
